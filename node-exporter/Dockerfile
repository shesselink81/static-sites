FROM prom/node-exporter:master

ENV NODE_ID=none

USER root

COPY ./node-exporter/conf /etc/node-exporter/

ENTRYPOINT  [ "/etc/node-exporter/docker-entrypoint.sh" ]
CMD [ "/bin/node_exporter" ]
