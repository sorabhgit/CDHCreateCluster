#!/bin/bash

DIRNAME=$(dirname $0)
SCRIPTS_HOME_DIR=$(readlink -f $DIRNAME)

hostname=`hostname`
cdh_version=$2
nodes_list=$1
SECURE_IND=$3

HOST_NAME=`hostname | tr 'a-z' 'A-Z'`

if [[ -z $nodes_list ]] 
then
	printf "\nUsage:\n\n\t `basename $0` <namenodes_list> [-s] \n\n"
	printf "Example:\n\n\t `basename $0`   bda-env-2,bda-env-3 \n\n"
	exit 1
fi

export PATH=/usr/sbin:$PATH

cd ${SCRIPTS_HOME_DIR}

printf "${SCRIPTS_HOME_DIR}/InstallAll.pl -opt 0 -s $nodes_list \n\n"
${SCRIPTS_HOME_DIR}/InstallAll.pl -opt 0 -s $nodes_list

printf "${SCRIPTS_HOME_DIR}/InstallAll.pl -opt 5 -s $nodes_list \n\n"
${SCRIPTS_HOME_DIR}/InstallAll.pl -opt 5 -s $nodes_list

printf "${SCRIPTS_HOME_DIR}/InstallAll.pl -opt 1 -s $nodes_list \n\n"
${SCRIPTS_HOME_DIR}/InstallAll.pl -opt 1 -s $nodes_list

printf "${SCRIPTS_HOME_DIR}/InstallAll.pl -opt 2 -s $nodes_list \n\n"
${SCRIPTS_HOME_DIR}/InstallAll.pl -opt 2 -s $nodes_list

printf "sleep 30\n\n"
sleep 30


printf "${SCRIPTS_HOME_DIR}/InstallAll.pl -opt 3 -s $nodes_list \n\n"
${SCRIPTS_HOME_DIR}/InstallAll.pl -opt 3 -s $nodes_list

printf "${SCRIPTS_HOME_DIR}/InstallAll.pl -opt 4 -s $nodes_list \n\n"
${SCRIPTS_HOME_DIR}/InstallAll.pl -opt 4 -s $nodes_list


if [[ $SECURE_IND == "-s" ]]
then
	printf "${SCRIPTS_HOME_DIR}/../security/CreateKerboresSecurity.sh -r ${HOST_NAME}.KERBEROS.COM  -s $nodes_list \n\n"
	${SCRIPTS_HOME_DIR}/../security/CreateKerboresSecurity.sh -r ${HOST_NAME}.KERBEROS.COM  -s $nodes_list -i 2500
fi


printf "End Of Installation \n\n\n"

printf "Check cloudera manager at the URL 'http://${hostname}:7180' \n\n"



