#!/bin/bash
# FreeSWITCH 1.10.12 Install Script for Ubuntu 22.04
# guiding principle: KISS, Occam's Razor

set -e

# --- 1. 环境准备 ---
sudo apt update
sudo apt install -y git build-essential autoconf automake libtool libtool-bin \
    pkg-config libssl-dev zlib1g-dev libncurses5-dev libncursesw5-dev \
    libjpeg-dev libsqlite3-dev libcurl4-openssl-dev libpcre3-dev \
    libspeex-dev libspeexdsp-dev libldns-dev libedit-dev \
    libpq-dev libopus-dev cmake uuid-dev libsndfile1-dev \
    libshout3-dev libmpg123-dev libmp3lame-dev \
    libtiff-dev nasm uuid-dev lua5.3 liblua5.3-dev lua-json lua-socket lua-sec

# --- 2. 编译核心依赖 ---
cd /usr/src

# Sofia-SIP
sudo git config --global http.sslVerify false
sudo git clone https://gh-proxy.org/https://github.com/freeswitch/sofia-sip.git
cd sofia-sip && sudo ./bootstrap.sh && sudo ./configure && sudo make -j`nproc` && sudo make install
cd ..

# SpanDSP (回退到兼容版本 0d2e6ac 以修复 V18 编译错误)
sudo git clone https://gh-proxy.org/https://github.com/freeswitch/spandsp.git
cd spandsp
sudo git checkout 0d2e6ac
sudo ./bootstrap.sh && sudo ./configure && sudo make -j`nproc` && sudo make install
sudo ldconfig
cd ..

# --- 3. 编译 FreeSWITCH ---
sudo git clone -b v1.10.12 https://gh-proxy.org/https://github.com/signalwire/freeswitch.git
cd freeswitch
sudo ./bootstrap.sh -j

# 预先禁用部分模块以避免编译错误（可根据需要调整）
sudo sed -i 's/^applications\/mod_av$/#applications\/mod_av/g' modules.conf \
    && sed -i 's/^endpoints\/mod_verto$/#endpoints\/mod_verto/g' modules.conf \
    && sed -i 's/^applications\/mod_signalwire$/#applications\/mod_signalwire/g' modules.conf \
    && sed -i 's/^#formats\/mod_shout$/formats\/mod_shout/g' modules.conf

# sed -i 's/<!--<load module="mod_shout"\/>-->/<load module="mod_shout"\/>/g' modules.conf.xml

# 显式注入 -luuid 解决链接失败问题
sudo ./configure LIBS="-luuid" --with-gnu-ld --with-openssl --enable-zrtp --enable-system-lua
sudo make -j`nproc`
sudo make install
sudo make cd-sounds-install cd-moh-install

# --- 4. 用户权限与软链接 ---
sudo groupadd --system freeswitch || true
sudo adduser --disabled-password --quiet --system --home /usr/local/freeswitch --gecos "FreeSWITCH" --ingroup freeswitch freeswitch || true

# 统一修正权限
sudo chown -R freeswitch:freeswitch /usr/local/freeswitch
sudo chmod -R ug=rwX,o= /usr/local/freeswitch

# 建立软链接
sudo ln -sf /usr/local/freeswitch/bin/freeswitch /usr/bin/
sudo ln -sf /usr/local/freeswitch/bin/fs_cli /usr/bin/

# --- 5. 写入 Systemd 服务 ---
cat <<EOF | sudo tee /etc/systemd/system/freeswitch.service
[Unit]
Description=FreeSWITCH VoIP Server
After=syslog.target network.target local-fs.target

[Service]
Type=forking
User=freeswitch
Group=freeswitch
Environment="LD_LIBRARY_PATH=/usr/local/lib:/usr/local/freeswitch/lib"
ExecStartPre=/usr/bin/chown -R freeswitch:freeswitch /usr/local/freeswitch
ExecStart=/usr/local/freeswitch/bin/freeswitch -u freeswitch -g freeswitch -nonat -ncwait
Priority=-10
LimitCORE=infinity
LimitNOFILE=100000
LimitNPROC=60000
LimitTASKS=infinity
TasksMax=infinity

[Install]
WantedBy=multi-user.target
EOF

# --- 6. 启动与校验 ---
sudo systemctl daemon-reload
sudo systemctl enable freeswitch
sudo systemctl start freeswitch

echo "-------------------------------------------------------"
echo "安装完成！正在校验服务状态..."
sudo systemctl is-active freeswitch

echo "尝试连接 fs_cli (按 Ctrl+D 退出)..."
sleep 2
sudo fs_cli -x "status"