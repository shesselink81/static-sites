docker buildx create --name mybuilder
docker buildx use mybuilder
docker buildx inspect --bootstrap
docker buildx build --push --platform linux/arm/v7 --tag quay.io/shesselink81/cadvisor:v0.37.5-armv7 .