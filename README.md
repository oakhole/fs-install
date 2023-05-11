## FS 安装及配置

### 系统环境

CentOS 系统 7.x mini

#### 内核参数 `ulimit` 配置

```shell
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
```

#### 防火墙配置

```shell
# 关闭 ipables 服务
systemctl stop iptables.service
systemctl disable iptables.service
```

`SIP端口`: 5060 / 5080
`RTP端口`: 16384 - 32768

#### 网络配置

- 多网卡配置, 或云服务器配置

`ip route add 221.181.213.19/32 via 10.44.241.177`

### FS 安装

使用 fusionpbx 脚本安装 Freeswitch。

- **前置条件**
  配置``

```shell
yum install -y git
git clone https://gitee.com/oakhole/fs-install.git && cd fs-install && chmod +x install.sh
install.sh
```

开启 `sngrep` 监控 sip 消息，使用 sip 客户端登录用户 `1000、1001` 到 `IP:5060` 的 sip 消息并相互呼叫验证服务是否可用。

### FS 服务配置

#### 建议配置

- 默认分机密码

  ```xml
  <!-- vars.xml -->
  ```

- 变更 sip 监听 IP 和 端口

  ```xml
  <!-- vars.xml -->
  <X-PRE-PROCESS cmd="set" data="internal_sip_port=5060"/>

  <!-- RTP port range -->
  <param name="rtp-start-port" value="16384"/>
  <param name="rtp-end-port" value="32768"/>
  ```

- 语音编码

  ```xml
  <!-- vars.xml -->
  <X-PRE-PROCESS cmd="set" data="internal_sip_port=5060"/>
  ```

- `SPS` 和 `max_session`, 对应 caps 值和最大会话数。默认值 sps=30，max_session=1000
  `fsctl sps` 或 `fsctl max_session` 查看当前运行环境中的默认值。

  ```xml
  <!-- switch.conf.xml -->
  ```

- ACL

  ```xml

  ```

- 落地网关

  ```xml

  ```

#### 优化配置（选择性）

- 使用内存，freeswitch 内置的数据库 sqlite 对性能影响也很大， 磁盘 IO 在每次呼叫都有发生，所以可以把 core db 放到 ram 里。

  ```xml
  <!-- switch.conf.xm -->
  <param name="core-db-name" value="/dev/shm/core.db" />
  ```

  或者，在启动时禁止数据库，启动时加参数 `-nosql`, 完整启动命令为 `freeswitch -nc -nonat -nosql`

- 关闭 media timer，关闭 sip profile 的 media 检测。

  ```xml
  <!-- sip profile 文件 internal.xml 或者 external.xml 里面的 rtp-timeout 和 rtp-hold-timeout，改成 0 -->
  <set rtp-timeout="0"/>
  <set rtp-hold-timeout="0"/>
  ```

- 关闭不必要的模块，如 xml_cdr，默认写通话记录到磁盘，影响性能。模块配置注释 `mod_xml_cdr` 后重启。

  ```xml
  <!-- <load module="mod_xml_cdr"/> -->
  ```

- 对于 caps 很高的应用，为了提高系统吞吐量，可以使用 session 线程池,在 switch.conf.xml 文件修改 session-pool 为 true。

  ```xml
  <!-- switch.conf.xml -->
  <param name="session-pool" value="true"/>
  ```
