ARG TRINO_BIN_VERSION="436"
FROM trinodb/trino:${TRINO_BIN_VERSION}
USER root
RUN microdnf update -y && \
    microdnf install -y zip openssl bash gzip tar wget && \
    microdnf upgrade -y
USER trino
RUN mkdir -p /usr/lib/trino/plugin/ext
COPY trino-ext-authz/build/libs/trino-ext-authz.jar /usr/lib/trino/plugin/ext/trino-ext-authz.jar
COPY trino-ext-authz/build/ext/ /usr/lib/trino/plugin/ext/

COPY hive-authz/build/libs/hive-authz.jar /usr/lib/trino/plugin/hive/hive-authz.jar
COPY plugins.sh /tmp/plugins.sh
RUN /tmp/plugins.sh
USER root
RUN apt-get remove -y zip 

USER trino



