ARG PHP_VERSION

FROM php:${PHP_VERSION}-fpm-alpine as base_php


RUN apt-get update
RUN apt-get install -y --no-install-recommends curl
RUN apt-get install -y --no-install-recommends libmemcached-dev
RUN apt-get install -y --no-install-recommends libz-dev
RUN apt-get install -y --no-install-recommends libjpeg-dev
RUN apt-get install -y --no-install-recommends libpng-dev
RUN apt-get install -y --no-install-recommends libssl-dev
RUN apt-get install -y --no-install-recommends libmcrypt-dev
RUN apt-get install -y --no-install-recommends nano
RUN apt-get install -y --no-install-recommends cron
RUN apt-get install -y --no-install-recommends git
RUN apt-get install -y --no-install-recommends unzip
RUN apt-get install -y --no-install-recommends libzip-dev
RUN apt-get install -y --no-install-recommends libfreetype6-dev
RUN apt-get install -y --no-install-recommends libjpeg62-turbo-dev
RUN apt-get install -y --no-install-recommends libxml2-dev
RUN apt-get install -y --no-install-recommends libxrender1
RUN apt-get install -y --no-install-recommends libfontconfig1
RUN apt-get install -y --no-install-recommends libxext6


ARG ENABLE_LIBREOFFICE_WRITER=0
RUN if [ ${ENABLE_LIBREOFFICE_WRITER} = 1 ] ; then \
    mkdir -p /usr/share/man/man1 \
    && mkdir -p /.cache/dconf && chmod -R 777 /.cache/dconf \
    && apt-get update \
    && apt-get install -y --no-install-recommends openjdk-11-jre-headless \
    && apt-get install -y --no-install-recommends libreoffice-writer \
    && apt-get install -y --no-install-recommends libreoffice-java-common ;\
fi;


RUN docker-php-ext-install pdo_mysql
RUN docker-php-ext-install mysqli
RUN docker-php-ext-install pcntl
RUN docker-php-ext-install zip
RUN docker-php-ext-install soap
RUN docker-php-ext-install exif


RUN pecl install -o -f redis \
&&  rm -rf /tmp/pear \
&&  docker-php-ext-enable redis


RUN docker-php-ext-configure gd -with-freetype=/usr/include/ --with-jpeg=/usr/include/
RUN docker-php-ext-install gd

RUN mkdir -p /.config/psysh && chmod -R 777 /.config/psysh

RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
RUN sed -e 's/max_execution_time = 30/max_execution_time = 600/' -i "$PHP_INI_DIR/php.ini"
RUN sed -e 's/memory_limit = 128M/memory_limit = 2G/' -i "$PHP_INI_DIR/php.ini"
RUN sed -e 's/;max_input_nesting_level = 64/max_input_nesting_level = 256/' -i "$PHP_INI_DIR/php.ini"
RUN sed -e 's/;max_input_vars = 1000/max_input_vars = 10000/' -i "$PHP_INI_DIR/php.ini"
RUN sed -e 's/post_max_size = 8M/post_max_size = 2G/' -i "$PHP_INI_DIR/php.ini"
RUN sed -e 's/upload_max_filesize = 2M/upload_max_filesize = 2G/' -i "$PHP_INI_DIR/php.ini"



FROM base_php as php
ARG ENABLE_XDEBUG=0
RUN if [ ${ENABLE_XDEBUG} = 1 ] ; then \
    pecl install xdebug \
    && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.client_port=9000" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.discover_client_host=1" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.idekey='PHPSTORM'" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.log_level=0" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && docker-php-ext-enable xdebug ;\
fi;





FROM base_php as websocket
COPY ./scripts/start_websocket.sh /usr/local/bin/start
RUN chmod 777 /usr/local/bin/start
CMD ["/usr/local/bin/start"]



FROM base_php as worker
COPY ./scripts/start_worker.sh /usr/local/bin/start
RUN chmod 777 /usr/local/bin/start
CMD ["/usr/local/bin/start"]



FROM base_php as scheduler
COPY ./scripts/start_schedule.sh /usr/local/bin/start
RUN chmod 777 /usr/local/bin/start
CMD ["/usr/local/bin/start"]



FROM base_php as composer
COPY --from=composer /usr/bin/composer /usr/bin/composer
RUN mkdir -p /.composer/cache && chmod -R 777 /.composer/cache




FROM composer as tester
RUN apt-get -y install curl gnupg
RUN curl -sL https://deb.nodesource.com/setup_14.x  | bash -
RUN apt-get -y install nodejs
