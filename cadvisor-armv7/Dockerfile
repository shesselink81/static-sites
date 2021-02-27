# Builder
# FROM arm32v7/golang as builder

# ENV CADVISOR_VERSION "v0.37.5"

# RUN apt-get update && apt-get install -y git dmsetup && apt-get clean

# RUN git clone --branch ${CADVISOR_VERSION} https://github.com/google/cadvisor.git /go/src/github.com/google/cadvisor

# WORKDIR /go/src/github.com/google/cadvisor

# RUN make build

# Image for usage
FROM arm32v7/alpine

RUN apk --no-cache add libc6-compat device-mapper findutils ndctl && \
    apk --no-cache add thin-provisioning-tools --repository http://dl-3.alpinelinux.org/alpine/edge/main/ && \
    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf && \
    rm -rf /var/cache/apk/*

COPY ./cadvisor-armv7/bin/cadvisor /usr/bin/cadvisor

EXPOSE 8080
ENTRYPOINT ["/usr/bin/cadvisor", "-logtostderr"]