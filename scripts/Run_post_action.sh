#!/bin/bash

DIRNAME=$(dirname $0)
SCRIPTS_HOME_DIR=$(readlink -f $DIRNAME)

useradd lights -p abRbW2JCXeavM
useradd bdauser -p abF/LdN6QUXG2

sudo -u hdfs hdfs dfs -mkdir -p /user/bdauser
sudo -u hdfs hdfs dfs -chown bdauser:bdauser /user/bdauser

# extract ext-2.2 for oozie GUI
cd /var/lib/oozie
tar -xvf ${SCRIPTS_HOME_DIR}/../jars/ext-2.2.tar > /dev/null


