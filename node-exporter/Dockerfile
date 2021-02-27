FROM prom/node-exporter:latest

ENV NODE_ID=none

USER root

COPY conf /etc/node-exporter/
RUN chmod 755 /etc/node-exporter/docker-entrypoint.sh
ENTRYPOINT  [ "/etc/node-exporter/docker-entrypoint.sh" ]
CMD [ "/bin/node_exporter" ]
