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
  <X-PRE-PROCESS cmd="set" data="default_password=COMPLEX_PASSWORD"/>
  ```

- 变更 sip 监听 IP 和 端口

  ```xml
  <!-- conf/vars.xml -->
  <X-PRE-PROCESS cmd="set" data="internal_sip_port=5060"/>
  <!-- Internal SIP Profile -->
  <X-PRE-PROCESS cmd="set" data="internal_auth_calls=true"/>
  <X-PRE-PROCESS cmd="set" data="internal_sip_port=PORT"/>
  <X-PRE-PROCESS cmd="set" data="internal_tls_port=PORT"/>
  <X-PRE-PROCESS cmd="set" data="internal_ssl_enable=false"/>

  <!-- External SIP Profile -->
  <X-PRE-PROCESS cmd="set" data="external_auth_calls=false"/>
  <X-PRE-PROCESS cmd="set" data="external_sip_port=PORT"/>
  <X-PRE-PROCESS cmd="set" data="external_tls_port=PORT"/>
  <X-PRE-PROCESS cmd="set" data="external_ssl_enable=false"/>

  <!-- RTP port range -->
  <param name="rtp-start-port" value="16384"/>
  <param name="rtp-end-port" value="32768"/>
  ```

- 语音编码

  ```xml
  <!-- conf/vars.xml -->
  <X-PRE-PROCESS cmd="set" data="global_codec_prefs=PCMA,PCMU"/>
  <X-PRE-PROCESS cmd="set" data="outbound_codec_prefs=PCMA,PCMU"/>
  ```

- `SPS` 和 `max_session`, 对应 caps 值和最大会话数。默认值 sps=30，max_session=1000
  `fsctl sps` 或 `fsctl max_session` 查看当前运行环境中的默认值。

  ```xml
  <!-- conf/autoload/switch.conf.xml -->
  <param name="max-sessions" value="100000"/>
  <!--Most channels to create per second -->
  <param name="sessions-per-second" value="300"/>
  ```

- ACL

  ```xml
  <!-- conf/autoload/acl.conf.xml -->
  <list name="domains" default="deny">
    <!-- 添加域 -->
    <node type="allow" domain="DOMAIN"/>
    <!-- 添加 ip 地址段 -->
    <node type="allow" cidr="192.168.0.0/24"/>
  </list>
  ```

- 落地网关

  ```xml
  <!-- conf/external/<NEW_FILE> -->
  <include>
        <gateway name="GATEWAY_NAME">
            <!-- 落地网关的 ip 和端口 -->
            <param name="realm" value="IP:PORT"/>
            <!-- 是否注册 -->
            <param name="register" value="false" />
            <!-- 透传主叫号码 -->
            <param name="caller-id-in-from" value="true"/>
            <!-- 配置客户端设备名称 -->
            <param name="user-agent-string"value="<CLIENT_NAME>"/>
        </gateway>
    </include>
  ```

- SBC 媒体配置

  `default`: 默认模式，协商转发转码媒体流，适合呼叫中心场景。
  `proxy-media`: 代理模式，转发不处理，不对 SDP 信息进行处理，适合 SBC 场景解决 nat 问题。
  `bypass-media`: 旁路模式，不转发不处理，性能最高，适合信令代理、黑名单、计费等场景。

  ```xml
  <!-- sip_profile/internal.xml Uncomment to set all inbound calls to proxy media mode -->
  <param name="inbound-proxy-media" value="true"/>
  ```

- 呼入路由

  ```xml
  <!-- diaplan/public.xml -->
  <extension name="inbound">
      <condition field="destination_number" expression="^(extin.*)$">
          <param name="set" value="bypass-media=true"/>
          <action application="bridge" data="sofia/gateway/<GATEWAY_NAME>/$1" />
      </condition>
  </extension>
  ```

- 外呼路由

  ```xml
    <!-- diaplan/public.xml -->
    <extension name="outbound">
        <condition field="destination_number" expression="^(extout.*)$">
            <param name="set" value="bypass-media=true"/>
            <action application="bridge" data="sofia/gateway/<GATEWAY_NAME>/$1" />
        </condition>
    </extension>
  ```

- 删除冗余配置

  ```txt
  conf/chatplan/default.xml
  conf/dialplan/*
  conf/directory/*
  conf/ivr_menus/*
  conf/jingle_profiles/*
  conf/mrcp_profiles/*
  conf/sip_profile/*ipv6*.xml
  conf/skinny_profiles/*
  ```

#### 优化配置（选择性）

- 使用内存，freeswitch 内置的数据库 sqlite 对性能影响也很大， 磁盘 IO 在每次呼叫都有发生，所以可以把 core db 放到 ram 里。

  ```xml
  <!-- conf/autoload/switch.conf.xm -->
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
  <!-- conf/autoload/switch.conf.xml -->
  <param name="session-pool" value="true"/>
  ```
