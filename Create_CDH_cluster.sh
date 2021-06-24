#!/bin/bash 

cdh_version=$1
manager_host=$2
datanode_hosts=$3
UnInstall_Only=false
Reinstall=true
secure_cluster=false
run_bda_post_script=false
WORKSPACE=/home/admin/CDH_Auto_Installation

function check_status
{

return_status=$1

printf "The return status is $return_status \n\n"

if [[ $return_status != 0 ]]
then
	printf "There was a failure in the last commnad, Aborting.....\n\n"
	exit 1
fi


}

printf "cdh_version=$cdh_version \nmanager_host=$manager_host \ndatanode_hosts=$datanode_hosts \nsecure_cluster=$secure_cluster \nrun_bda_post_script=$run_bda_post_script\n\n"

package_installation_name="CDH_Auto_Installation"

if [[ -z $manager_host || -z $datanode_hosts ]]
then
	printf "\nUsage:\n\n\t `basename $0` <cdh_version> <manager_host> <node_hosts_list> [-s]\n\n"
	printf "For Example:\n\n\t `basename $0` cdh551 ilvbdsi807 ilvbdsi808,ilvbdsi809 \n\n"
	echo "-s: Create secured cluster."
	echo ""
	exit 1
fi


if [[ $cdh_version != "cdh551" && $cdh_version != "cdh582" ]] 
then
	printf "\n\nError: cdh_version must be 'cdh551' or 'cdh582' , aborting.... \n\n"
	exit 1
fi

HOST_NAME=`echo $manager_host | tr 'a-z' 'A-Z'`

datanode_hosts=`echo $datanode_hosts | sed "s/ //g"`

chmod -R 755 $WORKSPACE/

cd $WORKSPACE/cluster_installation/cdh/${cdh_version}/
tar -cvf $HOME/CDH_Auto_Installation.tar CDH_Auto_Installation

ls -l $HOME/CDH_Auto_Installation.tar

scp $HOME/${package_installation_name}.tar  root@${manager_host}:/root/.

ssh root@${manager_host} tar -xvf ${package_installation_name}.tar

# Uninstall Only

if [[ $UnInstall_Only == "true" ]]
then
        printf "ssh root@${manager_host} /root/${package_installation_name}/scripts/InstallAll.pl -opt 5 -s $datanode_hosts \n\n"
        ssh root@${manager_host} /root/${package_installation_name}/scripts/InstallAll.pl -opt 5 -s $datanode_hosts
	exit $?
fi

# Uninstall before installation

if [[ $Reinstall == "true" ]]
then
	printf "ssh root@${manager_host} /root/${package_installation_name}/scripts/InstallAll.pl -opt 5 -s $datanode_hosts \n\n"
	ssh root@${manager_host} /root/${package_installation_name}/scripts/InstallAll.pl -opt 5 -s $datanode_hosts
fi

## start the installation

printf "ssh root@${manager_host} /root/${package_installation_name}/scripts/InstallAll.pl -opt 0 -s $datanode_hosts \n\n"
ssh root@${manager_host} /root/${package_installation_name}/scripts/InstallAll.pl -opt 0 -s $datanode_hosts
check_status $?

printf "ssh root@${manager_host} /root/${package_installation_name}/scripts/InstallAll.pl -opt 1 -s $datanode_hosts \n\n"
ssh root@${manager_host} /root/${package_installation_name}/scripts/InstallAll.pl -opt 1 -s $datanode_hosts
check_status $?

printf "ssh root@${manager_host} /root/${package_installation_name}/scripts/InstallAll.pl -opt 2 -s $datanode_hosts \n\n"
ssh root@${manager_host} /root/${package_installation_name}/scripts/InstallAll.pl -opt 2 -s $datanode_hosts
check_status $? 

printf "sleep 30\n\n"
sleep 30

printf "ssh root@${manager_host} /root/${package_installation_name}/scripts/InstallAll.pl -opt 3 -s $datanode_hosts \n\n"
ssh root@${manager_host} /root/${package_installation_name}/scripts/InstallAll.pl -opt 3 -s $datanode_hosts
check_status $? 

printf "ssh root@${manager_host} /root/${package_installation_name}/scripts/InstallAll.pl -opt 4 -s $datanode_hosts \n\n"
ssh root@${manager_host} /root/${package_installation_name}/scripts/InstallAll.pl -opt 4 -s $datanode_hosts
check_status $?

#printf "\n\n ssh root@${manager_host} /root/${package_installation_name}/scripts/Build_ALL.sh $datanode_hosts $secure_cluster \n\n"
#ssh root@${manager_host} /root/${package_installation_name}/scripts/Build_ALL.sh $datanode_hosts $secure_cluster

if [[ $secure_cluster == "true" ]]
then
	printf "ssh root@${manager_host} /root/${package_installation_name}/security/CreateKerboresSecurity.sh -r ${HOST_NAME}.KERBEROS.COM  -s $datanode_hosts -i 2500 \n\n"
	ssh root@${manager_host} /root/${package_installation_name}/security/CreateKerboresSecurity.sh -r ${HOST_NAME}.KERBEROS.COM  -s $datanode_hosts -i 2500
	check_status $?
fi



if [[ $run_bda_post_script == "true" ]]
then
	printf "ssh root@${manager_host} /root/${package_installation_name}/bda-post-actions/Run_post_action.sh $manager_host \n\n"
	ssh root@${manager_host} /root/${package_installation_name}/bda-post-actions/Run_post_action.sh $manager_host
fi

