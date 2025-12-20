# Static Websites – Nginx Docker Containers

This repository contains **two Nginx-based Docker containers**, each serving a static website.  
The images are built automatically using **GitHub Actions (Buildx)** and are suitable for local use, Docker Compose, or Kubernetes.

##  Containers Overview

| Container | Description |
|---------|-------------|
| anna-nginx | Static website for *Anna*, served via Nginx |
| hesselinkme-nginx | Personal static website for *hesselink.me*, served via Nginx |

Both containers:
- Serve **pure static content**
- Use **Nginx**
- Are optimized for containerized deployment
- Can be built for multi-architectures via Docker Buildx

##  Development Workflow

### GitHub Actions (CI/CD)
The repository includes a Docker Buildx GitHub Actions workflow:
- Builds Docker images automatically
- Supports multi-architecture builds (e.g. amd64, arm64)
- Will push the docker images to Quay.io: <https://quay.io/organization/shesselink81>

### Tagging
The create_tag.ps1 script can be used on Windows to create and push Git tags, typically used to trigger image builds.

##  Use Cases

- Static websites
- Portfolio hosting
- Lightweight Nginx containers
- Kubernetes / Helm deployments
- Edge / ARM (Raspberry Pi) hosting
