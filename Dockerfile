ARG TRINO_BIN_VERSION="447"
FROM trinodb/trino:${TRINO_BIN_VERSION}
USER root
RUN microdnf update -y && \
    microdnf install -y zip openssl bash gzip tar wget && \
    microdnf upgrade -y

RUN mkdir -p /usr/lib/trino/plugin/ext && \
    mkdir -p /usr/lib/trino/plugin/hive && \
    chown -R trino:trino /usr/lib/trino/plugin

COPY trino-ext-authz/build/libs/trino-ext-authz.jar /usr/lib/trino/plugin/ext/trino-ext-authz.jar
COPY trino-ext-authz/build/ext/ /usr/lib/trino/plugin/ext/

COPY hive-authz/build/libs/hive-authz.jar /usr/lib/trino/plugin/hive/hive-authz.jar
COPY extra-libs.properties /tmp/extra-libs.properties
COPY delete-libs.properties /tmp/delete-libs.properties
COPY plugins.sh /tmp/plugins.sh

# Remove zip and switch back to trino user
RUN microdnf remove -y zip

USER trino
