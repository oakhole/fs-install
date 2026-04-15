# 示例命令
# -v /etc/freeswitch:/etc/freeswitch \
# -v /home/freeswitch/log:/home/freeswitch/log \
# -v /home/freeswitch/records:/home/freeswitch/records \
docker run -d \
    --net=host \
    --cap-add=SYS_NICE \
    --restart=always \
    -e "TZ=Asia/Shanghai" \
    --name freeswitch \
    fs:latest