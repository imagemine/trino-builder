#!/usr/bin/env bash

extra_libs() {
  local target=$1
  local lib_file="/tmp/extra-libs.properties"
  for line in $(cat ${lib_file});
  do
    echo $line
    fname=$(basename $line)
    patt="^"$(echo $fname|sed -E "s/[0-9]+\.[0-9]+\.[0-9]+/[0-9]+\.[0-9]+\.[0-9]+/g")"$"
    set +e
    matching_file=$(ls $target|grep -E $patt|head -1)
    if [[ $matching_file != "" ]];
    then
      echo removing old version ${matching_file} and replacing with ${fname}
      rm $target/$matching_file
    fi;
    set -e
    curl -sL -o ${target}/${fname} ${line}
  done;
}

remove_libs() {
  local target=$1
  local lib_file="/tmp/delete-libs.properties"
  for line in $(cat ${lib_file});
  do
    for jf in $(ls $target);
    do
      if [[ -d $target/$jf ]]; then
        remove_libs $target/$jf
      else
        if [[ "$jf" == "$line" ]]; then
          echo removing jar $target/$jf
          rm $target/$jf
        fi;
      fi;
    done
  done;
}

clean_unused_files() {
  local target=$1
  local mode=$2
  local n=0
  local cleaned=0
  for jf in $(ls $target);
  do
    if [[ -d $target/$jf ]]; then
      clean_unused_files $target/$jf 1;
    else
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
          echo $target/$jf $target/lib-$n.jar
          mv $target/$jf $target/lib-$n.jar
        fi;
      fi;
    n=$((n+1))
    fi
  done;
}

wd=$(pwd)
cd /tmp
clean_unused_files /usr/lib/trino/lib 1

extra_libs /usr/lib/trino/plugin/ext
remove_libs /usr/lib/trino/plugin
for d in $(ls /usr/lib/trino/plugin);
do
  echo clean up $d
  clean_unused_files /usr/lib/trino/plugin/$d 1;
done;
cd $wd

