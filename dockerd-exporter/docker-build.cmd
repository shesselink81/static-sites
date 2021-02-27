docker buildx use mybuilder
docker buildx build --push --platform linux/arm/v7,linux/amd64,linux/arm64 --tag quay.io/shesselink81/dockerd-exporter:latest -f .\dockerd-exporter\Dockerfile .