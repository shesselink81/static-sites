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

##  Helm Charts

This repository includes Helm charts for Kubernetes deployment of both services:

### Available Charts
- **anna-nginx** – Helm chart for the Anna website (v0.2.3)
- **hesselinkme-nginx** – Helm chart for the hesselink.me website (v0.2.3)

### Installation

To install a chart, use:

```bash
helm repo add static-nginx https://static.charts.hessel.cloud
helm repo update
helm install <release-name> ./charts/<chart-name>
```

For example:

```bash
helm install static-anna static-nginx/anna-nginx
helm install static-hesselinkme static-nginx/hesselinkme-nginx
```

### Configuration

Each chart supports customizable parameters. Install with custom values:

```bash
helm install <release-name> ./charts/<chart-name> -f values.yaml
```

Common configurable parameters:
- `image.repository` – Docker image repository
- `image.tag` – Image version tag
- `replicaCount` – Number of pod replicas
- `service.type` – Kubernetes service type (ClusterIP, NodePort, LoadBalancer)
- `service.port` – Service port

For detailed configuration options, see the README in each chart directory.

##  Use Cases

- Static websites
- Portfolio hosting
- Lightweight Nginx containers
- Kubernetes / Helm deployments
- Edge / ARM (Raspberry Pi) hosting
