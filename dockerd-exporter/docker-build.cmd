docker buildx create --name mybuilder
docker buildx use mybuilder
docker buildx inspect --bootstrap
docker buildx build --push --platform linux/arm/v7,linux/amd64 --tag quay.io/shesselink81/dockerd-exporter:latest --no-cache .