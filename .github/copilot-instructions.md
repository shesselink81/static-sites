# Copilot Instructions for dockerfiles Repository

## Project Overview
This repository contains Docker configurations for static websites served via nginx. Each website has its own directory with a Dockerfile, docker-compose.yml, and static assets.

## Architecture
- **Base Image**: Uses `nginxinc/nginx-unprivileged:alpine-slim` for security (runs as non-root user)
- **Structure**: Each service directory contains:
  - `Dockerfile`: Copies static files to `/usr/share/nginx/html`
  - `compose.yml`: Defines nginx service with port mapping
  - Static content directory (e.g., `anna-static/`, `hesselinkme-static/`)

## Key Patterns
- **Dockerfile Template**:
  ```dockerfile
  FROM nginxinc/nginx-unprivileged:alpine-slim
  USER root
  COPY /{service}-nginx/{static-dir} /usr/share/nginx/html
  USER nginx
  ```
- **Compose Configuration**: 
  - Service name: `nginx`
  - Restart policy: `always`
  - Port mapping: Host port 8090 → Container port 8080 (note: adjust host port to avoid conflicts)

## Development Workflow
- **Local Testing**: Uncomment `build: .` in compose.yml, run `docker compose up` from service directory
- **Image Building**: Use GitHub Actions workflow triggered on tag push (e.g., `v2.0.5`)
- **Tagging**: Run `.\create_tag.ps1` to create and push version tags
- **Registry**: Images pushed to `quay.io/{username}/{service}-nginx:{tag}`

## Multi-Platform Support
Builds target `linux/amd64`, `linux/arm/v7`, `linux/arm64` using Docker Buildx.

## Adding New Services
1. Create new directory with service name
2. Add Dockerfile following the template
3. Add compose.yml with unique host port
4. Place static files in dedicated subdirectory
5. Update workflow if needed for new service

## Conventions
- Image tags follow semantic versioning (e.g., `v2.0.5`)
- Static directories named `{service}-static`
- Compose files use relative paths for local builds</content>
<parameter name="filePath">d:\Users\Sander\repos\dockerfiles\.github\copilot-instructions.md