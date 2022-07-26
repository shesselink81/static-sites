docker build  --build-arg "GRAFANA_VERSION=latest" --build-arg "GF_INSTALL_IMAGE_RENDERER_PLUGIN=false" --build-arg "GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-piechart-panel" -t quay.io/shesselink81/grafana:latest -f Dockerfile .
docker push quay.io/shesselink81/grafana:latest
