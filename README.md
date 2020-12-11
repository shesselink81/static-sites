# dockerfiles
cmds:
* docker buildx build --platform linux/amd64,linux/arm/v7,linux/arm64 -t shesselink81/node-exporter:latest-multi --push .
* docker buildx build --platform linux/amd64,linux/arm/v7,linux/arm/v6,linux/arm64 -t shesselink81/dockerd-exporter:latest-multi --push .
