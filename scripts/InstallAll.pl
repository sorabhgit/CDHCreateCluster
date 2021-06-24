#!/usr/bin/perl

use Getopt::Long;
use File::Basename;
use strict;

our $gOption;
our $gServersList;
our $gLogFile; 
our $gLocal;
our $gNoLocal;

our @serversList;

our $gScriptsHomeDir;

&getParams;


&main;


######################################
# sub getParams
######################################
sub getParams {

my $opt_status = GetOptions("opt=s"           =>  \$gOption,
			    "s=s"	      =>  \$gServersList,
			    "l:s"	      =>  \$gLocal,
			    "n:s"	      =>  \$gNoLocal,
                            "log=s"           =>  \$gLogFile);


        &Usage if (! defined($gOption)) ;
        &Usage if (! defined($gServersList)) ;

}

######################################
# sub main
######################################
sub main {

&getServerInfo;

&checkPropertiesVars;


if ($gOption == 0) {
        &runStep0;
} elsif ($gOption == 1) {
        &runStep1;
} elsif ($gOption == 2) {
        &runStep2;
} elsif ($gOption == 3) {
        &runStep3;
} elsif ($gOption == 4) {
        &runStep4;
} elsif ($gOption == 5) {
        &runStep5;
} else {
        print "\nUnknown Option '$gOption' \n\n";
        &Usage;
}

}

######################################
# sub getServerInfo
######################################
sub getServerInfo {

my $mHost;
my $mDirName;
my $mPropsFile;
my $mLine;

$mDirName = `dirname $0`;
chomp($mDirName);

$gScriptsHomeDir = `readlink -f $mDirName`;
chomp($gScriptsHomeDir);

$gScriptsHomeDir = dirname($gScriptsHomeDir);

$mPropsFile = "$gScriptsHomeDir/properties/cdh_props.sh";

@serversList = split (/,/, $gServersList) ;

print "serversList = @serversList \n\n";

if ($gOption != 0) {
	foreach $mHost (@serversList) {
		print "checkSSHConnection $mHost \n";
		&checkSSHConnection($mHost) ;
	}
}


open(PROPS_FILE,"$mPropsFile") || die "can't open file $mPropsFile . exit .....";

for $mLine (<PROPS_FILE>) {
        if ($mLine =~ /^export\s+(.*)=(.*)/) {
                $ENV{$1} = $2 ;
        }
}

close(PROPS_FILE);


}

######################################
# sub checkPropertiesVars
######################################
sub checkPropertiesVars {

my $mVarsList;
my $mVar;
my @mVarsList;

@mVarsList = qw(RHEL_VERSION CDH_VERSION);

for $mVar (@mVarsList) {
	if ( $ENV{$mVar} =~ /^$/ ) {
		print "\nError: The Variable '$mVar' is missing, Aborting....\n\n\n";
		exit 1;
	}
}

}

######################################
# sub checkSSHConnection
######################################
sub checkSSHConnection {

my ($mHostName) = @_;
my $sshCmd;

#$sshCmd = "ssh $mHostName 'ls  > /dev/null'";

$sshCmd = "ssh -o 'StrictHostKeyChecking no'  '-oBatchMode=yes' $mHostName date >> /dev/null " ;

if (system("$sshCmd")) {

	print "\nError: There is problem to connect to $mHostName, check the ssh permissions. Exit... \n\n" ;
	exit 1;

}

}


######################################
# sub createEtcHostsFile
######################################
sub createEtcHostsFile {

my $hosname_ip;
my $hostname_file;
my $hostname_fqdn;
my $tmp_hosts_file = "/tmp/hosts.temp";

my $mHost;
my $mLocalHostName;
my $mLocalInd;

$mLocalHostName = `hostname`;
chomp($mLocalHostName);

system("rm -f /etc/hosts");

open(HOSTS_FILE,">$tmp_hosts_file") || die "can't open file $tmp_hosts_file for writting. exit .....";

$hosname_ip=`hostname -i` ;
chomp($hosname_ip);

$hostname_file = `hostname`;
chomp($hostname_file);

$hostname_fqdn  = `hostname -f`;
chomp($hostname_fqdn);

print HOSTS_FILE  "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4\n" ;
print HOSTS_FILE  "::1         localhost localhost.localdomain localhost6 localhost6.localdomain6\n\n" ;

print HOSTS_FILE "$hosname_ip $hostname_fqdn $hostname_file \n" ;

foreach $mHost (@serversList) {

        next if ($mLocalHostName eq $mHost);

        system("ssh ${mHost} rm -f /etc/hosts");
  	
	$hosname_ip = `ssh $mHost hostname -i` ;
	chomp($hosname_ip);

	$hostname_file = `ssh $mHost hostname`;
	chomp($hostname_file);

	$hostname_fqdn  = `ssh $mHost hostname -f`;
	chomp($hostname_fqdn);

	print HOSTS_FILE "$hosname_ip $hostname_fqdn $hostname_file \n" ;

}

system("cp -f $tmp_hosts_file /etc/hosts");

foreach $mHost (@serversList) {

        next if ($mLocalHostName eq $mHost);
	system("scp $tmp_hosts_file ${mHost}:/etc/hosts");

}

print "\nCreating $tmp_hosts_file \n\n";

}

######################################
# sub copyScripts
######################################
sub copyScripts {

my ($mHostName) = @_;
my $scpCmd_1;
my $scpCmd_2;

system("ssh $mHostName \"mkdir -p $gScriptsHomeDir\"");

$scpCmd_1 = "scp -rp ${gScriptsHomeDir}/tools $mHostName:${gScriptsHomeDir}" ;
$scpCmd_2 = "scp -rp ${gScriptsHomeDir}/RPMS $mHostName:${gScriptsHomeDir}" ;

print "$scpCmd_1 \n";
system("$scpCmd_1");

print "$scpCmd_2 \n";
system("$scpCmd_2");


}


######################################
# sub runLocalCommand
######################################
sub runLocalCommand {

my ($mScriptName) = @_;

my $mCmd;
my $return_status;

$mCmd = "${gScriptsHomeDir}/tools/${mScriptName}" ;

print "Running $mCmd \n\n";

system("$mCmd");

$return_status = $? ;

return if ($mCmd =~ /BDA_Uninstall/) ;

#print "The return status of the command is $return_status\n\n";

if ($return_status != 0) {

        print "\nThere was a problem when running the command '$mCmd' , Aborting .........\n\n";
        exit 1;

}


}

######################################
# sub runRemoteCommand
######################################
sub runRemoteCommand {

my ($mHost,$mScriptName) = @_;

my $mCmd;

$mCmd = "ssh $mHost '${gScriptsHomeDir}/tools/$mScriptName' " ;

print "$mCmd \n\n";

system("$mCmd");


}

######################################
# sub runStep0 - create ssh-key
######################################
sub runStep0 {

&runLocalCommand("BDA_create_ssh_key.sh $gServersList") ;

}

######################################
# sub runStep1   - create redhat repo 
######################################
sub runStep1 {

my $mHost;

my $mLocalHostName;

my $mLocalInd;

$mLocalHostName = `hostname`;
chomp($mLocalHostName);

&runLocalCommand("BDA_CreateLocalRedHatRepo.sh $ENV{RHEL_VERSION} $ENV{CDH_VERSION}") ;

        foreach $mHost (@serversList) {

                next if ($mLocalHostName eq $mHost);
                &copyScripts($mHost) ;
                &runRemoteCommand($mHost,"BDA_CreateLocalRedHatRepo.sh $ENV{RHEL_VERSION} $ENV{CDH_VERSION}") ;

        }

}

######################################
# sub runStep2  install cloudera
######################################
sub runStep2 {

my $mHost;

my $mLocalHostName;

$mLocalHostName = `hostname`;
chomp($mLocalHostName);

&createEtcHostsFile;

&runLocalCommand("BDA_RunClouderaManager.sh MASTER $mLocalHostName") ;

        foreach $mHost (@serversList) {

                next if ($mLocalHostName eq $mHost);
                &copyScripts($mHost) ;
                &runRemoteCommand($mHost,"BDA_RunClouderaManager.sh NODE $mLocalHostName") ;

        }



}

######################################
# sub runStep3
######################################
sub runStep3 {

&runLocalCommand("BDA_Update_Cdh_Silent_Script.sh") ;

&runLocalCommand("BDA_CdhSilent.sh cluster $ENV{CDH_VERSION} \"@serversList\" ") ;

&runLocalCommand("Check_Cdh_Status.sh") ;


}

######################################
# sub runStep4
######################################
sub runStep4 {

my $mHost;
my $mLocalHostName = `hostname`;
chomp($mLocalHostName);


system("useradd -u 2600 lights -p abRbW2JCXeavM");
system("useradd -u 2700 bdauser -p abF/LdN6QUXG2");

system("sudo -u hdfs hdfs dfs -mkdir -p /user/bdauser");
system("sudo -u hdfs hdfs dfs -chown bdauser:bdauser /user/bdauser");

foreach $mHost (@serversList) {
	next if ($mLocalHostName eq $mHost);
	system("ssh $mHost useradd -u 2600 lights -p abRbW2JCXeavM");
	system("ssh $mHost useradd -u 2700 bdauser -p abF/LdN6QUXG2");
}


}

######################################
# sub runStep5
######################################
sub runStep5 {

my $mHost;
my $mLocalHostName = `hostname`;
chomp($mLocalHostName);

&runLocalCommand("BDA_Uninstall_CDH.sh MASTER") ;
#&runLocalCommand("BDA_Uninstall_HDP.sh") ;

        foreach $mHost (@serversList) {

                next if ($mLocalHostName eq $mHost);
                &copyScripts($mHost) ;
                &runRemoteCommand($mHost,"BDA_Uninstall_CDH.sh") ;
#               &runRemoteCommand($mHost,"BDA_Uninstall_HDP.sh") ;

        }

}

######################################
# sub Usage
######################################
sub Usage {

        my $command = `basename $0` ;
        chomp($command) ;

        print STDOUT "\nUsage: \n\n\t$command  -opt <option_number> -s <servers_list> [-l] \n\n";
        print STDOUT "-opt \n\n";
        print STDOUT "\t 0 - Add ssh-key, for login without password. \n";
        print STDOUT "\t 1 - Add redhat local repo to /etc/yum.repos.d\n";
        print STDOUT "\t 2 - Install Cloudera manager and agent componenets.\n";
        print STDOUT "\t 3 - Run Cloudera cdh silent installation.\n";
        print STDOUT "\t 4 - Run Post Installation.\n";
        print STDOUT "\t 5 - Uninstall CDH.\n\n\n";

        exit 1;

}


