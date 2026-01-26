#!/bin/bash

# Enable strict error handling:
# -e: Exit immediately if any command exits with a non-zero status
# -u: Exit if an undefined variable is referenced
set -euo

# 构建 docker 镜像
FREESWITCH_VERSION = "v1.10.12"
SOFIA_VERSION = "v1.13.17"

docker build --build-arg FREESWITCH_VERSION=${FREESWITCH_VERSION} \
    --build-arg SOFIA_VERSION=${SOFIA_VERSION} \
    -t freeswitch:${FREESWITCH_VERSION} .

# 运行容器
docker run -rm \
    --net=host \
    --cap-add SYS_NICE \ 
    --privileged=true \
    --name fs-instance \
    -v ./build:/build \
    freeswitch:${FREESWITCH_VERSION} \
    /bin/bash -c "cd /build && tar zcvf build.tar.gz ./"