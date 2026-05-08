# Ubuntu 22.04 安装 freeswitch 1.10.12

## 1. 系统准备与依赖安装

```shell
ulimit -c unlimited -d unlimited -f unlimited -i unlimited -n 999999 -q unlimited -u unlimited -v unlimited -x unlimited -s 240 -l unlimited

sudo apt update && sudo apt install -y gnupg2 wget lsb-release

echo "oakhole" >/etc/yum/vars/signalwireusername
echo "pat_QAQRREtCTSA4vhanF15Rn3t7" >/etc/yum/vars/signalwiretoken
```

### 必装基础组件

```shell
sudo apt install -y
    git build-essential autoconf automake libtool libtool-bin
    pkg-config libssl-dev zlib1g-dev libncurses5-dev libncursesw5-dev
    libjpeg-dev libsqlite3-dev libcurl4-openssl-dev libpcre3-dev
    libspeex-dev libspeexdsp-dev libldns-dev libedit-dev
    liblua5.2-dev libopus-dev cmake

sudo apt install -y libtiff-dev nasm uuid-dev libsndfile1-dev libshout3-dev libmpg123-dev libmp3lame-dev
```

## 2. 核心组件编译 (Sofia-SIP & SpanDSP)

### 安装 Sofia-Sip

```shell
cd /usr/src
sudo git clone https://github.com/freeswitch/sofia-sip.git
cd sofia-sip
sudo ./bootstrap.sh && sudo ./configure && sudo make -j `nproc` && sudo make install
```

### 安装 SpanDsp

```shell
cd /usr/src
sudo git clone https://github.com/freeswitch/spandsp.git
cd spandsp
# 兼容支持 freeswitch 1.10.x
sudo git checkout 0d2e6ac
sudo ./bootstrap.sh && sudo ./configure && sudo make -j `nproc` && sudo make install
sudo ldconfig  # 刷新动态链接库
```

## 安装 FreeSWITCH

### 下载并配置 FreeSWITCH

```shell
cd /usr/src
sudo git clone -b v1.10.12 https://gh-proxy.org/https://github.com/signalwire/freeswitch.git
cd freeswitch

sudo ./bootstrap.sh -j
sudo ./configure LIBS="-luuid"

sudo make -j`nproc`
sudo make install

# 安装标准音效包
sudo make cd-sounds-install
sudo make cd-moh-install

```

### 添加 freeswitch 用户和组

```shell
sudo groupadd freeswitch
sudo adduser --disabled-password  --quiet --system --home /usr/local/freeswitch --gecos "FreeSWITCH" --ingroup freeswitch freeswitch
sudo chown -R freeswitch:freeswitch /usr/local/freeswitch
sudo chmod -R ug=rwX,o= /usr/local/freeswitch
```

### 设置软链接

```shell
sudo ln -s /usr/local/freeswitch/bin/freeswitch /usr/bin/
sudo ln -s /usr/local/freeswitch/bin/fs_cli /usr/bin/
```

### 配置 Systemd 服务

1. 配置 Systemd 服务（推荐）
   作为架构师，建议使用 systemd 管理服务，而不是手动启动。创建服务文件：`sudo vi /etc/systemd/system/freeswitch.service` 写入以下配置：

```ini,toml
[Unit]
Description=freeswitch
After=syslog.target network.target local-fs.target

[Service]
Type=forking
User=freeswitch
Group=freeswitch
Environment="LD_LIBRARY_PATH=/usr/local/lib:/usr/local/freeswitch/lib"
# 这里的路径需与你编译安装的路径一致
ExecStartPre=/usr/bin/chown -R freeswitch:freeswitch /usr/local/freeswitch
ExecStart=/usr/local/freeswitch/bin/freeswitch -u freeswitch -g freeswitch -ncwait
Priority=-10
LimitCORE=infinity
LimitNOFILE=100000
LimitNPROC=60000
LimitTASKS=infinity
TasksMax=infinity

[Install]
WantedBy=multi-user.target
```

### 启动并验证

```shell
sudo systemctl daemon-reload
sudo systemctl enable freeswitch
sudo systemctl start freeswitch

# 检查运行状态
sudo systemctl status freeswitch
```
