#Requires -Version 5.1
<#
.SYNOPSIS
    Checks for new Docker image versions and updates Helm charts and README files.
.DESCRIPTION
    Scans Helm chart values.yaml and Dockerfiles across two repos, queries Docker Hub,
    Quay.io and GHCR for newer versions, and updates values.yaml / Chart.yaml / README.md.
.PARAMETER DryRun
    Show what would change without writing any files.
.PARAMETER GitHubToken
    GitHub PAT with read:packages scope, used for GHCR lookups.
    Falls back to $env:GITHUB_TOKEN if not supplied.
.PARAMETER WordpressRepo
    Path to the wordpress-apache repository.
.PARAMETER Mode
    Which repo sections to process: All (default), Nginx, or WordPress.
    Use Nginx in the dockerfiles CI, WordPress in the wordpress-apache CI.
.EXAMPLE
    .\update-versions.ps1
    .\update-versions.ps1 -DryRun
    .\update-versions.ps1 -Mode Nginx
    .\update-versions.ps1 -Mode WordPress -WordpressRepo /workspace/wordpress-apache
#>
param(
    [switch]$DryRun,
    [string]$GitHubToken   = $env:GITHUB_TOKEN,
    [string]$WordpressRepo = 'D:\Users\Sander\repos\wordpress-apache',
    [ValidateSet('All', 'Nginx', 'WordPress')]
    [string]$Mode = 'All'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$RepoRoot = $PSScriptRoot

if ($DryRun) { Write-Host '[DRY RUN] No files will be modified.' -ForegroundColor Magenta }

# ═══════════════════════════════════════════════════════════════════════════
# Output helpers
# ═══════════════════════════════════════════════════════════════════════════

function Write-Header  ([string]$t) { Write-Host "`n== $t ==" -ForegroundColor Cyan }
function Write-Ok      ([string]$t) { Write-Host "  [OK]     $t" -ForegroundColor DarkGray }
function Write-New     ([string]$t) { Write-Host "  [NEW]    $t" -ForegroundColor Green }
function Write-Changed ([string]$t) { Write-Host "  [UPDATE] $t" -ForegroundColor Yellow }
function Write-Warn    ([string]$t) { Write-Host "  [WARN]   $t" -ForegroundColor Red }
function Write-Note    ([string]$t) { Write-Host "           $t" -ForegroundColor DarkGray }

# ═══════════════════════════════════════════════════════════════════════════
# Version comparison helpers
# ═══════════════════════════════════════════════════════════════════════════

function ConvertTo-SemVer ([string]$tag) {
    # Strip leading 'v' and any build-metadata suffix (e.g. v7.0.0.1 -> 7.0.0.1)
    $clean = $tag -replace '^v', ''
    try { return [version]$clean } catch { return $null }
}

function Test-IsNewer ([string]$current, [string]$candidate) {
    $cv = ConvertTo-SemVer $current
    $nv = ConvertTo-SemVer $candidate
    if (-not $cv -or -not $nv) { return $false }
    return $nv -gt $cv
}

function Get-BumpedPatchVersion ([string]$version) {
    $v = ConvertTo-SemVer $version
    if (-not $v) { return $version }
    $build = [Math]::Max(0, $v.Build)
    return "$($v.Major).$($v.Minor).$($build + 1)"
}

# ═══════════════════════════════════════════════════════════════════════════
# Registry API helpers
# ═══════════════════════════════════════════════════════════════════════════

function Invoke-Api ([string]$Uri, [hashtable]$Headers = @{}) {
    try {
        return Invoke-RestMethod -Uri $Uri -Headers $Headers -UseBasicParsing -ErrorAction Stop
    } catch {
        return $null
    }
}

# Returns the latest *versioned* tag on Docker Hub for a library image + flavor suffix.
#   Get-LatestDockerHubTag nginx     'alpine-slim'       ''  -> '1.27.5-alpine-slim'
#   Get-LatestDockerHubTag wordpress 'php8.5-fpm-alpine' ''  -> '7.0.0-php8.5-fpm-alpine'
#   Get-LatestDockerHubTag wordpress 'php8.5-apache'     '7' -> '7.0.0-php8.5-apache'
function Get-LatestDockerHubTag ([string]$Image, [string]$Flavor, [string]$MajorConstraint = '') {
    $collected = @()
    $url = "https://hub.docker.com/v2/repositories/library/$Image/tags?page_size=100"
    $page = 0
    while ($url -and $page -lt 6) {
        $resp = Invoke-Api $url
        if (-not $resp) { break }
        $collected += $resp.results | ForEach-Object { $_.name }
        $url = $resp.next
        $page++
    }

    $major = if ($MajorConstraint) { [regex]::Escape($MajorConstraint) } else { '\d+' }
    $flavorEsc = [regex]::Escape($Flavor)
    $pattern = "^$major\.\d+\.\d+-$flavorEsc$"

    return $collected |
        Where-Object { $_ -match $pattern } |
        Sort-Object { ConvertTo-SemVer ($_ -split '-')[0] } -Descending |
        Select-Object -First 1
}

# Returns the latest semver v* tag for a Quay.io repository.
function Get-LatestQuayTag ([string]$Org, [string]$Repo) {
    $resp = Invoke-Api "https://quay.io/api/v1/repository/$Org/$Repo/tag/?onlyActiveTags=true&limit=100"
    if (-not $resp) { return $null }
    return $resp.tags |
        Where-Object { $_.name -match '^v?\d+\.\d+' } |
        ForEach-Object { $_.name } |
        Sort-Object { ConvertTo-SemVer $_ } -Descending |
        Select-Object -First 1
}

# Returns the latest semver v* tag for a GHCR (GitHub Container Registry) package.
function Get-LatestGHCRTag ([string]$User, [string]$Package, [string]$Token = '') {
    $headers = @{
        'Accept'               = 'application/vnd.github+json'
        'X-GitHub-Api-Version' = '2022-11-28'
    }
    if ($Token) { $headers['Authorization'] = "Bearer $Token" }

    $resp = Invoke-Api "https://api.github.com/users/$User/packages/container/$Package/versions?per_page=100" $headers
    if (-not $resp) {
        if (-not $Token) { Write-Note "Tip: set `$env:GITHUB_TOKEN (read:packages scope) for GHCR lookups" }
        return $null
    }

    return $resp |
        ForEach-Object { $_.metadata.container.tags } |
        Where-Object { $_ -match '^v?\d+\.\d+' } |
        Sort-Object { ConvertTo-SemVer $_ } -Descending |
        Select-Object -First 1
}

# ═══════════════════════════════════════════════════════════════════════════
# File update helpers
# ═══════════════════════════════════════════════════════════════════════════

# Writes $NewContent to $Path only when content changed. Returns $true if changed.
function Save-IfChanged ([string]$Path, [string]$OldContent, [string]$NewContent, [switch]$DryRun) {
    if ($OldContent -ceq $NewContent) { return $false }
    if (-not $DryRun) {
        [System.IO.File]::WriteAllText($Path, $NewContent, [System.Text.UTF8Encoding]::new($false))
    }
    return $true
}

# Updates `tag: <old>` -> `tag: <new>` in a values.yaml file.
function Update-ValuesTag ([string]$Path, [string]$OldTag, [string]$NewTag, [switch]$DryRun) {
    $c = Get-Content $Path -Raw
    $u = $c -replace "(?m)^(\s*tag:\s*)$([regex]::Escape($OldTag))\s*$", "`${1}$NewTag"
    if (Save-IfChanged $Path $c $u -DryRun:$DryRun) {
        Write-Changed "$(Split-Path $Path -Leaf): image.tag  $OldTag -> $NewTag"
        return $true
    }
    return $false
}

# Replaces an exact image reference string anywhere in a values.yaml file.
function Update-ValuesImageRef ([string]$Path, [string]$OldRef, [string]$NewRef, [switch]$DryRun) {
    $c = Get-Content $Path -Raw
    $u = $c.Replace($OldRef, $NewRef)
    if (Save-IfChanged $Path $c $u -DryRun:$DryRun) {
        Write-Changed "$(Split-Path $Path -Leaf): $OldRef -> $NewRef"
        return $true
    }
    return $false
}

# Updates `version: "<old>"` under env.wp in a values.yaml file.
function Update-ValuesWpVersion ([string]$Path, [string]$OldVer, [string]$NewVer, [switch]$DryRun) {
    $c = Get-Content $Path -Raw
    $u = $c -replace "(?m)^(\s*version:\s*)""$([regex]::Escape($OldVer))""\s*$", "`${1}`"$NewVer`""
    if (Save-IfChanged $Path $c $u -DryRun:$DryRun) {
        Write-Changed "$(Split-Path $Path -Leaf): env.wp.version  `"$OldVer`" -> `"$NewVer`""
        return $true
    }
    return $false
}

# Bumps Chart.yaml `version` (patch +1) and sets `appVersion`. Preserves inline comments.
function Update-ChartYaml ([string]$Path, [string]$NewAppVersion, [switch]$DryRun) {
    $c = Get-Content $Path -Raw

    $oldVer    = ''; if ($c -match '(?m)^version:\s*(\S+)')                 { $oldVer    = $Matches[1] }
    $oldAppVer = ''; if ($c -match '(?m)^appVersion:\s*"?([^"\s#]+)"?')     { $oldAppVer = $Matches[1] }
    $newVer    = Get-BumpedPatchVersion $oldVer

    $u = $c -replace "(?m)^(version:\s*)$([regex]::Escape($oldVer))\s*$",   "`${1}$newVer"
    $u = $u  -replace '(?m)^(appVersion:\s*)"?[^"\s#]+"?(\s*(?:#.*)?)$',    "`${1}`"$NewAppVersion`"`$2"

    if (Save-IfChanged $Path $c $u -DryRun:$DryRun) {
        Write-Changed "Chart.yaml: version $oldVer -> $newVer  |  appVersion `"$oldAppVer`" -> `"$NewAppVersion`""
        return @{ NewVersion = $newVer; NewAppVersion = $NewAppVersion }
    }
    return $null
}

# Syncs the shields.io Version / AppVersion badges in a Helm chart README.
function Update-ReadmeBadges ([string]$Path, [string]$ChartVersion, [string]$AppVersion, [switch]$DryRun) {
    if (-not (Test-Path $Path)) { return $false }
    $c = Get-Content $Path -Raw
    $u = $c

    # Label part: ![Version: 0.1.0]  ->  ![Version: 1.29.8]
    $u = $u -replace '(?<=!\[Version:\s*)[\d.]+(?=\])',                       $ChartVersion
    # URL part:   /badge/Version-0.1.0-informational  ->  /badge/Version-1.29.8-informational
    $u = $u -replace '(?<=img\.shields\.io/badge/Version-)[\d.]+(?=-informational)', $ChartVersion

    # AppVersion may or may not have a 'v' prefix
    $u = $u -replace '(?<=!\[AppVersion:\s*)v?[\d.]+(?=\])',                  $AppVersion
    $u = $u -replace '(?<=img\.shields\.io/badge/AppVersion-)v?[\d.]+(?=-informational)', $AppVersion

    if (Save-IfChanged $Path $c $u -DryRun:$DryRun) {
        Write-Changed "README.md: badges  Version=$ChartVersion  AppVersion=$AppVersion"
        return $true
    }
    return $false
}

# Updates the default value cell for a named parameter in a Markdown config table.
# Replaces whatever is currently in the default column, regardless of old value.
function Update-ReadmeTableDefault ([string]$Path, [string]$Param, [string]$NewVal, [switch]$DryRun) {
    if (-not (Test-Path $Path)) { return $false }
    $c = Get-Content $Path -Raw
    # Matches: | `image.tag` | Any description | `<any-existing-value>` |
    $paramEsc = [regex]::Escape($Param)
    $u = $c -replace "(?m)(\|\s*``$paramEsc``\s*\|[^|]*\|\s*)``\S+``(\s*\|)", "`${1}``$NewVal```${2}"
    if (Save-IfChanged $Path $c $u -DryRun:$DryRun) {
        Write-Changed "README.md: $Param default -> $NewVal"
        return $true
    }
    return $false
}

# Updates chart version references in the root README.md (e.g. "anna-nginx (v0.2.3)").
function Update-MainReadmeVersion ([string]$Path, [string]$ChartName, [string]$NewVersion, [switch]$DryRun) {
    if (-not (Test-Path $Path)) { return $false }
    $c = Get-Content $Path -Raw
    $nameEsc = [regex]::Escape($ChartName)
    # Matches: **anna-nginx** ... (v0.2.3)  -- any dash/text between name and version
    $u = $c -replace "(?m)(\*\*$nameEsc\*\*[^(]+\()v?[\d.]+(\))", "`${1}$NewVersion`${2}"
    if (Save-IfChanged $Path $c $u -DryRun:$DryRun) {
        Write-Changed "Root README.md: $ChartName version -> $NewVersion"
        return $true
    }
    return $false
}

# Packages a Helm chart and regenerates charts/index.yaml via 'helm repo index'.
# Requires helm in PATH. Prints a hint if helm is not available.
function Invoke-HelmReindex ([string]$ChartDir, [string]$ChartsOutputDir, [switch]$DryRun) {
    if (-not (Get-Command 'helm' -ErrorAction SilentlyContinue)) {
        Write-Note "helm not found in PATH - run manually to regenerate index.yaml:"
        Write-Note "  helm package `"$ChartDir`" -d `"$ChartsOutputDir`""
        Write-Note "  helm repo index `"$ChartsOutputDir`" --merge `"$(Join-Path $ChartsOutputDir 'index.yaml')`""
        return $false
    }
    if ($DryRun) {
        Write-Note "[DRY RUN] Would run: helm package + helm repo index for $(Split-Path $ChartDir -Leaf)"
        return $true
    }
    Write-Changed "helm package $(Split-Path $ChartDir -Leaf)"
    helm package $ChartDir -d $ChartsOutputDir | Out-Null
    Write-Changed "helm repo index $ChartsOutputDir"
    helm repo index $ChartsOutputDir --merge (Join-Path $ChartsOutputDir 'index.yaml')
    return $true
}

# Replaces an exact image reference string in a README (e.g. image table).
function Update-ReadmeImageRef ([string]$Path, [string]$OldRef, [string]$NewRef, [switch]$DryRun) {
    if (-not (Test-Path $Path)) { return $false }
    $c = Get-Content $Path -Raw
    $u = $c.Replace($OldRef, $NewRef)
    if (Save-IfChanged $Path $c $u -DryRun:$DryRun) {
        Write-Changed "README.md: $OldRef -> $NewRef"
        return $true
    }
    return $false
}

# ═══════════════════════════════════════════════════════════════════════════
# SECTION 1 - Dockerfile base image versions (informational only)
#              These use floating tags (mainline-alpine-slim etc.) so the
#              Dockerfiles themselves are not rewritten, but we report the
#              current pinned version behind the tag so you know when to
#              trigger a rebuild.
# ═══════════════════════════════════════════════════════════════════════════
Write-Header 'Dockerfile base image versions (informational)'

$baseImageChecks = @(
    @{ Label = 'nginx:mainline-alpine-slim';  Image = 'nginx';     Flavor = 'alpine-slim';       Major = ''  }
    @{ Label = 'wordpress:php8.5-fpm-alpine'; Image = 'wordpress'; Flavor = 'php8.5-fpm-alpine'; Major = ''  }
    @{ Label = 'wordpress:7-php8.5-apache';   Image = 'wordpress'; Flavor = 'php8.5-apache';     Major = '7' }
    @{ Label = 'wordpress:cli-php8.5';        Image = 'wordpress'; Flavor = 'php8.5-cli';        Major = ''  }
)

foreach ($bi in $baseImageChecks) {
    $latest = Get-LatestDockerHubTag $bi.Image $bi.Flavor $bi.Major
    if ($latest) {
        Write-Note "$($bi.Label)  ->  latest versioned tag: $latest"
    } else {
        Write-Warn "Could not determine latest versioned tag for $($bi.Label)"
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# SECTION 2 - dockerfiles repo: anna-nginx and hesselinkme-nginx Helm charts
# ═══════════════════════════════════════════════════════════════════════════
if ($Mode -in @('All', 'Nginx')) {

Write-Header 'dockerfiles repo - nginx Helm charts (Quay.io)'

foreach ($chartName in @('anna-nginx', 'hesselinkme-nginx')) {
    $chartDir   = Join-Path $RepoRoot "charts\$chartName"
    $valuesPath = Join-Path $chartDir 'values.yaml'
    $chartPath  = Join-Path $chartDir 'Chart.yaml'
    $readmePath = Join-Path $chartDir 'README.md'

    # ── Read current state ──────────────────────────────────────────────
    $valContent   = Get-Content $valuesPath -Raw
    $chartContent = Get-Content $chartPath  -Raw

    $currentTag = ''; if ($valContent   -match '(?m)^\s*tag:\s*(\S+)')            { $currentTag    = $Matches[1] }
    $chartVer   = ''; if ($chartContent -match '(?m)^version:\s*(\S+)')           { $chartVer      = $Matches[1] }
    $chartAppVer = ''; if ($chartContent -match '(?m)^appVersion:\s*"?([^"\s#]+)"?') { $chartAppVer = $Matches[1] }

    Write-Note "Checking quay.io/shesselink81/$chartName  (current tag: $currentTag)..."
    $latestTag = Get-LatestQuayTag 'shesselink81' $chartName

    if (-not $latestTag) {
        Write-Warn "Quay.io: no tags retrieved for shesselink81/$chartName"
        $latestTag = $currentTag
    }

    $chartsDir = Join-Path $RepoRoot 'charts'
    $mainReadme = Join-Path $RepoRoot 'README.md'

    if (Test-IsNewer $currentTag $latestTag) {
        Write-New "$chartName`: $currentTag -> $latestTag"

        # Compute bumped chart version upfront (used for badges even in DryRun)
        $bumpedChartVer = Get-BumpedPatchVersion $chartVer

        Update-ValuesTag          -Path $valuesPath -OldTag $currentTag -NewTag $latestTag           -DryRun:$DryRun | Out-Null
        Update-ChartYaml          -Path $chartPath  -NewAppVersion $latestTag                         -DryRun:$DryRun | Out-Null
        Update-ReadmeBadges       -Path $readmePath -ChartVersion $bumpedChartVer -AppVersion $latestTag -DryRun:$DryRun | Out-Null
        Update-ReadmeTableDefault -Path $readmePath -Param 'image.tag' -NewVal $latestTag             -DryRun:$DryRun | Out-Null
        Update-MainReadmeVersion  -Path $mainReadme -ChartName $chartName -NewVersion $bumpedChartVer -DryRun:$DryRun | Out-Null
        Invoke-HelmReindex        -ChartDir $chartDir -ChartsOutputDir $chartsDir                     -DryRun:$DryRun | Out-Null
    } else {
        Write-Ok "$chartName`: $currentTag is up to date (Quay.io latest: $latestTag)"

        # Always sync README in case it drifted from Chart.yaml
        $b = Update-ReadmeBadges       -Path $readmePath -ChartVersion $chartVer -AppVersion $chartAppVer -DryRun:$DryRun
        $t = Update-ReadmeTableDefault -Path $readmePath -Param 'image.tag' -NewVal $currentTag           -DryRun:$DryRun
        if (-not $b -and -not $t) { Write-Ok 'README.md is in sync' }
    }
}

} # end Nginx mode

# ═══════════════════════════════════════════════════════════════════════════
# SECTION 3 - wordpress-apache repo: wordpress-alpine Helm chart (GHCR)
# ═══════════════════════════════════════════════════════════════════════════
if ($Mode -in @('All', 'WordPress')) {

Write-Header 'wordpress-apache repo - WordPress Helm chart (GHCR)'

if (-not (Test-Path $WordpressRepo)) {
    Write-Warn "wordpress-apache repo not found at $WordpressRepo - skipping"
} else {
    $wpChartDir   = Join-Path $WordpressRepo 'wordpress-alpine\chart\source'
    $wpValuesPath = Join-Path $wpChartDir 'values.yaml'
    $wpChartPath  = Join-Path $wpChartDir 'Chart.yaml'
    $wpReadmePath = Join-Path $wpChartDir 'README.md'

    # ── Read current state ──────────────────────────────────────────────
    $wpValues = Get-Content $wpValuesPath -Raw

    $currentFpm   = ''; if ($wpValues -match '(?m)^\s*fpm:\s*(\S+)')   { $currentFpm   = $Matches[1] }
    $currentNginx = ''; if ($wpValues -match '(?m)^\s*nginx:\s*(\S+)') { $currentNginx = $Matches[1] }
    $currentInit  = ''; if ($wpValues -match '(?m)^\s*init:\s*(\S+)')  { $currentInit  = $Matches[1] }
    $currentWpVer = ''
    if ($wpValues -match "(?m)^\s*version:\s*`"([\w.]+)`"") { $currentWpVer = $Matches[1] }

    $fpmTag   = ''
    if ($currentFpm   -match '.*:(.+)$') { $fpmTag   = $Matches[1] }
    $nginxTag = ''
    if ($currentNginx -match '.*:(.+)$') { $nginxTag = $Matches[1] }

    # ── GHCR lookups ────────────────────────────────────────────────────
    Write-Note "Checking ghcr.io/shesselink81/wordpress-alpine  (current: $fpmTag)..."
    $latestFpmTag = Get-LatestGHCRTag 'shesselink81' 'wordpress-alpine' $GitHubToken

    Write-Note "Checking ghcr.io/shesselink81/nginx-alpine  (current: $nginxTag)..."
    $latestNginxTag = Get-LatestGHCRTag 'shesselink81' 'nginx-alpine' $GitHubToken

    $anyUpdate   = $false
    $activeFpmTag = $fpmTag  # tracks effective tag after possible update

    # ── wordpress-alpine (FPM) ──────────────────────────────────────────
    if (-not $latestFpmTag) {
        Write-Warn "GHCR: no tags retrieved for shesselink81/wordpress-alpine"
    } elseif (Test-IsNewer $fpmTag $latestFpmTag) {
        Write-New "wordpress-alpine: $fpmTag -> $latestFpmTag"
        $newFpmRef    = $currentFpm -replace '[^:]+$', $latestFpmTag
        $anyUpdate    = Update-ValuesImageRef -Path $wpValuesPath -OldRef $currentFpm   -NewRef $newFpmRef   -DryRun:$DryRun
        $activeFpmTag = $latestFpmTag
        Update-ReadmeImageRef -Path $wpReadmePath -OldRef $currentFpm -NewRef $newFpmRef -DryRun:$DryRun | Out-Null
    } else {
        Write-Ok "wordpress-alpine: $fpmTag is up to date"
    }

    # ── nginx-alpine ────────────────────────────────────────────────────
    if (-not $latestNginxTag) {
        Write-Warn "GHCR: no tags retrieved for shesselink81/nginx-alpine"
    } elseif (Test-IsNewer $nginxTag $latestNginxTag) {
        Write-New "nginx-alpine: $nginxTag -> $latestNginxTag"
        $newNginxRef = $currentNginx -replace '[^:]+$', $latestNginxTag
        $anyUpdate   = (Update-ValuesImageRef -Path $wpValuesPath -OldRef $currentNginx -NewRef $newNginxRef -DryRun:$DryRun) -or $anyUpdate
        Update-ReadmeImageRef -Path $wpReadmePath -OldRef $currentNginx -NewRef $newNginxRef -DryRun:$DryRun | Out-Null
    } else {
        Write-Ok "nginx-alpine: $nginxTag is up to date"
    }

    # ── Chart.yaml + WordPress version + Helm index ──────────────────────
    if ($anyUpdate) {
        # Derive WordPress version from the FPM image tag (v7.0.1.0 -> 7.0.1)
        $newWpVer = ''
        if ($activeFpmTag -match '^v?(\d+\.\d+\.\d+)') { $newWpVer = $Matches[1] }

        if ($newWpVer -and $newWpVer -ne $currentWpVer) {
            Update-ValuesWpVersion -Path $wpValuesPath -OldVer $currentWpVer -NewVer $newWpVer -DryRun:$DryRun | Out-Null
        }

        $appVerForChart = if ($newWpVer) { $newWpVer } else { $activeFpmTag -replace '^v', '' }
        Update-ChartYaml -Path $wpChartPath -NewAppVersion $appVerForChart -DryRun:$DryRun | Out-Null

        $wpChartOutputDir = Join-Path $WordpressRepo 'wordpress-alpine\chart'
        Invoke-HelmReindex -ChartDir $wpChartDir -ChartsOutputDir $wpChartOutputDir -DryRun:$DryRun | Out-Null
    }

    # ── Init image (Docker Hub, informational) ──────────────────────────
    # wordpress:cli-php8.5 -> versioned tags are formatted as "6.7.2-php8.5-cli"
    Write-Note "Init image: $currentInit"
    if ($currentInit -match '^wordpress:cli-(php\S+)$') {
        $phpVer    = $Matches[1]
        $cliLatest = Get-LatestDockerHubTag 'wordpress' "$phpVer-cli" ''
        if ($cliLatest) { Write-Note "  Latest versioned $phpVer-cli tag: $cliLatest" }
    }
}

} # end WordPress mode

# ═══════════════════════════════════════════════════════════════════════════
Write-Host "`n$( if ($DryRun) { '[DRY RUN] Done - no files were written.' } else { 'Done.' } )" -ForegroundColor Cyan
