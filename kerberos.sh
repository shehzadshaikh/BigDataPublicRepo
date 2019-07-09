

####################################################################
# Kerberos Authentication in Cloudera Manager
# https://www.cloudera.com/documentation/enterprise/5-11-x/topics/cm_sg_intro_kerb.html
# http://web.mit.edu/Kerberos/
# http://web.mit.edu/Kerberos/krb5-1.8/
# https://kylo.readthedocs.io/en/v0.8.2/installation/KerberosInstallationExample-Cloudera.html
####################################################################


# Cloudera Manager clusters can be integrated with MIT Kerberos or with Microsoft Active Directory:
# Administrative access is needed to access the Active Directory KDC, create principals, and troubleshoot Kerberos TGT/TGS-ticket-renewal and other issues.


# Following Active Directory Setup is not required for Production Cluster Setup
# Configure Active Directory
---------------------------
# 1) Password for Admin user
Goto --> Compute Engine --> VM Instaces --> OS -> 'Windows Server 2012 Desktop Experience'

# Set password for Windows Server
hPxEh$zbZgG]/#H

# Change the Administrator password
Start -> Computer Management -> Local Users and Groups
Administrator -> right click -> Set Password
Pass: Windows1

# repeat same for your own user (if you want to)

# Connect to Windows Server with RDP client

# 2) Setting up AD DS
Goto --> Server Manager --> Add roles and features
--> Before You Begin (default) -> Click Next
--> Installation Type (select Role-based.....) -> Click Next
--> Server Selection (Select a server from the server pool) -> Click Next
--> Server Role - click on 'Active Directory Domain Services' -> Add Feature -> Next

# Once installation completed promote the server as domain controller
Under 'Active Directory Domain Services Configuration Wizard'
 -> Deployment Configuration -
 - Add a new forest
 - Root domain name: bigdata.com

 -> Domain Controller Options -
  - Password: 		  	********
 	- Confirm Passowrd:	********

 -> Rest option default

 # complete the installation and restart the server

# 3) AD CS Secure communication (requires Administrator user login)
Plain-text ldap:// 389
Encrypted ldaps:// 636


# verify connection
Start -> search for 'LDP'

Goto Connections -> Connect...
Server: windows-server
Port: 389

# try connection on 636 (it should fail)

# setup certificate services
Goto --> Server Manager --> Add roles and features
--> Before You Begin (default) -> Click Next
--> Installation Type (select Role-based.....) -> Click Next
--> Server Selection (Select a server from the server pool) -> Click Next
--> Server Role - click on 'Active Directory Certificate Services' -> Add Feature -> Next

# once above is completed
click on 'Configure AD CS on destination server'
Credentials: NXTBIGTHING\Administrator
Role Services: click on 'Certificate Authority'
Setup Type: Enterprise CA
CA Type: Root CA
Private Key: Create a new private key
Cryptography: SHA1
CA NAME: #make note of CN, DN and Preview
Validity Period: 10

CONFIGURE

# CA NAME
Common Name for CA: nxtbigthing-WINDOWS-SERVER-CA
DN suffix: DC=nxtbigthing,DC=com
Preview: CN=nxtbigthing-WINDOWS-SERVER-CA,DC=nxtbigthing,DC=com

# RESTART THE SYSTEM
--------------------

# login and verify ldaps connection
Start -> search for 'LDP'

Goto Connections -> Connect...
Server: windows-server
Port: 636
SSL: True

# validate throug command line
openssl s_client -connect <server-name>:<port>

# In order to make secure connection from unix boxes we need certificate
# to save/download certificate
Start --> Administrative Tools --> Certificate Authority
right click on domain-WINDOWS-SERVER-CA --> Properties --> View Certificate --> Details -> Copy to File...
'Export File Format': Base-64 encoded X.509 (.CER)
'File to Export': C:\Users\Administrator\Desktop\dir01nbt.cer

# Create OU for CDH principle and Cloudera Manager Principle
Goto --> Server Manager --> Tools --> ACTIVE DIRECTORY USERS AND COMPUTERS

# create OU cloudera inside domain
right click on domain name --> NEW -> Organisational Unit -> Cloudera

# create Principle under Cloudera OU
right click on Cloudera -> New -> User -> Cloudera Kerberos
User Logon name: cloudera4krb

# create Cloudera Principle OU under Cloudera
right click on Cloudera (OU) --> NEW -> Organisational Unit -> Cloudera Principles

# delegate controls to create principles
right click on Cloudera Principles -> Delegate Control -> Add -> cloudera4krb
Create, Delete, and Manage User Accounts


# Configure Cluster Hosts
-------------------------
# On the Cloudera Manager Server host
yum -y install openldap-clients krb5-workstation krb5-libs

# On all hosts
yum -y install krb5-workstation, krb5-libs

# configure krb5.conf file on all hosts
# backup the existing krb5.conf
cp /etc/krb5.conf /etc/krbconf_bkup

# truncate the file
> /etc/krb5.conf

# edit the file and paste the below information
vi /etc/krb5.conf
[logging]
 default = FILE:/var/log/krb5libs.log
 kdc = FILE:/var/log/krb5kdc.log
 admin_server = FILE:/var/log/kadmind.log

[libdefaults]
 default_realm = NXTBIGTHING.COM
 dns_lookup_realm = false
 dns_lookup_kdc = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true

default_tgs_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 arcfour-hmac-md5
default_tkt_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 arcfour-hmac-md5
permitted_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 arcfour-hmac-md5

[realms]
 NXTBIGTHING.COM = {
  kdc = dir01.nxtbigthing.com
  admin_server = dir01.nxtbigthing.com
  max_renewable_life = 7d
 }

[domain_realm]
  nxtbigthing.com = NXTBIGTHING.COM
  .nxtbigthing.com = NXTBIGTHING.COM


# configure DNS for AD hosts on all servers
-------------------------------------------
vi /etc/hosts
10.0.0.3 windows.hadoop.com ad


# Install Java Cryptography Extensions (JCE)
---------------------------------------------
sudo yum install -y wget
sudo wget -nv --no-check-certificate --no-cookies --header "Cookie:oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jce/7/UnlimitedJCEPolicyJDK7.zip -O /usr/java/jdk1.7.0_67-cloudera/jre/lib/security/UnlimitedJCEPolicyJDK7.zip

cd /usr/java/jdk1.7.0_67-cloudera/jre/lib/security/

sudo yum install unzip -y
sudo unzip UnlimitedJCEPolicyJDK7.zip

sudo cp UnlimitedJCEPolicy/* .
sudo rm -r UnlimitedJCEPolicy*

ls -l

# Validate Java Cryptography Extension
# Create a java Test.java
vi /tmp/Test.java

import javax.crypto.Cipher;
class Test {
public static void main(String[] args) {
try {
 System.out.println("Hello World!");
 int maxKeyLen = Cipher.getMaxAllowedKeyLength("AES");
 System.out.println(maxKeyLen);
} catch (Exception e){
 System.out.println("Sad world :(");
}
}
}

"# Compile the code
/usr/java/jdk1.7.0_67-cloudera/bin/javac /tmp/Test.java

# Run test, the expected number is: 2147483647
cd /tmp
ls -lrth
/usr/java/jdk1.7.0_67-cloudera/bin/java Test

# Enable Kerberos through Cloudera wizard
------------------------------------------
Goto Cloudera Manager --> Administrator --> Security --> Enable Kerberos
KDC Type: 'Active Directory'
Kerberos Security Realm: 'NXTBIGTHING.COM'
KDC Server Host: 'dir01.nxtbigthing.com'
KDC Admin Server Host: 'dir01.nxtbigthing.com'
Active Directory Suffix: 'OU=Cloudera Principals,OU=Cloudera,DC=nxtbigthing,DC=com'
Kerberos Encryption Types:
  - 'aes256-cts-hmac-sha1-96'
  - 'aes128-cts-hmac-sha1-96'
  - 'arcfour-hmac-md5'

Manage krb5.conf through Cloudera Manager: 'Fale'

Next -> Next -> (troubleshoot for issue if any)

# validate keytab file created for HDFS
# Login to Namenode host
cd /var/run/cloudera-scm-agent/process/131-hdfs-NAMENODE
klist -e -kt hdfs.keytab


# KeyTab Generation
-------------------
# Note: use kadmin if installation is MIT KDC else use ktutil in case of AD
# Create the keytab files, using the ktutil command
add_entry -password -p principal_name -k kvno_number -e encryption_type for each encryption type

ktutil
add_entry -password -p shaikhsh/cdh02.nxtbigthing.com@NXTBIGTHING.COM -k 1 -e aes256-cts-hmac-sha1-96
Password for shaikhsh/cdh02.nxtbigthing.com@NXTBIGTHING.COM:

add_entry -password -p shaikhsh/cdh02.nxtbigthing.com@NXTBIGTHING.COM -k 1 -e aes128-cts-hmac-sha1-96
Password for shaikhsh/cdh02.nxtbigthing.com@NXTBIGTHING.COM:

add_entry -password -p shaikhsh/cdh02.nxtbigthing.com@NXTBIGTHING.COM -k 1 -e arcfour-hmac
Password for shaikhsh/cdh02.nxtbigthing.com@NXTBIGTHING.COM:

# write to a keytab file
wkt /tmp/shaikhsh.keytab
exit

# goto keytab location
cd /tmp
klist -e -kt shaikhsh.keytab

kinit -kt shaikhsh.keytab shaikhsh/cdh02.nxtbigthing.com


# Create the keytab files, using the kadmin command only if using MIT KDC
kadmin.local
addprinc -randkey shaikhsh@cdh02.nxtbigthing.com
xst -norandkey -k /etc/security/shaikhsh.keytab shaikhsh@cdh02.nxtbigthing.com
exit

chown shaikhsh:hadoop  /etc/security/shaikhsh.keytab
chmod 440  /etc/security/shaikhsh.keytab

# Initialize your keytab file using below command.
kinit -kt  /etc/security/shaikhsh.keytab shaikhsh


# Running Job in kerberized cluster with local users who has UID lesser than 1000
find /opt/ -name "*hadoop*example*"
export EXAMPL_JAR=/opt/cloudera/parcels/CDH-5.14.4-1.cdh5.14.4.p0.3/jars/hadoop-mapreduce-examples-2.6.0-cdh5.14.4.jar

# Run hadoop pi job
hadoop jar $EXAMPL_JAR pi 10 10

# job should fail with following error message
main : requested yarn user is hdfs
Requested user hdfs is not whitelisted and has id 995,which is below the minimum allowed 1000

# Set the minimum user id for yarn
Goto Cloudera Manager -> YARN -> search 'min.user.id'
min.user.id = 500

# restart the service and run the job again


# Namenode/HDFS Delegation Token
---------------------------
# https://hortonworks.com/blog/the-role-of-delegation-tokens-in-apache-hadoop-security/
# https://blog.cloudera.com/blog/2017/12/hadoop-delegation-tokens-explained/

- Delegation token is introduced to avoid frequent authentication check against Kerberos (KDC).
- After the initial authentication against Namenode using Keberos, any subsequent authentication can be done without Kerberos service ticket(or TGT).
- Once the client authentication with Kerberos for Namenode is successfull, The client can get a delegation token from Namenode.
- This token has expiration and max issue date. But this can be renewed up to max issue date.
- HDFS NameNode persists the Delegation Tokens to its metadata (aka. fsimage and edit logs)

# run a pi job and look for HDFS_DELEGATION_TOKEN
find /opt/ -name "*hadoop*example*"
export EXAMPL_JAR=/opt/cloudera/parcels/CDH-5.14.4-1.cdh5.14.4.p0.3/jars/hadoop-mapreduce-examples-2.6.0-cdh5.14.4.jar

hadoop jar $EXAMPL_JAR pi 10 10

# ensure you have ticket
klist
kinit shaikhsh

hdfs dfs -ls /

# generate delegation toekn for currently logged in user
hdfs fetchdt --renewer shaikhsh /tmp/shaikhsh.dtoken
export HADOOP_TOKEN_FILE_LOCATION=/tmp/shaikhsh.dtoken

# destroy the ticket cache
kdestroy
klist

# access file system without tgt
hdfs dfs -ls /user


# check if delegation token can be fetched without the initial ticket from kerberos.
unset HADOOP_TOKEN_FILE_LOCATION

hdfs fetchdt --renewer hdfs my.delegation.token



# Enable Kerberos Authentication for HTTP Web-Consoles
------------------------------------------------------
# https://community.hortonworks.com/articles/28537/user-authentication-from-windows-workstation-to-hd.html

# HDFS HTTP Web Consoles
Cloudera Manager --> HDFS --> Configuration
search 'Enable Kerberos Authentication for HTTP Web-Consoles' and set YARN 'True'

# YARN HTTP Web Consoles
Cloudera Manager --> YARN --> Configuration
search 'Enable Kerberos Authentication for HTTP Web-Consoles' and set to 'True'

# When the command finishes, restart all roles of that service


# Enabling SPNEGO as an Authentication Backend for Hue
