ARG PHP_VERSION

FROM php:${PHP_VERSION}-fpm-bullseye as base_php

ENV PHP_OPCACHE_VALIDATE_TIMESTAMPS="0" \
    PHP_OPCACHE_MAX_ACCELERATED_FILES="32531" \
    PHP_OPCACHE_MEMORY_CONSUMPTION="512" \
    PHP_OPCACHE_MAX_WASTED_PERCENTAGE="10" 

RUN apt-get update && \
    apt-get install -y --no-install-recommends procps && \
    apt-get install -y --no-install-recommends curl && \
    apt-get install -y --no-install-recommends wget && \
    apt-get install -y --no-install-recommends iputils-ping && \
    apt-get install -y --no-install-recommends libmemcached-dev && \
    apt-get install -y --no-install-recommends libz-dev && \
    apt-get install -y --no-install-recommends libjpeg-dev && \
    apt-get install -y --no-install-recommends libpng-dev && \
    apt-get install -y --no-install-recommends libwebp-dev && \
    apt-get install -y --no-install-recommends libssl-dev && \
    apt-get install -y --no-install-recommends libmcrypt-dev && \
    apt-get install -y --no-install-recommends nano && \
    apt-get install -y --no-install-recommends cron && \
    apt-get install -y --no-install-recommends git && \
    apt-get install -y --no-install-recommends unzip && \
    apt-get install -y --no-install-recommends libzip-dev && \
    apt-get install -y --no-install-recommends libfreetype6-dev && \
    apt-get install -y --no-install-recommends libjpeg62-turbo-dev && \
    apt-get install -y --no-install-recommends libxml2-dev && \
    apt-get install -y --no-install-recommends libxrender1 && \
    apt-get install -y --no-install-recommends libfontconfig1 && \
    apt-get install -y --no-install-recommends libxext6 && \
    apt-get install -y --no-install-recommends sqlite3 && \
    apt-get install -y --no-install-recommends lsb-release && \
    apt-get install -y --no-install-recommends libnss3      

RUN if [ "${PHP_VERSION}" = "7.2.14" ] ; then \
        echo 'no config' ; \
    elif [ "${PHP_VERSION}" = "7.0.33" ] ; then \
        echo 'no config' ; \
    else \
        apt install -y --no-install-recommends ca-certificates; \
    fi;


ARG ENABLE_LIBREOFFICE_WRITER=0
RUN if [ ${ENABLE_LIBREOFFICE_WRITER} = 1 ] ; then \
    mkdir -p /usr/share/man/man1 \
    && mkdir -p /.cache/dconf && chmod -R 777 /.cache/dconf \
    && apt update \
    && apt install -y --no-install-recommends openjdk-11-jre \
    && apt install -y --no-install-recommends libreoffice-writer \
    && apt install -y --no-install-recommends libreoffice-java-common \
    && apt install -y --no-install-recommends pandoc ; \
fi;


ARG ENABLE_BACKUP_TOOLS=0
RUN if [ ${ENABLE_BACKUP_TOOLS} = 1 ] ; then \
    apt update && \
    apt install -y --no-install-recommends mariadb-client; \
fi;


RUN docker-php-ext-install pdo_mysql && \
    docker-php-ext-install mysqli && \
    docker-php-ext-install pcntl && \
    docker-php-ext-install zip && \
    docker-php-ext-install soap && \
    docker-php-ext-install calendar && \
    docker-php-ext-install intl && \
    docker-php-ext-install gettext && \
    docker-php-ext-install exif 


ARG ENABLE_OPCACHE=0
RUN if [ ${ENABLE_OPCACHE} = 1 ] ; then \
    wget -O /usr/bin/cachetool.phar  https://github.com/gordalina/cachetool/releases/latest/download/cachetool.phar && \
    chmod +x /usr/bin/cachetoool.phar && \
    docker-php-ext-install opcache; \
fi;

RUN if [ "${PHP_VERSION}" = "5.6.40" ] ; then \
        echo 'no config' ; \
    else \
        pecl install -o -f redis && \
        rm -rf /tmp/pear && \
        docker-php-ext-enable redis ; \
    fi;

RUN if [ "${PHP_VERSION}" = "7.3.29" ] ; then \
        docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
        docker-php-ext-install gd ; \
    elif [ "${PHP_VERSION}" = "7.2.14" ] ; then \
        docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
        docker-php-ext-install gd ; \
    elif [ "${PHP_VERSION}" = "5.6.40" ] ; then \
        docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
        docker-php-ext-install gd ; \
    else \
        docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ --with-webp=/usr/include/ && \
        docker-php-ext-install gd ; \
    fi;
   

RUN mkdir -p /.config/psysh && chmod -R 777 /.config/psysh


COPY php-production.ini "$PHP_INI_DIR/php.ini-production"
COPY php-development.ini "$PHP_INI_DIR/php.ini-development"
COPY opcache.ini "$PHP_INI_DIR/conf.d/opcache.ini"

ARG PRODUCTION=0
RUN if [ ${PRODUCTION} = 1 ] ; then \
        if [ "${PHP_VERSION}" = "5.6.40" ] ; then \
            mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" ; \
        else \
           mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" && \
           sed -e 's/pm\.max_children = 5/pm\.max_children = 50/' -i "/usr/local/etc/php-fpm.d/www.conf.default" && \
           sed -e 's/pm\.max_children = 5/pm\.max_children = 50/' -i "/usr/local/etc/php-fpm.d/www.conf" ; \
        fi; \
    else \
        if [ "${PHP_VERSION}" = "5.6.40" ] ; then \
            mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini" ; \
        else \
           mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini" && \
           sed -e 's/pm\.max_children = 5/pm\.max_children = 50/' -i "/usr/local/etc/php-fpm.d/www.conf.default" && \
           sed -e 's/pm\.max_children = 5/pm\.max_children = 50/' -i "/usr/local/etc/php-fpm.d/www.conf" ; \
        fi; \
    fi;
    


FROM base_php as fpm    

ARG ENABLE_XDEBUG=0
RUN if [ ${ENABLE_XDEBUG} = 1 ] ; then \
        if [ "${PHP_VERSION}" = "7.0.33" ] ; then \
            pecl install xdebug-2.6.0 && \
            echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.default_enable=1" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.remote_enable=1" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.remote_handler=dbgp" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.remote_port=9000" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.remote_autostart=1" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.remote_connect_back=1" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.idekey='PHPSTORM'" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.profiler_enable_trigger=1" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.profiler_output_dir='/opt/profile'" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            docker-php-ext-enable xdebug ;\
        elif [ "${PHP_VERSION}" = "5.6.40" ] ; then \
            pecl install xdebug-2.5.0 && \
            echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.default_enable=1" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.remote_enable=1" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.remote_handler=dbgp" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.remote_port=9000" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.remote_autostart=1" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.remote_connect_back=1" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.idekey='PHPSTORM'" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.profiler_enable_trigger=1" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.profiler_output_dir='/opt/profile'" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            docker-php-ext-enable xdebug ;\
        elif [ "${PHP_VERSION}" = "7.3.29" ] ; then \
            pecl install xdebug-3.1.0 && \
            echo "zend_extension=xdebug" > /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.client_port=9000" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.discover_client_host=1" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.idekey='PHPSTORM'" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.log_level=0" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            docker-php-ext-enable xdebug ;\
        elif [ "${PHP_VERSION}" = "7.4.30" ] ; then \
            pecl install xdebug-3.1.0 && \
            echo "zend_extension=xdebug" > /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.client_port=9000" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.discover_client_host=1" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.idekey='PHPSTORM'" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.log_level=0" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            docker-php-ext-enable xdebug ;\
        elif [ "${PHP_VERSION}" = "7.2.14" ] ; then \
            pecl install xdebug-3.1.0 && \
            echo "zend_extension=xdebug" > /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.client_port=9000" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.discover_client_host=1" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.idekey='PHPSTORM'" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.log_level=0" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            docker-php-ext-enable xdebug ;\
        else \
            pecl install pcov && \
            docker-php-ext-enable pcov && \
            pecl install xdebug && \
            echo "zend_extension=xdebug" > /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.client_port=9000" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.discover_client_host=1" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.idekey='PHPSTORM'" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.log_level=0" >> /usr/local/etc/php/conf.d/xdebug.ini && \
            docker-php-ext-enable xdebug ;\
        fi; \
    fi;





FROM base_php as websocket
COPY ./scripts/start_websocket.sh /usr/local/bin/start
RUN chmod 777 /usr/local/bin/start
CMD ["/usr/local/bin/start"]



FROM base_php as worker
COPY ./scripts/start_worker.sh /usr/local/bin/start
RUN chmod 777 /usr/local/bin/start
CMD ["/usr/local/bin/start"]




FROM base_php as pulse
COPY ./scripts/start_pulse.sh /usr/local/bin/start
RUN chmod 777 /usr/local/bin/start
CMD ["/usr/local/bin/start"]



FROM base_php as scheduler
COPY ./scripts/start_schedule.sh /usr/local/bin/start
RUN chmod 777 /usr/local/bin/start
CMD ["/usr/local/bin/start"]



FROM base_php as composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN mkdir -p /.composer/cache && chmod -R 777 /.composer/cache
RUN pecl install pcov && docker-php-ext-enable pcov ;


FROM composer as tester
RUN apt -y install curl gnupg
RUN curl -sL https://deb.nodesource.com/setup_14.x  | bash -
RUN apt -y install nodejs
