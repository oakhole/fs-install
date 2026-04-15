FROM ghcr.io/patrickbaus/freeswitch-docker

# 安装必要的依赖
RUN apk update && \
    apk add --no-cache lua5.3-cjson lua5.3-socket

# 创建必要的目录
RUN mkdir -p /home/freeswitch/log /home/freeswitch/records

# 挂载点（声明以便于 k8s/orchestrator 提示）
VOLUME ["/etc/freeswitch", "/home/freeswitch/log", "/home/freeswitch/records"]

# 设置环境变量（可根据需求调整）
ENV TZ=Asia/Shanghai

# 复制配置文件（如有本地配置，请解注释下行并提供对应文件）
COPY ./etc/freeswitch/ /etc/freeswitch/

# 启动 FreeSWITCH
CMD ["/usr/bin/freeswitch"]