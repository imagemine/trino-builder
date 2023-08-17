#!/usr/bin/env bash

set -euo pipefail
: "${version:=${1:-423}}"

WORK_DIR="docker-build"
if [[ ! -d ${WORK_DIR} ]];
then
  mkdir ${WORK_DIR}
fi;

if [[ ! -f ${WORK_DIR}/trino-server-${version}.tar.gz ]];
then
  curl -sk -o ${WORK_DIR}/trino-server-${version}.tar.gz https://repo1.maven.org/maven2/io/trino/trino-server/${version}/trino-server-${version}.tar.gz
else
  echo trino server exists. skipping download
fi;

TRINO_DIR=${WORK_DIR}/trino
if [[ -d ${TRINO_DIR} ]];
then
  rm -rf ${TRINO_DIR}
fi;

tar zxf ${WORK_DIR}/trino-server-${version}.tar.gz -C ${WORK_DIR}

mv docker-build/trino-server-${version} ${TRINO_DIR}
mkdir -p ${TRINO_DIR}/plugin/ext
cp trino-ext-authz/build/libs/trino-ext-authz.jar ${TRINO_DIR}/plugin/ext/trino-ext-authz.jar
cp -r trino-ext-authz/build/ext/ ${TRINO_DIR}/plugin/ext/

cp hive-authz/build/libs/hive-authz.jar ${TRINO_DIR}/plugin/hive/hive-authz.jar
cp run-trino ${TRINO_DIR}/bin/run-trino

#./plugins.sh ${TRINO_DIR}


