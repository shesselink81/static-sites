docker pull nginx:mainline-alpine-otel
docker compose --project-directory .\anna-nginx\ build
docker compose --project-directory .\anna-nginx\ up -d
docker compose --project-directory .\hesselinkme-nginx\ build
docker compose --project-directory .\hesselinkme-nginx\ up -d