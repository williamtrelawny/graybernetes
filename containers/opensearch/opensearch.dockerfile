ARG VERSION
FROM ubuntu:jammy-20240911.1
ARG VERSION
ENV CONTAINER_VERSION=$VERSION
# Lock below to latest version supported by Graylog
# ref: https://go2docs.graylog.org/current/downloading_and_installing_graylog/installing_graylog.html#CompatibilityMatrix
ENV OPENSEARCH_VERSION=2.15.0
ENV OPENSEARCH_INITIAL_ADMIN_PASSWORD=YabbaDabbaD00!

# Switch to Berkeley OCF mirror for updates, install curl and gnupg
RUN sed -i 's|ports.ubuntu.com|mirrors.ocf.berkeley.edu|g' /etc/apt/sources.list && apt update && apt install --no-install-recommends -y ca-certificates curl gnupg wget && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /etc/ssl/private/ssl-cert-snakeoil.key && install -m 0755 -d /etc/apt/keyrings

# Add Opensearch repository
RUN curl -o- https://artifacts.opensearch.org/publickeys/opensearch.pgp | sudo gpg --dearmor --batch --yes -o /usr/share/keyrings/opensearch-keyring
RUN echo "deb [arch="$(dpkg --print-architecture)" signed-by=/usr/share/keyrings/opensearch-keyring] https://artifacts.opensearch.org/releases/bundle/opensearch/2.x/apt stable main" | tee /etc/apt/sources.list.d/opensearch-2.x.list

# Configure supervisord
COPY contents/supervisor/supervisord.conf /etc/supervisord.conf
COPY --chown=runtime:runtime contents/supervisor/autoinit.sh /opt/supervisor/bin

# Configure entrypoint
EXPOSE 5044/tcp
EXPOSE 5140/tcp
EXPOSE 5140/udp
EXPOSE 9000/tcp
EXPOSE 12201/tcp
EXPOSE 12201/udp
EXPOSE 13301/tcp
EXPOSE 13302/tcp
USER runtime
WORKDIR /opt/supervisor/logs
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]