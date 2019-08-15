#================================================================================================
# Hive Administration & Development
# https://pivotalhd-210.docs.pivotal.io/doc/2100/webhelp/topics/Hive.html
# Apache Hive Cookbook by Shrey Mehrotra
# Practical Hive: A Guide to Hadoop's Data Warehouse System by Ankur Gupta
# Apache Hive Essentials by Dayong Du
# https://github.com/costin/hadoop-tutorials/blob/master/Sandbox/T03_Data_Processing_with_Hive.md
#=================================================================================================

'Hive Components'
# Hive Metastore
# Hiveserver2

# Hive Metastore
----------------
# The Hive table and database definitions and mapping to the data in HDFS is stored in a metastore. A metastore is a central repository for Hive metadata. A metastore consists of two main components, i) Services to which the client connects and queries the metastore, ii) A backing database to store the metadata

# By default, the metastore service and the Hive service run in the same JVM. Hive needs a database to store metadata. In default mode, it uses an embedded Derby database stored on the local file system.

# Hive Metastore Modes:
# Embedded Metastore (Derby Database) - The embedded mode of Hive has the limitation that only one session can be opened at a time from the same location on a machine as only one embedded Derby database can get lock and access the database files on disk. An Embedded Metastore has a single service and a single JVM that cannot work with multiple nodes at a time.
# Metastore service, Hive Driver, Derby Database runs in a single JVM.

# Local Metastore - External databse on to same server, the metastore service and Hive service still runs in the same JVM. Local means the same environment of the JVM machine as well as the service in the same node. Database used for metastore needs to be JDBC Compliant.

# Remote Metastore - Same as local metastore but running on remote server in a seperate JVMs.

# The Hive service is configured to use a remote metastore by setting "hive.metastore.uris" to metastore server URIs, separated by commas.

'Hive Installation & Configuration'
-----------------------------------
# Ensure JDK 1.7+ is installed on the server
# Make sure that the Hive node has a connection to Hadoop cluster, which means Hive would be installed on any of the Hadoop nodes, or Hadoop configurations are available in the node's class path.

# Download Hive tarball and unpacking
wget https://archive.apache.org/dist/hive/hive-1.1.0/apache-hive-1.1.0-bin.tar.gz
tar -zxf apache-hive-1.1.0-bin.tar.gz
sudo mkdir /usr/local/hive
sudo mv apache-hive-1.1.0-bin /usr/local/hive
sudo ln -s /usr/local/hive/apache-hive-1.1.0-bin /usr/local/hive/current
sudo chown -R centos:centos /usr/local/hive

sudo mkdir /etc/hive
sudo ln -s /usr/local/hive/current/conf /etc/hive/conf
sudo chown -R centos:centos /etc/hive

# Configure the bashrc file (environment variable)
vi ~/.bashrc
export HIVE_HOME=/usr/local/hive/current
export HIVE_CONF_DIR=/etc/hive/conf
export PATH=$PATH:$HIVE_HOME/bin

source ~/.bashrc

# Create the configuration files
cp /etc/hive/conf/hive-env.sh.template /etc/hive/conf/hive-env.sh
cp /etc/hive/conf/hive-default.xml.template /etc/hive/conf/hive-site.xml
cp /etc/hive/conf/hive-exec-log4j.properties.template /etc/hive/conf/hive-exec-log4j.properties
cp /etc/hive/conf/hive-log4j.properties.template /etc/hive/conf/hive-log4j.properties

# Install MySQL server
sudo yum install mysql-server -y
sudo service mysqld start

# Secure the mysql root account password
sudo /usr/bin/mysql_secure_installation

# Download MySQL JDBC connector
wget http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.35.tar.gz
tar -zxvf mysql-connector-java-5.1.35.tar.gz
cp mysql-connector-java-5.1.35/mysql-connector-java-5.1.35-bin.jar /usr/local/hive/current/lib/

# Configure hive-site.xml
vi /etc/hive/conf/hive-site.xml
<property>
    <name>hive.metastore.warehouse.dir</name>
    <value>/user/Hive/warehouse</value>
    <description> The directory relative to fs.default.name where managed tables are stored. </description>
</property>

<property>
    <name>hive.metastore.uris</name>
    <value>thrift://localhost:9083</value>
    <description> The URIs specifying the remote metastore servers to connect to. If there are multiple remote servers, clients connect in a round-robin fashion </description>
</property>

<property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:mysql://localhost:3306/hive?createDatabaseIfNotExist=true</value>
    <description> The JDBC URL of database. </description>
</property>

<property>
    <name>javax.jdo.option.ConnectionDriverName</name>
    <value>com.mysql.jdbc.Driver</value>
    <description> The JDBC driver classname. </description>
</property>
<property>
    <name>javax.jdo.option.ConnectionUserName</name>
    <value>hive</value>
    <description>metastore username to connect with</description>
</property>

<property>
    <name>javax.jdo.option.ConnectionPassword</name>
    <value>hive</value>
    <description>metastore password to connect with</description>
</property>

# Configure Hive log directory ensure sticky bit on directory
sudo mkdir /var/log/hive/
sudo chown -R centos:centos /var/log/hive
chmod 1755 /var/log/hive

vi /etc/hive/conf/hive-log4j.properties
hive.log.dir=/var/log/hive
hive.log.file=hiveserver2.log

# Create Metastore db and initialize schema script
# Hive Metastore script location
/usr/local/hive/current/scripts/metastore/upgrade/

mysql -u root --password="12345" -f -e "DROP DATABASE IF EXISTS hive; CREATE DATABASE IF NOT EXISTS hive;"
mysql -u root --password="12345" -e "GRANT ALL PRIVILEGES ON hive.* TO 'hive'@'%' IDENTIFIED BY 'hive'; FLUSH PRIVILEGES;"
schematool -dbType mysql -initSchema

# Start the Metastore and Hiveserver2
# Hive runs on Hadoop, first start the hdfs and yarn services
hive --service metastore 1>> /tmp/hivemetastore.log 2>> /tmp/hivemetastore.log &
hive --service hiveserver2 1>> /tmp/hiveserver2.log 2>> /tmp/hiveserver2.log &

# Connect Hive with either the hive or beeline command to validate the installation
hive
beeline -u "jdbc:hive2://localhost:10000"

#HIVE hands-on over Cloudera / HDP

 #hive command line interface (interactive mode)
 hive

 hive> show tables ;

 hive> show
 	 > tables ;

 hive> !whoami;

 #sql statement in non-inetractive mode
hive -e "show tables "

#hive commands from file
hive -f myfile.sql

 #interacting with beeline sql client for hive
 beeline -u jdbc:hive2://hiver-server-fqdn:10000/default;
 > create table sample_table (id int);
 > show tables ;
 > drop table sample_table;

#to view beeline specific help not hive
> !help


#HUE beeswax
Query Editor -> Hive


#creating manage tables in hive
hive
> create database db01 ;
> use db01 ;
> create table tab01 (id int) ;
> show tables ;

#to view table columns
> describe tab01 ;

#to view table create statement
> show create table tab01 ;

> describe extended tab01 ;

#to view the table format, owner, location etc
> describe formatted tab01 ;

#creating a file and loading into table tab01
vi tab01.data
23
456
123
num
1136
value
9899

#put the file to hdfs under table location retrived from describe formatted command
hdfs dfs -put tab01.data /user/hive/warehouse/tab01
hdfs dfs -ls /user/hive/warehouse/tab01

#login to hive and run select statement
hive
> select * from db01.tab01 ;

#specify warehouse directory location for database or table ;
hive> create table tab02
    > LOCATION '/data/hive/database/tab02' ;

Metastore Server HA

Hive Configuration -> Scope -> Hive Metastore Server
 Hive Metastore Delegation Token Store -> org.apache.hadoop.hive.thrift.DBTokenStore
 hive.metastore.uris
 #adding hive metastore server services

Hiverserver2 HA
#dynamic service discovery provides load balancing as well high availablity

#add 2 more hiveservers
Goto Hive -> Instances -> Add Role Instances -> Hiverserver2 'select hosts'

#select hiverser and start them

Hive -> Configuration -> Category -> Advance -> "Hiveserver2 Advance Configuration Snippet (Saftey Valve) for hive-site.xml"

Name: hive.server2.support.dynamic.service.discovery
value: true

beeline -u "jdbc:hive2://zk1:2181,zk2:2181,zk2:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiverser2"

# Download dataset
wget https://raw.githubusercontent.com/shehzadshaikh/hadoop-class/master/lahman591-csv.zip
