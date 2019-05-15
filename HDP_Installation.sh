# =======================================================================
# HDP Installation on GCP
# for HUE and Solr - https://docs.hortonworks.com/HDPDocuments/Ambari-2.6.2.2/bk_ambari-installation/content/choose_services.html
#
# =======================================================================

# startup script for rhel/cento6
#-------------------------------

#! /bin/bash
sed -i "s/localhost/$(hostname -f)/" /etc/sysconfig/network
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
echo "vm.swappiness = 0" >> /etc/sysctl.conf
sysctl -p
echo "echo never > /sys/kernel/mm/redhat_transparent_hugepage/enabled" >> /etc/rc.local
echo "echo never > /sys/kernel/mm/redhat_transparent_hugepage/defrag" >> /etc/rc.local
source /etc/rc.local
yum -y install ntp
chkconfig ntpd on
service ntpd restart
chkconfig iptables off
chkconfig ip6tables off

# startup script for rhel/centos7
#-------------------------------

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



# Necessary packages required on hosts
# RHEL/CentOS/Oracle Linux
yum and rpm
scp, curl, unzip, tar, and wget
OpenSSL and Python 2.7.x

# install python 2.7.x
yum install gcc openssl-devel bzip2-devel -y
cd /usr/src
wget https://www.python.org/ftp/python/2.7.15/Python-2.7.15.tgz
tar xzf Python-2.7.15.tgz
cd Python-2.7.15
./configure --enable-optimizations
make altinstall
/usr/local/bin/python2.7 -V

# Configure ​Maximum Open Files Requirements
ulimit -Sn
ulimit -Hn

ulimit -n 10000

# download the ambari repo file
wget http://public-repo-1.hortonworks.com/ambari/centos6/2.x/updates/2.6.2.2/ambari.repo -O /etc/yum.repo.d/ambari.repo

# validate ambari packages
yum repolist
yum list all | grep ambari

# Install the Ambari server
--------------------------
yum install ambari-server


# ​Using Ambari with MySQL/MariaDB
--------------------------------
yum install mysql-server -y
yum install mysql-connector-java -y

# Confirm that .jar is in the Java share directory.
ls /usr/share/java/mysql-connector-java.jar

# On the Ambari Server host run
ambari-server setup --jdbc-db=mysql --jdbc-driver=/usr/share/java/mysql-connector-java.jar

# start mysql server
service mysqld start
chkconfig mysqld on

# secure mysql server
/usr/bin/mysql_secure_installation

# Create a user for Ambari and grant permissions
mysql -u root -p
CREATE USER 'ambari'@'%' IDENTIFIED BY 'ambari';
GRANT ALL PRIVILEGES ON *.* TO 'ambari'@'%';

CREATE USER 'ambari'@'localhost' IDENTIFIED BY 'ambari';
GRANT ALL PRIVILEGES ON *.* TO 'ambari'@'localhost';

CREATE USER 'ambari'@'hdp01.asia-east2-a.c.kafkaprojects.internal' IDENTIFIED BY 'ambari';
GRANT ALL PRIVILEGES ON *.* TO 'ambari'@'hdp01.asia-east2-a.c.kafkaprojects.internal';

FLUSH PRIVILEGES;

# Load the Ambari Server database schema.
cd /var/lib/ambari-server/resources/
mysql -uambari -pambari
CREATE DATABASE ambari;
USE ambari;
SOURCE Ambari-DDL-MySQL-CREATE.sql;


# Set Up the Ambari Server
--------------------------
ambari-server setup

# select Advanced Database Configuration > Option [3] MySQL/MariaDB and enter the credentials defined for ambari db


# ​Start the Ambari Server
------------------------
ambari-server start
ambari-server status

# Log In to Apache Ambari
# default user name/password: admin/admin
http://<ambari.server.ip>:8080

# follow - https://docs.hortonworks.com/HDPDocuments/Ambari-2.6.2.2/bk_ambari-installation/content/launching_the_ambari_install_wizard.html


#Gone through same issue only when we are using oVirt Virtualization For our cluster deployment.
#Only following solution resolved the problem (Thanks to @bing lv and @Deven Fan:
#By adding below config in [security] section of
https://community.hortonworks.com/questions/145/openssl-error-upon-host-registration.html

vi /etc/ambari-agent/conf/ambari-agent.ini
force_https_protocol=PROTOCOL_TLSv1_2

vi /etc/python/cert-verification.cfg
[https]
verify=disable

============================================================================
# Enable Namenode and Resourcemanager HA
#
###########################################################









============================================================================
# Ambari RestAPI
# https://github.com/apache/ambari/blob/trunk/ambari-server/docs/api/v1/index.md
# https://github.com/HariSekhon/devops-python-tools
#
##########################################################

# Authentication
USERNAME=admin
PASSWD=admin

curl --user $USERNAME:$PASSWD http://hdp01:8080/api/v1/clusters

# Get the DATANODE component resource for the HDFS service of the cluster
GET /clusters/<cluster_name>/services/HDFS/components/DATANODE

curl -s --user $USERNAME:$PASSWD -X GET http://hdp01:8080/api/v1/clusters/NXTBIGTHING_PROD/services/HDFS/components/DATANODE

# -s/--silent
# Silent or quiet mode. Don’t show progress meter or error messages.  Makes Curl mute.

# curl -vs -o /dev/null http://somehost/somepage 2>&1
# That will suppress the progress meter, send stdout to /dev/null and redirect stderr (the -v output) to stdout.

# pull the name list of all datanodes
curl -s --user $USERNAME:$PASSWD -X GET http://hdp01:8080/api/v1/clusters/NXTBIGTHING_PROD/services/HDFS/components/DATANODE | grep -i 'host_name' | awk {'print $3'} | sed 's/"//g'


# to pull name of services in the cluster
/clusters/<cluster_name>

curl --user $USERNAME:$PASSWD http://hdp01:8080/api/v1/clusters/NXTBIGTHING_PROD/services

# Partial Response to restrict response to a specific field
GET    /api/v1/clusters/c1/services/HDFS/components/NAMENODE?fields=metrics/disk/disk_total

curl -s --user $USERNAME:$PASSWD -X GET http://hdp01:8080/api/v1/clusters/NXTBIGTHING_PROD/services/HDFS/components/DATANODE?fields=host_components/HostRoles/component_name/host_name


#################################
# Ambari API - Run all service checks (bulk)
# https://community.hortonworks.com/articles/11852/ambari-api-run-all-service-checks-bulk.html
# https://gist.github.com/mr-jstraub/0b55de318eeae6695c3f#payload-to-run-all-service-checks
#

# create payload file
vi payload
{
   "RequestInfo":{
      "context":"HDFS Service Check",
      "command":"HDFS_SERVICE_CHECK"
   },
   "Requests/resource_filters":[
      {
         "service_name":"HDFS"
      }
   ]
}

# run command to for HDFS service check
curl -ivk -H "X-Requested-By: ambari" -u admin:admin -X POST -d @payload http://hdp01:8080/api/v1/clusters/NXTBIGTHING_PROD/requests
