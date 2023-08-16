ARG TRINO_BIN_VERSION="423"
FROM trinodb/trino:${TRINO_BIN_VERSION}
USER root
RUN apt-get update && apt-get install -y zip && apt-get upgrade -y openssl bash gzip
USER trino
RUN mkdir -p /usr/lib/trino/plugin/ext
COPY trino-ext-authz/build/libs/trino-ext-authz.jar /usr/lib/trino/plugin/ext/trino-ext-authz.jar
COPY trino-ext-authz/build/ext/ /usr/lib/trino/plugin/ext/

COPY hive-authz/build/libs/hive-authz.jar /usr/lib/trino/plugin/hive/hive-authz.jar
COPY plugins.sh /tmp/plugins.sh
RUN /tmp/plugins.sh
USER root
RUN apt-get remove -y zip tar wget 

USER trino



