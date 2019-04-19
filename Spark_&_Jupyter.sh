##########################################################################
# SPARK DEVELOPMENT & ADMINISTRATION
#
# Following Installation of componenet have been carried out on Ubunutu OS
# 
#  - Spark Installation & basic configuration
#  - Jupyter Installation & Secure mode configuration
#
#
###########################################################################


Download and Install Spark
--------------------------
# update the repository
sudo apt-get update -y

# installing pip 3
sudo apt-get install python3-pip -y

# install jupyter
pip3 install jupyter

# install open jdk
sudo apt-get install default-jre -y
java -version

# install scala code runnder
sudo apt-get install scala -y
scala -version

# install py4j
pip3 install py4j

# download and configure spark
wget https://www.apache.org/dist/spark/spark-2.3.3/spark-2.3.3-bin-hadoop2.7.tgz
sudo tar -zxvf spark-2.3.3-bin-hadoop2.7.tgz
sudo mkdir -p /usr/local/spark/ && sudo chown `whoami`:`id -gn` /usr/local/spark
sudo mv spark-2.3.3-bin-hadoop2.7 /usr/local/spark/
ln -s /usr/local/spark/spark-2.3.3-bin-hadoop2.7 /usr/local/spark/current

# update bash profile for spark / .bashrc
vi ~/.bashrc
export SPARK_HOME=/usr/local/spark/current
export PATH=$PATH:$SPARK_HOME/bin

source  ~/.bashrc

# install findspark
pip3 install findspark

# configure jupyter
jupyter notebook --generate-config

# creating certificate
mkdir certs && cd certs

sudo openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout jupyter.pem -out jupyter.pem

# change jupyter notebook configs
vi /home/shehzad/.jupyter/jupyter_notebook_config.py

c = get_config()
c.NotebookApp.certfile = u'/home/shehzad/certs/jupyter.pem'
c.NotebookApp.ip = '0.0.0.0'
c.NotebookApp.open_browser = False
c.NotebookApp.port = 8888


# start the jupyter notebook
jupyter notebook

jupyter notebook 2>/dev/null

nohup jupyter notebook 2>/dev/null &

# running jupyter notebook withough config files
jupyter notebook --ip='0.0.0.0' --certfile='/home/shehzad/certs/jupyter.pem'


# goto python editor on jupyter
-------------------------------
# import pyspark module
import findspark
findspar.ini('/usr/local/spark/current/')

import pyspark
