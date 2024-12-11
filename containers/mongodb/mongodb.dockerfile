ARG VERSION
FROM ubuntu:noble-20241118.1
ARG VERSION
ENV CONTAINER_VERSION=$VERSION
# Lock below to latest version supported by Graylog
# ref: https://go2docs.graylog.org/current/downloading_and_installing_graylog/installing_graylog.html#CompatibilityMatrix
ENV MONGODB_VERSION=7.0

# Switch to Berkeley OCF mirror for updates, install curl and gnupg
RUN sed -i 's|ports.ubuntu.com|mirrors.ocf.berkeley.edu|g' /etc/apt/sources.list && apt update && apt install --no-install-recommends -y ca-certificates curl gnupg wget && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /etc/ssl/private/ssl-cert-snakeoil.key && install -m 0755 -d /etc/apt/keyrings

# Add MongoDB repository
RUN curl -fsSL https://pgp.mongodb.com/server-${MONGODB_VERSION}.asc | gpg -o /usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg --dearmor
RUN echo "deb [arch="$(dpkg --print-architecture)" signed-by=/usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/${MONGODB_VERSION} multiverse" | tee /etc/apt/sources.list.d/mongodb-org-${MONGODB_VERSION}.list

# Install MongoDB package, then create runtime user and directories
RUN apt update && apt upgrade -y && \
DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt install --no-install-recommends -y less mongodb-org nano supervisor && \
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /etc/ssl/private/ssl-cert-snakeoil.key && \
addgroup runtime && useradd -g runtime runtime && \
mkdir -p /data && chmod a+rwx /data && \
mkdir -p /opt/supervisor/bin && mkdir -p /opt/supervisor/logs && chown -R runtime:runtime /opt/supervisor && \
mkdir -p /usr/local/var && chown -R runtime:runtime /usr/local/var && \
chown -R runtime:runtime /var/log/mongodb

# Configure supervisord
COPY ./supervisord.conf /etc/supervisord.conf
COPY --chown=runtime:runtime ./autoinit.sh /opt/supervisor/bin

# Expose entrypoint
EXPOSE 27017
USER runtime
WORKDIR /opt/supervisor/logs
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]