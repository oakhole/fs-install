# 示例命令
docker run -d \
    --net=host \
    --cap-add SYS_NICE \
    # -v /etc/freeswitch:/etc/freeswitch \
    # -v /home/freeswitch/log:/home/freeswitch/log \
    # -v /home/freeswitch/records:/home/freeswitch/records \
    --name freeswitch \
    --restart=always \
    -e "TZ=Asia/Shanghai" \
    fs:latest