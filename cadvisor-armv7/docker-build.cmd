docker build --platform linux/arm/v7 --tag quay.io/shesselink81/cadvisor:v0.37.5-armv7 -f .\cadvisor-armv7\Dockerfile --no-cache .
docker push quay.io/shesselink81/cadvisor:v0.37.5-armv7