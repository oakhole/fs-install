# !/bin/bash

#   ┌──────────────────────────────────────────────────────────────────────────┐
#   │ fs install with mod_av support by ffmpeg                                 │
#   │ FreeSWITCH 1.10.10                                                       │
#   │ CentOS 7.6                                                               │
#   │ ffmpeg 5.1.3                                                             │
#   └──────────────────────────────────────────────────────────────────────────┘

# ---------------------------------- 系统环境准备 ---------------------------------- #
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

# ------------------------- 1. 安装 FreeSwitch 依赖 rpm 包 ------------------------ #
echo "oakhole" >/etc/yum/vars/signalwireusername
echo "pat_QAQRREtCTSA4vhanF15Rn3t7" >/etc/yum/vars/signalwiretoken
yum install -y https://$(</etc/yum/vars/signalwireusername):$(</etc/yum/vars/signalwiretoken)@freeswitch.signalwire.com/repo/yum/centos-release/freeswitch-release-repo-0-1.noarch.rpm epel-release

# ------------------------ 2. 安装 devtoolset-9，解决依赖找不到的问题 ------------------------ #
cd /usr/local/src
yum -y --downloadonly --downloaddir=./gccupdate install centos-release-scl
cd gccupdate
rpm -ivh ./*
yum -y --downloadonly --downloaddir=./gcc9 install devtoolset-9
cd gcc9
rpm -Uvh ./*
scl enable devtoolset-9 'bash'

# ------------------------------ 3. 安装freeswitch 依赖 ----------------------------- #
yum-builddep -y freeswitch --skip-broken
yum install -y yum-plugin-ovl centos-release-scl rpmdevtools yum-utils git

# ----------------------------- 4. 安装 spandsp，解决依赖冲突 ---------------------------- #
yum remove -y spandsp-devel-1.99.0-15.a6266f2259.x86_64
yum install -y spandsp3.x86_64 spandsp3-devel.x86_64

# ---------------------------- 5. 安装 devtoolset-4-gcc --------------------------- #
wget -O /etc/yum.repos.d/devtoolset-4.repo https://copr.fedoraproject.org/coprs/hhorak/devtoolset-4-rebuild-bootstrap/repo/epel-7/hhorak-devtoolset-4-rebuild-bootstrap-epel-7.repo --no-check-certificate
yum update -y
yum install -y devtoolset-4-gcc*
scl enable devtoolset-4 'bash'

# --------------------------------- 6. 编译安装 x264 -------------------------------- #
cd /usr/local/src
git clone https://ghproxy.com/https://github.com/mirror/x264.git
cd x264
./configure --prefix=/usr/local/x264 --enable-shared --enable-static --disable-asm
make && make install
echo 'export PKG_CONFIG_PATH=/usr/local/x264/lib/pkgconfig' >>/etc/profile
source /etc/profile
echo "/usr/local/x264/lib" >>/etc/ld.so.conf
ldconfig

# --------------------------------- 7. 安装 ffmpeg -------------------------------- #
cd /usr/local/src
wget -O ffmpeg-5.1.3.tar.gz https://ffmpeg.org/releases/ffmpeg-5.1.3.tar.gz
tar zxvf ffmpeg-5.1.3.tar.gz
mv ffmpeg-5.1.3 ffmpeg
cd ffmpeg
./configure --prefix=/usr/local/ffmpeg --enable-openssl --enable-shared --disable-static --enable-libx264 --enable-gpl --enable-version3 --enable-nonfree --enable-libopus --enable-libtheora --enable-libvorbis --enable-encoder=libx264 --enable-encoder=libx264rgb --enable-encoder=bmp --enable-encoder=png --enable-encoder=ljpeg --enable-decoder=h264 --enable-libmp3lame
# ./configure --prefix=/usr/local/ffmpeg --enable-shared --enable-pthreads --enable-gpl --enable-version3 --enable-hardcoded-tables --enable-avresample --cc=clang --host-cflags= --host-ldflags= --enable-libx264 --enable-libmp3lame --enable-libvo-aacenc --enable-libxvid --enable-libvorbis --enable-libvpx --enable-libfaac --enable-libspeex --enable-libx265 --enable-nonfree --enable-vda
make && make install
echo "export PATH=$PATH:/usr/local/ffmpeg/bin" >>/etc/profile
source /etc/profile
echo "/usr/local/ffmpeg/lib" >>/etc/ld.so.conf
ldconfig

# ----------------------------------- 8. freeswitch 源码编译安装 ----------------------------------- #
cd /usr/local/src
wget -O freeswitch-1.10.10.tar.gz https://ghproxy.com/https://github.com/signalwire/freeswitch/archive/refs/tags/v1.10.10.tar.gz
tar zxvf freeswitch-1.10.10.tar.gz
mv freeswitch-1.10.10 freeswitch
cd freeswitch
./bootstrap.sh -j
./configure --enable-portable-binary --prefix=/usr --localstatedir=/var --sysconfdir=/etc --with-gnu-ld --with-python --with-erlang --with-openssl --enable-core-odbc-support

# 更改 mod_av 编译文件
echo 'AV=/usr/local/ffmpeg' >/usr/local/src/freeswitch/src/mod/applications/mod_av/Makefile
echo 'LOCAL_CFLAGS=-I$(AV)/include' >>/usr/local/src/freeswitch/src/mod/applications/mod_av/Makefile
echo 'LOCAL_LDFLAGS=-L$(AV)/lib -lavcodec -lavformat -lavutil -lswscale' >>/usr/local/src/freeswitch/src/mod/applications/mod_av/Makefile
echo 'LOCAL_OBJS=avcodec.o avformat.o' >>/usr/local/src/freeswitch/src/mod/applications/mod_av/Makefile
echo 'include ../../../../build/modmake.rules' >>/usr/local/src/freeswitch/src/mod/applications/mod_av/Makefile

make
make -j install
make -j cd-sounds-install
make -j cd-moh-install

# ---------------------------- 9. 变更 freeswitch 默认配置 ---------------------------- #
rm -rf /etc/freeswitch/sip_profiles/external-ipv6 /etc/freeswitch/sip_profiles/external-ipv6.xml /etc/freeswitch/sip_profiles/internal-ipv6.xml
# 更改 vars.xml 默认密码

# ---------------------------- 安装 sip 抓包工具 sngrep ---------------------------- #
IRONTEC="[irontec]
name=Irontec RPMs repository
baseurl=http://packages.irontec.com/centos/\$releasever/\$basearch/"
echo "${IRONTEC}" >/etc/yum.repos.d/irontec.repo
rpm --import http://packages.irontec.com/public.key
yum -y install sngrep
