# !/bin/bash

# ulimit 内核限制
ulimit -c unlimited
ulimit -d unlimited
ulimit -f unlimited
ulimit -i unlimited
ulimit -n 999999
ulimit -q unlimited
ulimit -u unlimited
ulimit -v unlimited
ulimit -x unlimited
ulimit -s 240
ulimit -l unlimited

# Update CentOS
echo "Updating CentOS"
yum -y update && yum -y upgrade

# Add additional repository
yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum install -y freeswitch-release-repo-0-1.noarch.rpm epel-release
echo "oakhole" >/etc/yum/vars/signalwireusername
echo "pat_QAQRREtCTSA4vhanF15Rn3t7" >/etc/yum/vars/signalwiretoken

# Installing dependencies
yum -y install git ntp yum-utils net-tools epel-release htop vim openssl memcached curl gdb

#get the install script
git clone https://ghfast.top/https://github.com/fusionpbx/fusionpbx-install.sh.git

#change the working directory
cd ./fusionpbx-install.sh/centos

# Disable SELinux
resources/selinux.sh

#FreeSWITCH
#send a message
echo "Installing FreeSWITCH"

#install freeswitch packages
yum install -y freeswitch-config-vanilla freeswitch-lang-* freeswitch-lua freeswitch-xml-cdr

#update the permissions
chown -R freeswitch.daemon /etc/freeswitch /var/lib/freeswitch /var/log/freeswitch /usr/share/freeswitch /var/www/fusionpbx
find /etc/freeswitch -type d -exec chmod 770 {} \;
find /var/lib/freeswitch -type d -exec chmod 770 {} \;
find /var/log/freeswitch -type d -exec chmod 770 {} \;
find /usr/share/freeswitch -type d -exec chmod 770 {} \;
find /etc/freeswitch -type f -exec chmod 664 {} \;
find /var/lib/freeswitch -type f -exec chmod 664 {} \;
find /var/log/freeswitch -type f -exec chmod 664 {} \;
find /usr/share/freeswitch -type f -exec chmod 664 {} \;

#restart services
echo "Restarting packages for final configuration"
systemctl daemon-reload
systemctl enable freeswitch
systemctl restart freeswitch

#send a message
echo "FreeSWITCH installed"

#install sngrep
resources/sngrep.sh
