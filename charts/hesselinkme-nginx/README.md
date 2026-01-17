# Hesselink.me Nginx

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v2.0.3](https://img.shields.io/badge/AppVersion-v2.0.3-informational?style=flat-square)

Hesselink.me Nginx Helm chart

## Prerequisites

- Kubernetes 1.12+
- Helm 3.0+

## Installing the Chart

To install the chart with the release name `hesselinkme-nginx`:

```bash
helm install hesselinkme-nginx ./charts/hesselinkme-nginx
```

## Uninstalling the Chart

To uninstall the chart with the release name `hesselinkme-nginx`:

```bash
helm uninstall hesselinkme-nginx
```

## Configuration

The following table lists the configurable parameters of the Hesselink.me Nginx chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | The image repository | `quay.io/shesselink81/hesselinkme-nginx` |
| `image.tag` | The image tag | `v2.0.5` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `replicaCount` | Number of replicas | `1` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `8080` |
| `containerPort` | Container port | `80` |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```bash
helm install hesselinkme-nginx ./charts/hesselinkme-nginx -f values.yaml
```