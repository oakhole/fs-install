# Docker - FreeSWITCH 容器化部署

本目录包含 FreeSWITCH 的 Docker 容器化配置和构建文件。

## 一键安装脚本

```bash
curl -o- https://gitee.com/oakhole/fs-install/raw/main/docker/install.sh | bash
```

## 目录结构

```
docker/
├── README.md              # 本文件，项目文档
├── Dockerfile             # Docker 镜像构建文件
├── build.sh               # 构建脚本，生成 ./build/build.tar.gz
├── install.sh             # 容器内部初始化安装脚本
├── patches/               # FreeSWITCH 补丁文件目录
│   └── freeswitch/        # FreeSWITCH 相关补丁
│       ├── disable_mod_av.patch              # 禁用 AV 模块
│       ├── disable_mod_av_config.patch       # 禁用 AV 模块配置
│       ├── disable_mod_signalwire.patch      # 禁用 SignalWire 模块
│       └── disable_mod_signalwire_config.patch  # 禁用 SignalWire 配置
└── build/                 # 构建输出目录
    ├── build.tar.gz       # 构建产物压缩包，解压至 centos 7.x 系统根目录
    ├── libs.tar           # freeswitch 依赖库打包
    ├── etc/               # 系统配置文件
    │   ├── freeswitch/    # FreeSWITCH 主配置
    │   │   ├── freeswitch.xml     # 主配置文件
    │   │   ├── mime.types         # MIME 类型定义
    │   │   ├── vars.xml           # 变量定义
    │   │   ├── autoload_configs/   # 自动加载配置模块
    │   │   ├── dialplan/           # 拨号计划
    │   │   └── sbc_profiles/       # SBC 配置文件
    │   └── systemd/               # Systemd 服务配置
    ├── usr/               # 用户程序文件
    │   ├── bin/           # 可执行文件（freeswitch, fs_cli 等）
    │   ├── include/       # 头文件（FreeSWITCH 和 Sofia-SIP）
    │   ├── lib/           # 库文件和模块
    │   └── share/         # 共享资源文件
    └── var/               # 变量数据目录
        ├── lib/freeswitch/   # FreeSWITCH 数据目录
        ├── log/freeswitch/   # 日志目录
        └── run/freeswitch/   # 运行时目录
```

## 文件说明

### Dockerfile

多阶段 Docker 构建文件，使用 CentOS 7.9.2009 作为基础镜像。

**构建阶段:**

- **builder-freeswitch**: 编译 FreeSWITCH 和 Sofia-SIP 依赖库
    - 配置阿里云源以加速依赖下载
    - 安装编译工具链（devtoolset-4）和各类开发库
    - 克隆 FreeSWITCH (v1.10.12) 和 Sofia-SIP (v1.13.17) 源码
    - 应用补丁文件
    - 编译并生成二进制文件和库

- **runner**: 运行环境镜像
    - 基于 CentOS 7.9.2009
    - 包含 FreeSWITCH 运行时依赖
    - 集成所有编译好的二进制文件

### install.sh

容器初始化脚本，在容器启动时执行以下操作：

1. **系统配置**
    - 设置 `ulimit` 参数（文件描述符限制、内存限制等）
    - 关闭 SELinux 和防火墙

2. **包管理配置**
    - 配置阿里云 YUM 源（加速下载）
    - 添加 FreeSWITCH 官方源

3. **依赖安装**
    - 安装 FreeSWITCH 运行时依赖库
    - 安装 NTP 时间同步工具

4. **编译文件部署**
    - 从远程下载预编译的 FreeSWITCH 二进制和库文件
    - 解压到系统相应目录

5. **用户和权限**
    - 创建 `freeswitch` 用户和用户组（UID/GID: 499）

6. **Systemd 服务**
    - 启用 FreeSWITCH systemd 服务
    - 设置开机自启

### build/ 目录

构建过程生成的文件和配置目录，包含：

- **etc/freeswitch/**: FreeSWITCH 核心配置文件
    - `freeswitch.xml`: 主配置文件，定义模块加载和系统参数
    - `autoload_configs/`: 各功能模块配置（ACL、CDR、事件、SIP 等）
    - `dialplan/`: 拨号计划（default、features、public）
    - `sbc_profiles/`: SBC（会话边界控制器）配置

- **usr/bin/**: 可执行命令
    - `freeswitch`: FreeSWITCH 主程序
    - `fs_cli`: FreeSWITCH 命令行客户端
    - 其他工具：fs_encode、fs_ivrd、fs_tts 等

- **usr/lib/**: FreeSWITCH 模块和依赖库
    - `libfreeswitch.so.1.0.0`: 主库文件
    - `freeswitch/mod/`: 功能模块

- **var/**: 运行时数据目录
    - `lib/freeswitch/`: 数据存储目录
    - `log/freeswitch/`: 日志目录
    - `run/freeswitch/`: PID 和 Socket 目录

## patches/ 目录

包含对 FreeSWITCH 源码的补丁文件：

| 补丁文件                              | 说明                     |
| ------------------------------------- | ------------------------ |
| `disable_mod_av.patch`                | 禁用音视频模块           |
| `disable_mod_av_config.patch`         | 禁用音视频模块配置加载   |
| `disable_mod_signalwire.patch`        | 禁用 SignalWire 模块     |
| `disable_mod_signalwire_config.patch` | 禁用 SignalWire 配置加载 |

这些补丁用于在构建过程中移除不需要的功能模块。

## 使用方法

### 构建镜像

```bash
cd docker
docker build -t freeswitch:latest .
```

**构建参数:**

- `FREESWITCH_VERSION`: FreeSWITCH 版本（默认: v1.10.12）
- `SOFIA_VERSION`: Sofia-SIP 版本（默认: v1.13.17）

```bash
docker build --build-arg FREESWITCH_VERSION=v1.10.12 \
             --build-arg SOFIA_VERSION=v1.13.17 \
             -t freeswitch:custom .
```

### 运行容器

```bash
docker run -rm \
  --net=host \
  --cap-add SYS_NICE \
  --privileged=true \
  --name fs-instance \
  -v ./build:/build \
  freeswitch:latest \
  /bin/bash cd /build && tar zcvf build.tar.gz ./
```

**常用选项:**

- `--net=host`: 使用主机网络（SIP/RTP 需要）
- `--cap-add SYS_NICE`: 允许优先级管理
- `--privileged=true`: 特权模式（系统配置需要）
- `-v`: 挂载卷（配置和日志持久化）

### 访问 FreeSWITCH CLI

```bash
# 进入容器
docker exec -it fs-instance /usr/bin/fs_cli

# 常用命令
status                    # 查看系统状态
show channels             # 查看所有通道
show calls                # 查看活动通话
reloadxml                 # 重新加载配置
```

## 重要说明

### 网络配置

- **SIP 端口**: 5060 (UDP/TCP), 5080
- **RTP 端口**: 16384 - 32768 (UDP)
- **事件 Socket**: 8021 (TCP)

确保防火墙规则允许这些端口的流量。

### 性能优化

- `ulimit -n 999999`: 文件描述符限制（支持高并发）
- `ulimit -s 240`: 栈内存限制
- `--cap-add SYS_NICE`: 实时优先级支持

### 存储和日志

- 配置文件: `/etc/freeswitch/`
- 数据目录: `/var/lib/freeswitch/`
- 日志文件: `/var/log/freeswitch/`

## 维护和支持

- FreeSWITCH 官网: https://freeswitch.org
- 项目仓库: https://github.com/signalwire/freeswitch
- Sofia-SIP: https://github.com/freeswitch/sofia-sip
