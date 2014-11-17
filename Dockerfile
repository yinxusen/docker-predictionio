FROM ubuntu:14.04
 
ENV http_proxy http://10.240.252.16:911
ENV https_proxy https://10.240.252.16:911
ENV no_proxy 172.16.124.180

RUN echo "Acquire::http::proxy \"http://10.240.252.16:911\";" >> /etc/apt/apt.conf
RUN echo "Acquire::https::proxy \"https://10.240.252.16:911\";" >> /etc/apt/apt.conf

#RUN echo "deb mirror://mirrors.ubuntu.com/mirrors.txt precise main restricted universe multiverse" > /etc/apt/sources.list
#RUN echo "deb mirror://mirrors.ubuntu.com/mirrors.txt precise-updates main restricted universe multiverse" >> /etc/apt/sources.list
#RUN echo "deb mirror://mirrors.ubuntu.com/mirrors.txt precise-backports main restricted universe multiverse" >> /etc/apt/sources.list
#RUN echo "deb mirror://mirrors.ubuntu.com/mirrors.txt precise-security main restricted universe multiverse" >> /etc/apt/sources.list

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -y
RUN apt-get clean all

#Runit
RUN apt-get install -y runit
CMD /usr/sbin/runsvdir-start

#SSHD
RUN apt-get install -y openssh-server && \
    mkdir -p /var/run/sshd && \
    echo 'root:root' |chpasswd
RUN sed -i "s/session.*required.*pam_loginuid.so/#session    required     pam_loginuid.so/" /etc/pam.d/sshd
RUN sed -i "s/PermitRootLogin without-password/#PermitRootLogin without-password/" /etc/ssh/sshd_config

#Utilities
RUN apt-get install -y vim less net-tools inetutils-ping curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common

#Install Oracle Java 7
RUN add-apt-repository ppa:webupd8team/java -y && \
    apt-get update && \
    echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y oracle-java7-installer
ENV JAVA_HOME /usr/lib/jvm/java-7-oracle

# Here I open a simple http server with Python to serve my own jar files request, to prevent the network failure due to INTRANET.

#PredictionIO
RUN curl http://172.16.124.180:8000/PredictionIO-0.8.0.tar.gz | tar zx
RUN mv PredictionIO* PredictionIO

#Spark
RUN curl http://172.16.124.180:8000/spark-1.1.0-bin-hadoop2.4.tgz | tar zx
RUN mv spark* spark
RUN sed -i 's|SPARK_HOME=/path_to_apache_spark|SPARK_HOME=/spark|' /PredictionIO/conf/pio-env.sh

#ElasticSearch
RUN curl http://172.16.124.180:8000/elasticsearch-1.3.2.tar.gz | tar zx
RUN mv elasticsearch* elasticsearch

#HBase
RUN curl http://172.16.124.180:8000/hbase-0.98.6-hadoop2-bin.tar.gz | tar zx
RUN mv hbase* hbase
RUN echo "export JAVA_HOME=/usr/lib/jvm/java-7-oracle" >> /hbase/conf/hbase-env.sh

RUN apt-get update

#Python SDK
RUN apt-get install -y python-pip
RUN pip install pytz
RUN pip install predictionio

#Add runit services
ADD sv /etc/service 

#Quickstart App
ADD quickstartapp quickstartapp

ENV PIO_HOME /PredictionIO
