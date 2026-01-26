# 基础镜像
FROM centos:7.9.2009 AS base

ARG FREESWITCH_VERSION="v1.10.12"
ARG SOFIA_VERSION="v1.13.17"

# 编译阶段
FROM base AS builder-freeswitch

COPY patches/freeswitch/. ./patches

# 安装 阿里云源
RUN rm -rf /etc/yum.repos.d/* && \
    curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo && \
    curl -o /etc/yum.repos.d/epel-7.repo https://mirrors.aliyun.com/repo/epel-7.repo && \
    yum clean all && yum makecache

# 安装 依赖包 和 devtoolset-4
RUN echo "oakhole" >/etc/yum/vars/signalwireusername && echo "pat_QAQRREtCTSA4vhanF15Rn3t7" >/etc/yum/vars/signalwiretoken \
    && yum install -y https://$(</etc/yum/vars/signalwireusername):$(</etc/yum/vars/signalwiretoken)@freeswitch.signalwire.com/repo/yum/centos-release/freeswitch-release-repo-0-1.noarch.rpm epel-release \
    && yum install -y wget git gcc-c++ patch vim tar which build-base autoconf automake make libtool openssl-devel glib-devel lksctp-tools-devel bzip2 bzip2-devel zlib-devel libjpeg-devel libpng-devel libtiff-devel freetype-devel fontconfig-devel libcurl-devel libxml2-devel sqlite-devel speex-devel speexdsp-devel libsndfile-devel libsamplerate-devel ldns-devel neon-devel opus-devel pcre-devel libedit-devel gnutls-devel libevent-devel libical-devel yasm nasm sox libshout-devel gsm-devel libvorbis-devel libwebp-devel openjpeg2-devel libtheora-devel libmad-devel libmnl-devel fftw-devel cppunit-devel python3-devel lua-devel jemalloc-devel mysql-devel postgresql-devel unixODBC-devel libtool-ltdl-devel qt5-qtbase-devel qt5-qttools-devel cmake3 pulseaudio-libs-devel tcl-devel opusfile-devel libsrtp-devel libffi-devel python3-pip python3-virtualenv spandsp3-devel libks2 sofia-sip-devel python2 python2-devel erlang \
    && wget -O /etc/yum.repos.d/devtoolset-4.repo https://copr.fedoraproject.org/coprs/hhorak/devtoolset-4-rebuild-bootstrap/repo/epel-7/hhorak-devtoolset-4-rebuild-bootstrap-epel-7.repo --no-check-certificate \
    && yum update -y && yum install -y devtoolset-4-gcc* && scl enable devtoolset-4 'bash'

# 下载 fs 和 sofia-sip 源码
RUN git clone --depth 1 --branch "${FREESWITCH_VERSION}" https://github.com/signalwire/freeswitch /freeswitch \
    && rm -rf /freeswitch/.git \
    && git clone --depth 1 --branch "${SOFIA_VERSION}" https://github.com/freeswitch/sofia-sip /libdeps/sofia-sip \
    && rm -rf /sofia-sip/.git

RUN cd /libdeps/sofia-sip \
    && ./bootstrap.sh \
    && ./configure --prefix=/usr --enable-sctp --with-openssl --without-doxygen --enable-static=no \
    && make -j$(nproc --all) \
    && make DESTDIR=/build install

RUN cd /freeswitch \
    && for i in /patches/*.patch; do patch -p1 < $i; done \
    && ./bootstrap.sh \
    && ./configure --enable-portable-binary --prefix=/usr --localstatedir=/var --sysconfdir=/etc --with-gnu-ld --with-python --with-erlang --with-openssl --enable-core-odbc-support --enable-zrtp --enable-system-lua \
    && make -j$(nproc --all) \
    && make install \
    && make DESTDIR=/build install \
    && make DESTDIR=/build samples-conf \
    && ldd $(which freeswitch) | cut -d" " -f3 | xargs tar --dereference -cf /build/libs.tar \
    && cd /build && tar zcvf /build.tar.gz *

# 运行阶段
FROM base AS runner

ARG WORKER_USER_ID=499

COPY  --from=builder-freeswitch /build.tar.gz /build.tar.gz
RUN tar zxvf /build.tar.gz

RUN groupadd -g ${WORKER_USER_ID} freeswitch \
    && useradd -u ${WORKER_USER_ID} -g freeswitch freeswitch \
    && rm -rf /etc/yum.repos.d/* \
    && curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo \
    && curl -o /etc/yum.repos.d/epel-7.repo https://mirrors.aliyun.com/repo/epel-7.repo \
    && echo "oakhole" >/etc/yum/vars/signalwireusername && echo "pat_QAQRREtCTSA4vhanF15Rn3t7" >/etc/yum/vars/signalwiretoken \
    && yum install -y https://$(</etc/yum/vars/signalwireusername):$(</etc/yum/vars/signalwiretoken)@freeswitch.signalwire.com/repo/yum/centos-release/freeswitch-release-repo-0-1.noarch.rpm epel-release \
    && yum install -y ldns libsndfile opus libks2 \
    && tar -xf /libs.tar \
    && rm -rf /libs.tar

EXPOSE 8021/tcp
EXPOSE 5060/tcp 5060/udp 5080/tcp 5080/udp

HEALTHCHECK --interval=15s --timeout=5s \
    CMD  fs_cli -x status | grep -q ^UP || exit 1

# USER freeswitch
CMD ["/usr/bin/freeswitch", "-nc", "-nf", "-nonat"]
