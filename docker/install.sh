#!/bin/bash

# Enable strict error handling:
# -e: Exit immediately if any command exits with a non-zero status
# -u: Exit if an undefined variable is referenced
set -euo

# 设置系统ulimit参数
ulimit -c unlimited -d unlimited -f unlimited -i unlimited -n 999999 -q unlimited -u unlimited -v unlimited -x unlimited -s 240 -l unlimited

# 关闭selinux及防火墙
setenforce 0 && systemctl stop firewalld && systemctl disable firewalld

# 配置阿里云yum源及signalwire freeswitch源
rm -rf /etc/yum.repos.d/* && \
    curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo \
    && curl -o /etc/yum.repos.d/epel-7.repo https://mirrors.aliyun.com/repo/epel-7.repo \
    && echo "oakhole" >/etc/yum/vars/signalwireusername && echo "pat_QAQRREtCTSA4vhanF15Rn3t7" >/etc/yum/vars/signalwiretoken \
    && yum install -y https://$(</etc/yum/vars/signalwireusername):$(</etc/yum/vars/signalwiretoken)@freeswitch.signalwire.com/repo/yum/centos-release/freeswitch-release-repo-0-1.noarch.rpm epel-release \
    && yum clean all && yum makecache

# freeswitch runime dependencies
yum install -y ldns libsndfile opus libks2 ntpdate && ntpdate cn.pool.ntp.org

# 下载并解压编译好的freeswitch及其依赖库
curl -o /fs.tgz http://t9h8k8i48.hd-bkt.clouddn.com/fs.tgz && cd / \
&& tar zxvf fs.tgz && rm -rf fs.tgz \
&& tar xvf libs.tar && rm -rf libs.tar

# 创建freeswitch用户和用户组
groupadd -g 499 freeswitch \
    && useradd -u 499 -g freeswitch freeswitch

# freeswitch 加载systemd服务开机自启
systemctl daemon-reload && systemctl start freeswitch && systemctl enable freeswitch

# fs_cli 查询当前状态
fs_cli -x "status"
