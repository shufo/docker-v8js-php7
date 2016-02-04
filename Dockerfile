FROM phusion/baseimage:latest
MAINTAINER shufo <meikyowise@gmail.com>

RUN apt-get update
RUN apt-get -y install git subversion make g++ python curl chrpath language-pack-en-base && apt-get clean
RUN LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php && apt-get update
RUN apt-get install -y php7.0 php7.0-cli php7.0-dev

# depot tools
RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git /usr/local/depot_tools
ENV PATH $PATH:/usr/local/depot_tools

# download v8
RUN cd /usr/local/src && fetch v8

# compile v8
RUN cd /usr/local/src/v8 && make native library=shared snapshot=off -j8

# install v8
RUN mkdir -p /usr/local/lib
RUN cp /usr/local/src/v8/out/native/lib.target/lib*.so /usr/local/lib
RUN echo "create /usr/local/lib/libv8_libplatform.a\naddlib /usr/local/src/v8/out/native/obj.target/tools/gyp/libv8_libplatform.a\nsave\nend" | ar -M
RUN cp -R /usr/local/src/v8/include /usr/local
RUN chrpath -r '$ORIGIN' /usr/local/lib/libv8.so

# get v8js, compile and install
RUN git clone https://github.com/preillyme/v8js.git /usr/local/src/v8js
RUN cd /usr/local/src/v8js && phpize && ./configure --with-v8js=/usr/local
ENV NO_INTERACTION 1
RUN cd /usr/local/src/v8js && make all test install

# autoload v8js.so
RUN echo extension=v8js.so > /etc/php/7.0/cli/conf.d/99-v8js.ini