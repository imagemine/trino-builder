#!/usr/bin/env bash

clean_unused_files() {
  local target=$1
  local mode=$2
  local n=0
  local cleaned=0
  for jf in $(ls $target);
  do
    cleaned=0
    for pom in $(jar tvf $target/$jf|grep -E "pom.(xml|properties)$"|awk -F" " '{print $8}');
    do
      zip -q -d $target/$jf $pom
      cleaned=1
    done;
    if [[ $cleaned -eq 1 ]] || [[ $jf =~ ^[a-z]+.*$ ]];
    then
      ok=1
      echo $(date) $jf > RELEASE
      zip -q -u $target/$jf RELEASE
      if [[ "$mode" == "1" ]]; then
        mv $target/$jf $target/lib-$n.jar
      fi;
    fi;
    n=$((n+1))
  done;
}
wd=$(pwd)
cd /tmp
clean_unused_files /usr/lib/trino/lib 1

for d in $(ls /usr/lib/trino/plugin);
do
  echo clean up $d
  clean_unused_files /usr/lib/trino/plugin/$d 1;
done;
cd $wd

