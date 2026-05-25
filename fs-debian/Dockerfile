# --- 第一阶段：构建环境 ---
FROM debian:bookworm-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive

# 1. 安装编译所需的工具链和核心库
RUN apt-get update && apt-get install -y --no-install-recommends \
    git build-essential autoconf automake libtool libtool-bin \
    pkg-config libssl-dev zlib1g-dev libncurses5-dev libncursesw5-dev \
    libjpeg-dev libsqlite3-dev libcurl4-openssl-dev libpcre3-dev \
    libspeex-dev libspeexdsp-dev libldns-dev libedit-dev \
    libpq-dev libopus-dev cmake uuid-dev libsndfile1-dev \
    libshout3-dev libmpg123-dev libmp3lame-dev \
    libtiff-dev nasm uuid-dev lua5.3 liblua5.3-dev lua-json lua-socket lua-sec

# 2. 克隆 FreeSWITCH 最新源码 (Release 分支)
WORKDIR /usr/src
RUN git config --global http.sslVerify false

RUN git clone -b v1.10.12 https://gh-proxy.org/https://github.com/signalwire/freeswitch.git

# 2. 编译核心依赖 Sofia-SIP 和 SpanDSP
# 注意：v1.10 之后这些被拆分为独立项目
RUN git clone https://gh-proxy.org/https://github.com/freeswitch/sofia-sip.git /usr/src/sofia-sip \
    && cd /usr/src/sofia-sip && ./bootstrap.sh && ./configure && make -j$(nproc) && make install

RUN git clone https://gh-proxy.org/https://github.com/freeswitch/spandsp.git /usr/src/spandsp \
    && cd /usr/src/spandsp && git checkout 0d2e6ac && ./bootstrap.sh && ./configure && make -j$(nproc) && make install

# 4. 配置并编译 FreeSWITCH
WORKDIR /usr/src/freeswitch
RUN ./bootstrap.sh -j

# 预先禁用部分模块以避免编译错误（可根据需要调整）
RUN sed -i 's/^applications\/mod_av$/#applications\/mod_av/g' modules.conf \
    && sed -i 's/^endpoints\/mod_verto$/#endpoints\/mod_verto/g' modules.conf \
    && sed -i 's/^applications\/mod_signalwire$/#applications\/mod_signalwire/g' modules.conf \
    && sed -i 's/^#formats\/mod_shout$/formats\/mod_shout/g' modules.conf

RUN ./configure
RUN make -j$(nproc)
RUN make install

# --- 第二阶段：运行环境 ---
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# 1. 只安装运行期必需的共享动态库（保持镜像精简）
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    libtiff6 libssl3 libsqlite3-0 libcurl4 libpcre3 libedit2 \
    libspeex1 libspeexdsp1 libldns3 libopus0 libsndfile1 ffmpeg \
    libshout3 libmpg123-0 libmp3lame0 liblua5.3-0 lua5.3 lua-json lua-socket lua-sec \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. 从 builder 阶段拷贝编译好的成品
COPY --from=builder /usr/local/freeswitch /usr/local/freeswitch
COPY --from=builder /usr/local/lib /usr/local/lib

# 3. 更新动态链接库缓存
RUN ldconfig

# 4. 设置路径环境变量
ENV PATH="/usr/local/freeswitch/bin:$PATH"

# 5. 创建运行目录并设置权限
RUN groupadd -r freeswitch && useradd -r -g freeswitch freeswitch \
    && mkdir -p /usr/local/freeswitch/run \
    && chown -R freeswitch:freeswitch /usr/local/freeswitch

# 6. 配置符号链接（可选，方便操作）
RUN ln -s /usr/local/freeswitch/bin/fs_cli /usr/bin/fs_cli

WORKDIR /usr/local/freeswitch/bin
USER freeswitch

CMD ["./freeswitch", "-nf", "-nonat"]