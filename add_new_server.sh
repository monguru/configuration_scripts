#!/bin/bash -e

export LC_ALL="C"

if [ ! `whoami` == "root" ];then
    echo "You must run this as root."
    echo "Try running curl -sL curl -sL https://raw.github.com/monguru/configuration_scripts/master/add_new_server.sh | sudo bash -e"
    exit 1
fi

echo "-Instaling snmp daemon from apt repository... "
apt-get update > /dev/null
apt-get install -y snmpd > /dev/null

echo -n "-Generating random snmp login..."
theusername=`head -c 1200 /dev/urandom | md5sum | head -c 16`
echo "done."
echo -n "-Generating random snmp password..."
thepassword=`head -c 1200 /dev/urandom | md5sum | head -c 16`
echo "done."

/etc/init.d/snmpd stop

echo -n "-Backingup your snmpd configuration file..."
test -e /etc/snmp/snmpd.conf && mv /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.monguru.backup-`date +%s`
echo "done."

echo -n "-Downloading new configuration file for snmpd..."
wget -q -O - https://raw.github.com/monguru/configuration_scripts/master/snmpd.conf | sed -e "s/\[%REPLACE_ME%\]/${theusername}/g" > /etc/snmp/snmpd.conf
echo "done."

echo -n "-Setting new snmp login/password..."
echo "createUser $theusername SHA1 \"$thepassword\" AES
rouser $theusername" >> /var/lib/snmp/snmpd.conf
echo "done."

/etc/init.d/snmpd start


echo -n "-Downloading and unpacking monguru script to detect services..."
cd /tmp
test -f monguru_add_server.tar.gz && rm -f monguru_add_server.tar.gz 
test -d /tmp/monguru && rm -rf /tmp/monguru
wget -q https://raw.github.com/monguru/configuration_scripts/master/monguru_add_server.tar.gz
tar zxf monguru_add_server.tar.gz
echo "done."
/tmp/monguru/monguru_add_server.py ${theusername} ${thepassword}
rm -fr monguru_add_server.tar.gz /tmp/monguru
cd - > /dev/null
