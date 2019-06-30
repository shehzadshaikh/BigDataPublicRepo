###########################################################3
# Cloudera Installation external Database
#

# Hadoop pre-requisites

# Configure Network
----------
#RHEL/CentOS 6
chkconfig NetworkManager off
chkconfig network on
service network restart
sed -i "s/localhost/$(hostnmae -f)/g" /etc/sysconfig/network

#RHEL/CentOS 7
systemctl disable NetworkManager
systemctl enable network
systemctl restart network

# Disable iptables and ipv6
------------
#RHEL/CentOS 6
chkconfig iptables off
chkconfig ip6tables off
service iptables stop
service ip6tables stop

# Turn on ntpd and httpd
-------------
yum install -y ntp httpd
chkconfig ntpd on
chkconfig httpd on
service ntpd start
service httpd start

# Firewalld for RHEL/CentOS 7
----------
systemctl stop firewalld
systemctl disable firewalld

# Configure DNS (hosts mapping)
-----------
sudo vi /etc/hosts
# ip 	FQDN	hostname-alias
10.10.0.2 master01.ojunkie.com m1
10.10.0.3 master02.ojunkie.com m2
10.10.0.4 worker01.ojunkie.com w1
10.10.0.5 worker02.ojunkie.com w2
10.10.0.6 worker03.ojunkie.com w3

# Disable SELinux
-----------------
# temporary setting SELinux to permissive
getenforce
setenforce 0

# disable SELinux permenantly, below changes require OS reboot to take effect
sed -i 's/SELINUX=enforcing/SELINUX=disable/g' /etc/selinux/config

vi /etc/selinux/config
SELINUX=disabled

# Disable Swapiness
-------------
# Swapiness is the process of transmitting data from RAM to HDD when there is more requirement of RAM for other application to execute. Default value for swapiness is 60, i.e. after 40% RAM consumption system will swap it back to HDD causing application to run slow. Cloudera & Hortonworks recommend swapiness value to be 10% or 0.
echo "vm.swappiness = 0" >> /etc/sysctl.conf
sysctl -p

# Disable THP (Transparent Huge Page Compaction)
-------------
# Transparent Huge Page Compaction can cause significant performance problems. According RedHat Systems there is Huge Pages & Transparent Huge Pages.
 # Huge Pages are blocks of memory which are 1096 bytes in size.
 # Transparent Huge Pages are an abstraction on the Huge Pages to make it bigger so that mapping size will smaller (somewhat similar fsimage and edits relation in HDFS)
echo "echo never > /sys/kernel/mm/redhat_transparent_hugepage/enable" >> /etc/rc.local
echo "echo never > /sys/kernel/mm/redhat_transparent_hugepage/defrag" >> /etc/rc.local
source /etc/rc.local

# rhel/centos7
echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.local
echo "echo never > /sys/kernel/mm/transparent_hugepage/defrag" >> /etc/rc.local
source /etc/rc.local


# UMASK (User Mask or User-File-Creation Mask)
-------------
# UMASK sets the default permissions or base permissions when a new file or folder is created on a Linux machine. A umask value of 022 grants read, write, execute permissions of 755 for new files or folders.
# check your current umask:
umask

# set permenant umask value
echo umask 0022 >> /etc/profile
soruce /etc/profile


# configure DNS
vi /etc/sysconfig/network
HOSTNAME=cdh01.nxtbigthing.com
NETWORKING_IPV6=False
NETWORKING=yes
NOZEROCONF=yes

# identify the MAC address
ip a | grep -i link/ether | awk {'print $2'} | head -n1

    link/ether 42:01:0a:c4:8b:8b brd ff:ff:ff:ff:ff:ff
#MAC => 42:01:0a:c4:8b:8b

# configure the eth-config for nic HWADDR is MAC address
cp /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth0.backup
vi /etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE="eth0"
HWADDR="42:01:0a:c4:70:02"
USERCTL="no"
TYPE="Ethernet"
BOOTPROTO="dhcp"
ONBOOT="yes"
PEERDNS="yes"
NM_CONTROLLED="no"

# disable network manager
systemctl status NetworkManager
systemctl disable NetworkManager
systemctl stop NetworkManager

# ensure network is enable and running
systemctl status network

# set hostname
hostnamectl --help to set hostname
hostnamectl set-hostname gcp5659hdpdr02.res01.slb-ds.com

# remove auto entry for hostname by google
grep -ri 'set_hostname' /etc/*

which google_set_hostname
cat /bin/google_set_hostname

# move script to  to some other location
mv /bin/google_set_hostname /root/

reboot

=========================================================================================
# startup script makesure to change the FQDN to desire name

#!/bin/bash
FQDN=cdh01.nxtbigthing.com

sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
setenforce 0
echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.local
echo "echo never > /sys/kernel/mm/transparent_hugepage/defrag" >> /etc/rc.local
source /etc/rc.local
yum -y install ntp
systemctl enable ntpd
systemctl restart ntpd
systemctl enable chronyd
systemctl restart chronyd
systemctl disable firewalld
systemctl stop firewalld
echo "vm.swappiness = 0" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6 = 1 " >> /etc/sysctl.conf
sysctl -p

echo "HOSTNAME=$FQDN
NETWORKING_IPV6=False
NETWORKING=yes
NOZEROCONF=yes" > /etc/sysconfig/network

MAC_ADDR=`ip a | grep -i link/ether | awk {'print $2'} | head -n1`
cp /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth0.backup
echo "DEVICE=\"eth0\"
HWADDR=\"$MAC_ADDR\"
USERCTL=\"no\"
TYPE=\"Ethernet\"
BOOTPROTO=\"dhcp\"
ONBOOT=\"yes\"
PEERDNS=\"yes\"
NM_CONTROLLED=\"no\"" > /etc/sysconfig/network-scripts/ifcfg-eth0

systemctl status NetworkManager
systemctl disable NetworkManager
systemctl stop NetworkManager
hostnamectl set-hostname $FQDN

mv /bin/google_set_hostname /tmp/


# ssh key forwarding to connect instance
ssh-agent bash
ssh-add <private-key>
ssh-add -L

ssh -A username@hostIP


# configre /etc/hosts file and reboot the machine manually once script has successfully ran
sudo vi /etc/hosts

10.112.90.3 cdh01.nxtbigthing.com c1
10.112.90.4 cdh02.nxtbigthing.com c2
10.112.90.5 cdh03.nxtbigthing.com c3

# Download CM repo file
yum install wget -y

wget -nv http://archive.cloudera.com/cm5/redhat/6/x86_64/cm/cloudera-manager.repo -O /etc/yum.repos.d/cloudera-manager.repo

vi /etc/yum.repos.d/cloudera-manager.repo
baseurl=https://archive.cloudera.com/cm5/redhat/6/x86_64/cm/baseurl=https://archive.cloudera.com/cm5/redhat/6/x86_64/cm/5.14.0

# Download Installer bin
wget http://archive.cloudera.com/cm5/installer/5.14.0/cloudera-manager-installer.bin

# Run the Installer
chmod +x cloudera-manager-installer.bin
./cloudera-manager-installer.bin --i-agree-to-all-licenses --noprompt --noreadme --nooptions

# Configure External DB for Cloudera Manager
cat /etc/cloudera-scm-server/db.properties

# Download MySQL repository
wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
rpm -ivh mysql-community-release-el7-5.noarch.rpm
yum update -y

yum -y install mysql-server mysql-connector-java
systemctl enable mysqld
systemctl start mysqld

# check mysql version
mysql -V

# secure mysql database with password and allow remote login
/usr/bin/mysql_secure_installation

--Disallow root login remotely? [Y/n] n


#validate cloudeara database
cat /etc/cloudera-scm-server/db.properties


# create database for cloudera
mysql -uroot -p
create user 'cloudera'@'%' identified by 'cloudera' ;
grant all on *.* to 'cloudera'@'%' with grant option ;
flush privileges ;
exit ;


# run the cloudera database init script for mysql
/usr/share/cmf/schema/scm_prepare_database.sh mysql -h fgdataservicecdh01.fossilgroup.com -ucloudera -pcloudera \
--scm-host fgdataservicecdh01.fossilgroup.com scm_db scm_user scm_pass

# restart cloudera server and verify database properties for cloudera
service cloudera-scm-server restart

cat /etc/cloudera-scm-server/db.properties

# install mysql connector
yum -y install mysql-connector-java


create database hive default character set utf8 ;
create user 'hive'@'%' identified by 'hive' ;
grant all on hive.* to 'hive'@'%' ;

create database rman default character set utf8 ;
create user 'rman'@'%' identified by 'rman' ;
grant all on rman.* to 'rman'@'%' ;

create database oozie default character set utf8 ;
create user 'oozie'@'%' identified by 'oozie' ;
grant all on oozie.* to 'oozie'@'%' ;

create database hue default character set utf8 ;
create user 'hue'@'%' identified by 'hue' ;
grant all on hue.* to 'hue'@'%' ;



====================================================
yarn.nodemanager.checker.utilization

sudo ln -sfn /usr/java/jdk1.7.0_67-cloudera/bin/java /etc/alternatives/java

sudo ln -sfn /usr/java/jdk1.7.0_67-cloudera/bin/java /usr/bin/java


#move the connector jar file to appropriate hosts depending upon metastore services
/usr/share/java/mysql-connector-java-5.1.17.jar
scp /usr/share/java/mysql-connector-java-5.1.17.jar n1:/tmp

#login to node
sudo mkdir -p /usr/share/java
sudo mv /tmp/mysql-connector-java-5.1.17.jar /usr/share/java


yum -y install mysql-connector-java



-------------------
# jdk installation script
---------------
#!/bin/bash

#########################################################################################################
# Hadoop Prerequisite for CDH cluster and JDK Installation Script
# Changes Needed:
#  - Change FQDN value to desired domain name
#  - Edit rpm link with latest jdk --> https://www.oracle.com/technetwork/java/jdk8-downloads-2133151.html
#
# Author: Shehzad Shaikh
#
#
############################################################################################################

# Edit FQDN value to desired domain name
# Edit JAVA_LINK with latest jdk --> https://www.oracle.com/technetwork/java/jdk8-downloads-2133151.html

JAVA_LINK=https://download.oracle.com/otn-pub/java/jdk/8u201-b09/42970487e3af4f5aa5bca3f542482c60/jdk-8u201-linux-x64.rpm

FQDN=corecdh01.nxtbigthing.com

# verify if script already executed
if [[ `hostname` == "${FQDN}" ]]
then
  echo "Startup script has successfully executed"
  exit 0
else
 echo `hostname`
 echo "Startup script is initiated..."
fi

# ------------------------------- Prerequisites for HADOOP  ----------------------------------

sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
setenforce 0
echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.local
echo "echo never > /sys/kernel/mm/transparent_hugepage/defrag" >> /etc/rc.local
source /etc/rc.local
yum -y install ntp
systemctl enable ntpd
systemctl restart ntpd
systemctl enable chronyd
systemctl restart chronyd
systemctl disable firewalld
systemctl stop firewalld
echo "vm.swappiness = 0" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6 = 1 " >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p

# ------------------------------- CONFIGURE HOSTNAME ------------------------------------

echo "HOSTNAME=$FQDN
NETWORKING_IPV6=False
NETWORKING=yes
NOZEROCONF=yes" > /etc/sysconfig/network

# disable ipv6
echo "net.ipv6.conf.all.disable_ipv6 = 1 " >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p
MAC_ADDR=`ip a | grep -i link/ether | awk {'print $2'} | head -n1`
cp /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth0.backup
echo "DEVICE=\"eth0\"
HWADDR=\"$MAC_ADDR\"
USERCTL=\"no\"
TYPE=\"Ethernet\"
BOOTPROTO=\"dhcp\"
ONBOOT=\"yes\"
PEERDNS=\"yes\"
NM_CONTROLLED=\"no\"" > /etc/sysconfig/network-scripts/ifcfg-eth0

systemctl status NetworkManager
systemctl disable NetworkManager
systemctl stop NetworkManager
hostnamectl set-hostname $FQDN

mv /bin/google_set_hostname /tmp/

# ----------------------------- ORACLE JDK 1.8 Installation ----------------------------

# truncate the output file
> /tmp/jdkInstall.output > /dev/null 2>&1

# validate if java already installed
/usr/bin/which java > /dev/null 2>&1

if [[ "${?}" -eq 0 ]]
then
       echo "JDK is already installed" >> /tmp/jdkInstall.output
       exit 0
else
     echo "Validating wget installation!" >> /tmp/jdkInstall.output
     /usr/bin/which wget > /dev/null 2>&1
     if [[ "${?}" -ne 0 ]]
     then
        echo 'wget not found attempting to install...' >> /tmp/jdkInstall.output
       /bin/yum update -y > /dev/null 2>&1 && /bin/yum install wget -y > /dev/null 2>&1
     fi

     # validate wget
     /usr/bin/which wget > /dev/null 2>&1

     if [[ "${?}" -ne 0 ]]
     then
        echo "/bin/yum update -y && /bin/yum install wget -y command failed with error code: ${?}"
     else
        DIR=/opt/downloads

       if [ ! -d "${DIR}" ]; then
          echo "Creating Download directory: ${DIR}" >> /tmp/jdkInstall.output
          mkdir -p "${DIR}"
       fi
     fi

     echo "Downloading JDK at ${DIR} location..." >> /tmp/jdkInstall.output
     /bin/wget -O $DIR/oracle-jdk-1-8.rpm -N \
     --no-check-certificate \
     --no-cookies \
     --header "Cookie: oraclelicense=accept-securebackup-cookie" \
     $JAVA_LINK > /dev/null 2>&1

     if [[ "${?}" -ne 0 ]]
     then
             echo 'JDK Download failed! Please Correct the Download Link. ' >> /tmp/jdkInstall.output
             exit 1
     fi

     echo "Installing JDK..." >> /tmp/jdkInstall.output
     /bin/yum -y localinstall $DIR/oracle-jdk-1-8.rpm > /dev/null 2>&1
     update-alternatives --install /usr/bin/java java /usr/java/jdk1.8.0_181-amd64/jre/bin/java 1
     update-alternatives --install /usr/bin/jar jar /usr/java/jdk1.8.0_181-amd64/bin/jar 1
     update-alternatives --install /usr/bin/javac javac /usr/java/jdk1.8.0_181-amd64/bin/javac 1
     update-alternatives --install /usr/bin/javaws javaws /usr/java/jdk1.8.0_181-amd64/jre/bin/javaws 1

     echo "ORACLE JDK 1.8 has been successfully installed!" >> /tmp/jdkInstall.output
fi
exit 0



--------------------------
# install cloudera manager
----------------------------
