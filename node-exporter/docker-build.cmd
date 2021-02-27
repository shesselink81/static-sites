docker buildx use mybuilder
docker buildx build --push --platform linux/arm/v7,linux/amd64,linux/arm64 --tag quay.io/shesselink81/node-exporter:latest -f .\node-exporter\Dockerfile .