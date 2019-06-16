FROM alpine:3.7

LABEL maintainer="Serhiy Kanyuka <serhiy@kanyuka.info>"

ENV GPG_KEYS 0B96609E270F565C13292B24C13C70B87267B52D 0BD78B5F97500D450838F95DFE857D9A90D90EC1 F38252826ACD957EF380D39F2F7956BC5DA04B5D



ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

COPY scripts/docker-php-ext-* scripts/docker-php-entrypoint scripts/docker-php-source  /usr/local/bin/

ENV NGINX_VERSION 1.14.0
ENV LUA_MODULE_VERSION 0.10.13
ENV DEVEL_KIT_MODULE_VERSION 0.3.0
ENV LUAJIT_LIB=/usr/lib
ENV LUAJIT_INC=/usr/include/luajit-2.1

RUN apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing \
	wget \
	git \
	rsync  \
	curl \
	tar \
	xz \
	ca-certificates \
	libressl \
	supervisor \
	logrotate \
        && mkdir -p /var/log/supervisor \
        && addgroup -g 1000 -S www-data \
        && adduser -u 1000 -D -S -G www-data www-data \
        && addgroup -S nginx \
        && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx 


RUN apk add --no-cache --virtual .build-deps \
	#&& apk add --no-cache --virtual .build-deps \
		#$PHPIZE_DEPS \
		coreutils \
		curl-dev \
		libedit-dev \
		libsodium-dev \
		libxml2-dev \
		sqlite-dev \
	\
    gnupg \
    musl-dev \
    autoconf \
    gcc \
    g++ \
    make \
    libc-dev \
    libressl-dev \
    pcre-dev \
    zlib-dev \
    linux-headers \
    libxslt-dev \
    gd-dev \
    geoip-dev \
    perl-dev \
    luajit-dev \
    coreutils \
    curl-dev \
    libedit-dev \
    libxml2-dev \
    sqlite-dev \
    dpkg \
    dpkg-dev \
    libevent-dev \
    libmemcached-dev \
    file \
    libc-dev \
    pkgconf \
    re2c \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
        libmcrypt-dev \
    ; GPG_KEYS=B0F4253373F8F6F510D42178520A9993A1C052F8 \
  && CONFIG="\
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --modules-path=/usr/lib/nginx/modules \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/log/nginx.error.log \
    --http-log-path=/log/nginx.access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --user=nginx \
    --group=nginx \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_stub_status_module \
    --with-http_auth_request_module \
    --with-http_xslt_module=dynamic \
    --with-http_image_filter_module=dynamic \
    --with-http_geoip_module=dynamic \
    --with-http_perl_module=dynamic \
    --with-threads \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-stream_realip_module \
    --with-stream_geoip_module=dynamic \
    --with-http_slice_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-compat \
    --with-file-aio \
    --with-http_v2_module \
    --add-module=/usr/src/ngx_devel_kit-$DEVEL_KIT_MODULE_VERSION \
    --add-module=/usr/src/lua-nginx-module-$LUA_MODULE_VERSION \
  " \
  && curl -fSL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz \
  && curl -fSL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz.asc  -o nginx.tar.gz.asc \
  && curl -fSL https://github.com/simpl/ngx_devel_kit/archive/v$DEVEL_KIT_MODULE_VERSION.tar.gz -o ndk.tar.gz \
  && curl -fSL https://github.com/openresty/lua-nginx-module/archive/v$LUA_MODULE_VERSION.tar.gz -o lua.tar.gz \
  && export GNUPGHOME="$(mktemp -d)" \
  && found=''; \
  for server in \
    ha.pool.sks-keyservers.net \
    hkp://keyserver.ubuntu.com:80 \
    hkp://p80.pool.sks-keyservers.net:80 \
    pgp.mit.edu \
  ; do \
    echo "Fetching GPG key $GPG_KEYS from $server"; \
    gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$GPG_KEYS" && found=yes && break; \
  done; \
  test -z "$found" && echo >&2 "error: failed to fetch GPG key $GPG_KEYS" && exit 1; \
  gpg --batch --verify nginx.tar.gz.asc nginx.tar.gz \
  #&& rm -r "$GNUPGHOME" nginx.tar.gz.asc \
  && mkdir -p /usr/src \
  && tar -zxC /usr/src -f nginx.tar.gz \
  && tar -zxC /usr/src -f ndk.tar.gz \
  && tar -zxC /usr/src -f lua.tar.gz \
  && rm nginx.tar.gz ndk.tar.gz lua.tar.gz \ 
  && cd /usr/src/nginx-$NGINX_VERSION \
  && ./configure $CONFIG --with-debug \
  && make -j$(getconf _NPROCESSORS_ONLN) \
  && mv objs/nginx objs/nginx-debug \
  && mv objs/ngx_http_xslt_filter_module.so objs/ngx_http_xslt_filter_module-debug.so \
  && mv objs/ngx_http_image_filter_module.so objs/ngx_http_image_filter_module-debug.so \
  && mv objs/ngx_http_geoip_module.so objs/ngx_http_geoip_module-debug.so \
  && mv objs/ngx_http_perl_module.so objs/ngx_http_perl_module-debug.so \
  && mv objs/ngx_stream_geoip_module.so objs/ngx_stream_geoip_module-debug.so \
  && ./configure $CONFIG \
  && make -j$(getconf _NPROCESSORS_ONLN) \
  && make install \
  && rm -rf /etc/nginx/html/ \
  && mkdir /etc/nginx/conf.d/ \
  && mkdir -p /usr/share/nginx/html/ \
  && install -m644 html/index.html /usr/share/nginx/html/ \
  && install -m644 html/50x.html /usr/share/nginx/html/ \
  && install -m755 objs/nginx-debug /usr/sbin/nginx-debug \
  && install -m755 objs/ngx_http_xslt_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_xslt_filter_module-debug.so \
  && install -m755 objs/ngx_http_image_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_image_filter_module-debug.so \
  && install -m755 objs/ngx_http_geoip_module-debug.so /usr/lib/nginx/modules/ngx_http_geoip_module-debug.so \
  && install -m755 objs/ngx_http_perl_module-debug.so /usr/lib/nginx/modules/ngx_http_perl_module-debug.so \
  && install -m755 objs/ngx_stream_geoip_module-debug.so /usr/lib/nginx/modules/ngx_stream_geoip_module-debug.so \
  && ln -s ../../usr/lib/nginx/modules /etc/nginx/modules \
  && strip /usr/sbin/nginx* \
  && strip /usr/lib/nginx/modules/*.so \
  && rm -rf /usr/src/nginx-$NGINX_VERSION \
  && apk add --no-cache --virtual .gettext gettext \
  && mv /usr/bin/envsubst /tmp/ \
  && runDeps="$( \
    scanelf --needed --nobanner /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst \
      | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
      | sort -u \
      | xargs -r apk info --installed \
      | sort -u \
  )" \
  && apk add --no-cache --virtual .nginx-rundeps $runDeps \
  && mv /tmp/envsubst /usr/local/bin/ 


COPY scripts/docker-php-* /usr/local/bin/


ENV PHP_VERSION 7.3.4
ENV PHP_INI_DIR /etc/php7
ENV PHP_CONF_DIR $PHP_INI_DIR/conf.d

ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -Wl,--hash-style=both -pie"

ENV GPG_KEYS CBAF69F173A0FEA4B537F470D66C9593118BCCB6 F38252826ACD957EF380D39F2F7956BC5DA04B5D

ENV PHP_VERSION 7.3.4
ENV PHP_URL="https://www.php.net/get/php-7.3.4.tar.xz/from/this/mirror" PHP_ASC_URL="https://www.php.net/get/php-7.3.4.tar.xz.asc/from/this/mirror"
ENV PHP_SHA256="6fe79fa1f8655f98ef6708cde8751299796d6c1e225081011f4104625b923b83" PHP_MD5=""



RUN set -xe; \
	mkdir /etc/php7; \
	apk add --no-cache --virtual .fetch-deps \
		gnupg \
		wget \
	; \
	\
	mkdir -p /usr/src; \
	cd /usr/src; \
	\
	wget -O php.tar.xz "$PHP_URL"; 
	
RUN	if [ -n "$PHP_SHA256" ]; then \
		echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c -; \
	fi; \
	if [ -n "$PHP_MD5" ]; then \
		echo "$PHP_MD5 *php.tar.xz" | md5sum -c -; \
	fi; \
	\
	if [ -n "$PHP_ASC_URL" ]; then \
		wget -O php.tar.xz.asc "$PHP_ASC_URL"; \
		export GNUPGHOME="$(mktemp -d)"; \
		for key in $GPG_KEYS; do \
			gpg --batch --keyserver pool.sks-keyservers.net --recv-keys "$key"; \
		done; \
		gpg --batch --verify php.tar.xz.asc php.tar.xz; \
		command -v gpgconf > /dev/null && gpgconf --kill all; \
		rm -rf "$GNUPGHOME"; \
	fi; \
	\
	apk del --no-network .fetch-deps


RUN set -xe \
	&& export CFLAGS="$PHP_CFLAGS" \
		CPPFLAGS="$PHP_CPPFLAGS" \
		LDFLAGS="$PHP_LDFLAGS" \
	&& docker-php-source extract \
	&& cd /usr/src/php \
	&& gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
	&& ./configure \
		--build="$gnuArch" \
		--with-config-file-path="$PHP_INI_DIR" \
		--with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
		\
# make sure invalid --configure-flags are fatal errors intead of just warnings
		--enable-option-checking=fatal \
		\
# https://github.com/docker-library/php/issues/439
		--with-mhash \
		\
# --enable-ftp is included here because ftp_ssl_connect() needs ftp to be compiled statically (see https://github.com/docker-library/php/issues/236)
		--enable-ftp \
# --enable-mbstring is included here because otherwise there's no way to get pecl to use it properly (see https://github.com/docker-library/php/issues/195)
		--enable-mbstring \
# --enable-mysqlnd is included here because it's harder to compile after the fact than extensions are (since it's a plugin for several extensions, not an extension in itself)
		--enable-mysqlnd \
# https://wiki.php.net/rfc/argon2_password_hash (7.2+)
#		--with-password-argon2 \
# https://wiki.php.net/rfc/libsodium
		--with-sodium=shared \
		\
		--with-curl \
		--with-libedit \
		--with-openssl \
		--with-zlib \
		\
# bundled pcre does not support JIT on s390x
# https://manpages.debian.org/stretch/libpcre3-dev/pcrejit.3.en.html#AVAILABILITY_OF_JIT_SUPPORT
		$(test "$gnuArch" = 's390x-linux-gnu' && echo '--without-pcre-jit') \
		\
		$PHP_EXTRA_CONFIGURE_ARGS \
	&& make -j "$(nproc)" \
	&& find -type f -name '*.a' -delete \
	&& make install \
	&& { find /usr/local/bin /usr/local/sbin -type f -perm +0111 -exec strip --strip-all '{}' + || true; } \
	&& make clean \
	\
# https://github.com/docker-library/php/issues/692 (copy default example "php.ini" files somewhere easily discoverable)
	&& cp -v php.ini-* "$PHP_INI_DIR/" \
	\
	&& cd / \
	&& docker-php-source delete \
	\
	&& runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)" \
	&& apk add --no-cache $runDeps \
	\
	#&& apk del --no-network .build-deps \
	\
# https://github.com/docker-library/php/issues/443
	&& pecl update-channels \
	&& rm -rf /tmp/pear ~/.pearrc


# sodium was built as a shared module (so that it can be replaced later if so desired), so let's enable it too (https://github.com/docker-library/php/issues/598)
# RUN docker-php-ext-enable sodium


RUN apk add --no-cache --virtual .php-rundeps $runDeps \
	&& rm -rf /tmp/pear ~/.pearrc \
	&& pecl update-channels \
	&& pecl install memcache \
	&& pecl install apcu-4.0.11 \
	&& cd /tmp \
    && apk --update add cyrus-sasl-dev libmemcached-dev \
    && curl -L --progress-bar -o "php-memcached-2.2.0.tar.gz" "https://github.com/php-memcached-dev/php-memcached/archive/2.2.0.tar.gz" \
    && tar -xzvf php-memcached-2.2.0.tar.gz \
    && cd php-memcached-2.2.0 \
    && phpize \
	&& mkdir -p /usr/local/etc/php/conf.d \
    && ./configure --disable-memcached-sasl \
    && make \
    && make install \
    && docker-php-ext-enable memcached \
    && cd .. \
    && rm -rf php-memcached-2.2.0 \
    && rm php-memcached-2.2.0.tar.gz \
	&& docker-php-source delete \
    && apk del .gettext \
    #&& apk del .build-deps \
	&& rm -fR /usr/src \
	&& mkdir -p $PHP_INI_DIR/conf.d \
  && echo "extension=memcache.so" > $PHP_CONF_DIR/memcache.ini \
  && echo "extension=memcached.so" > $PHP_CONF_DIR/memcached.ini \
  && echo "extension=apcu.so" > $PHP_CONF_DIR/apcu.ini \
  && echo "date.timezone = UTC" > $PHP_CONF_DIR/date.ini \
  && rm -Rf /var/www/* 

WORKDIR /root

RUN	 wget https://github.com/pear/Net_Socket/archive/master.zip \
	&& unzip master.zip \
	&& mv ./Net_Socket-master/ ./Net_Socket \
	&& pear install ./Net_Socket/package.xml \
	&& rm -f ./master.zip \
	&& wget https://github.com/pear/Auth_SASL/archive/master.zip \
	&& unzip master.zip \
	&& mv ./Auth_SASL-master/ ./Auth_SASL \
	&& pear install ./Auth_SASL/package.xml \
	&& rm -f ./master.zip \
	&& wget https://github.com/pear/Net_SMTP/archive/master.zip \
	&& unzip master.zip \
	&& pear install ./Net_SMTP-master/package.xml   \
	&& rm -f ./master.zip \
	&& wget https://github.com/pear/Log/archive/master.zip \
	&& unzip master.zip \
	&& pear install ./Log-master/package.xml   \
	&& rm -f ./master.zip \
	&& wget https://github.com/pear/Mail/archive/master.zip \
	&& unzip master.zip \
	&& pear install ./Mail-master/package.xml \
	&& rm -f ./master.zip \
	&& wget https://github.com/kvz/system_daemon/raw/master/packages/System_Daemon-1.0.0.tgz \
	&& pear install System_Daemon-1.0.0.tgz \
	&& pear channel-discover phpseclib.sourceforge.net \
	&& pear install  --alldeps phpseclib/Net_SSH2 \
	&& pear install  --alldeps phpseclib/Crypt_RSA 


# nginx site conf
RUN mkdir -p /etc/nginx/sites-available/ \
        && rm -f /etc/nginx/sites-available/* \
	&& mkdir -p /etc/nginx/sites-enabled/ \
	&& rm -f /etc/nginx/sites-enabled/* \
	&& rm -Rf /var/www/* \
 	&& rm -Rf /etc/nginx/nginx.conf \
 	&& mkdir /app-tmp \
 	&& chmod a+rwX /app-tmp \
 	&& rm -f /etc/php-fpm.d/* 
 	
ADD conf/php.ini $PHP_INI_DIR/php.ini
ADD conf/php-fpm.conf $PHP_INI_DIR/php-fpm.conf
ADD conf/fpm-host.conf /etc/php-fpm.d/pboxx.conf
ADD conf/nginx.conf /etc/nginx/nginx.conf
ADD conf/nginx-host.conf /etc/nginx/sites-available/pboxx.conf
ADD conf/supervisord.conf /etc/supervisord.conf
ADD conf/logrotate.conf /etc/logrotate.d/rotatelogs.conf

ADD ./scripts /scripts
ADD ./tests /tests

RUN mkdir /app-crt
WORKDIR /app-crt

#create ca key and cert
RUN openssl req -x509 -sha256 -nodes -days 3650 -newkey rsa:2048 -keyout /app-crt/ca.key -out /app-crt/ca.crt  -subj "/C=CA/ST=Toronto/O=Parking Boxx/OU=EU/CN=Parking Boxx CA 10 years/emailAddress=admin@parkingboxx.com/" \
#Create one year Server Key, CSR, and Self Signed Certificate
	&& openssl req -x509 -sha256 -nodes -days 3650 -newkey rsa:2048 -keyout /app-crt/server.key -out /app-crt/server.crt -subj "/C=CA/ST=Toronto/O=Parking Boxx/OU=Sync Server/CN=dev-sync.parkingboxx.com/emailAddress=admin@parkingboxx.com/" \
#create client certificate
	&& openssl req -x509 -sha256 -nodes -days 3650 -newkey rsa:2048 -keyout /app-crt/client-ca.key -out /app-crt/client-ca.crt  -subj "/C=CA/ST=Toronto/O=Parking Boxx/OU=EU/CN=Client Parking Boxx CA 10 years/emailAddress=admin@parkingboxx.com/" \
	&& cat ./server.crt ./ca.crt > ./all.crt

        
WORKDIR /root

# Add Scripts
ADD scripts/start.sh /start.sh
ADD scripts/pull /usr/bin/pull
ADD scripts/push /usr/bin/push
ADD scripts/letsencrypt-setup /usr/bin/letsencrypt-setup
ADD scripts/letsencrypt-renew /usr/bin/letsencrypt-renew

RUN touch crontab.tmp \
    && echo '15    1       *       *       *       logrotate --force /etc/logrotate.conf' > /root/crontab.tmp \ 
    && crontab -u root /root/crontab.tmp \
    && rm -rf /root/crontab.tmp \
	&& chmod 755 /usr/bin/pull \
  && chmod 755 /usr/bin/push \
  && chmod 755 /usr/bin/letsencrypt-setup \
  && chmod 755 /usr/bin/letsencrypt-renew \
  && chmod 755 /start.sh \
  && rm -f  /etc/logrotate.d/acpid \
  && rm -f  /etc/logrotate.d/supervisord \
  && chmod 0644  /etc/logrotate.d/rotatelogs.conf \
  && mkdir /app-crt-aws \
  && wget  https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem -O /app-crt-aws/rds-combined-ca-bundle.pem \
  && mkdir /webapp \
        && VERSTR="<?php\n\$config['version'] = '%s';\n\$config['copyright'] = 'Parking BOXX Corp. 2019';\n\$config['app-name'] = 'Parking BOXX – PHP 5.3 Server App ';\n\$config['build-date'] = '%s';\n?>\n" \
		&& GITVERS=unknown \
        && BUILDDATE=$(date) \
        && printf "$VERSTR" "$GITVERS" "$BUILDDATE">/webapp/version.php \
		&& printf "<html><body><h2>The docker was assembled on $BUILDDATE</h2></body></html>">/webapp/index.php \
		&& chmod a+rx /start.sh \
    && chmod 0444 /etc/logrotate.d/rotatelogs.conf \
    && chmod 0444 /etc/logrotate.conf \
    && touch /var/log/messages
    

EXPOSE 80 443
CMD ["/start.sh"]



ENTRYPOINT ["docker-php-entrypoint"]
##<autogenerated>##
CMD ["php", "-a"]
##</autogenerated>##
