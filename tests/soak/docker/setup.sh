#!/bin/sh
set -eu
cd /app
test -z "$(ls -A /app)"
cp -R /work/app/. /app/
box install
box install /work/package/quick.zip --noSave
# Expand the pinned engine while setup still has network access. No application
# requests run here; the measured application boots later in a fresh JVM.
box server start --noSaveSettings
box server stop
curl --fail --silent --show-error --location --max-time 60 \
  https://repo.maven.apache.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.jar \
  --output .engine/WEB-INF/lucee-server/bundles/com.mysql.cj-8.0.33.jar
printf '%s\n' 'e2a3b2fc726a1ac64e998585db86b30fa8bf3f706195b78bb77c5f99bf877bd9  .engine/WEB-INF/lucee-server/bundles/com.mysql.cj-8.0.33.jar' | sha256sum --check --strict
javac --add-modules jdk.attach,jdk.management.jfr -d /work/classes /work/collector/Collector.java
