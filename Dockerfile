ARG PHP_VERSION

FROM php:${PHP_VERSION}-fpm as base_php

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    apt-get install -y --no-install-recommends libmemcached-dev && \
    apt-get install -y --no-install-recommends libz-dev && \
    apt-get install -y --no-install-recommends libjpeg-dev && \
    apt-get install -y --no-install-recommends libpng-dev && \
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
    apt-get install -y --no-install-recommends libxext6


ARG ENABLE_LIBREOFFICE_WRITER=0
RUN if [ ${ENABLE_LIBREOFFICE_WRITER} = 1 ] ; then \
    mkdir -p /usr/share/man/man1 \
    && mkdir -p /.cache/dconf && chmod -R 777 /.cache/dconf \
    && apt-get update \
    && apt-get install -y --no-install-recommends openjdk-11-jre-headless \
    && apt-get install -y --no-install-recommends libreoffice-writer \
    && apt-get install -y --no-install-recommends libreoffice-java-common \
    && apt-get install -y --no-install-recommends pandoc ; \
fi;


ARG ENABLE_BACKUP_TOOLS=0
RUN if [ ${ENABLE_BACKUP_TOOLS} = 1 ] ; then \
    apt-get update \
    && apt-get install -y --no-install-recommends default-mysql-client ; \
fi;


RUN docker-php-ext-install pdo_mysql && \
    docker-php-ext-install mysqli && \
    docker-php-ext-install pcntl && \
    docker-php-ext-install zip && \
    docker-php-ext-install soap && \
    docker-php-ext-install exif


RUN pecl install -o -f redis && \ 
    rm -rf /tmp/pear && \
    docker-php-ext-enable redis


RUN docker-php-ext-configure gd -with-freetype=/usr/include/ --with-jpeg=/usr/include/ && \
    docker-php-ext-install gd

RUN mkdir -p /.config/psysh && chmod -R 777 /.config/psysh


ARG PRODUCTION=0
RUN if [ ${PRODUCTION} = 1 ] ; then \
        mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini" && \
        sed -e 's/max_execution_time = 30/max_execution_time = 600/' -i "$PHP_INI_DIR/php.ini" && \
        sed -e 's/memory_limit = 128M/memory_limit = 2G/' -i "$PHP_INI_DIR/php.ini" && \
        sed -e 's/;max_input_nesting_level = 64/max_input_nesting_level = 256/' -i "$PHP_INI_DIR/php.ini" && \
        sed -e 's/;max_input_vars = 1000/max_input_vars = 10000/' -i "$PHP_INI_DIR/php.ini" && \
        sed -e 's/post_max_size = 8M/post_max_size = 2G/' -i "$PHP_INI_DIR/php.ini" && \
        sed -e 's/upload_max_filesize = 2M/upload_max_filesize = 2G/' -i "$PHP_INI_DIR/php.ini" && \
        sed -e 's/max_file_uploads = 20/max_file_uploads = 1000/' -i "$PHP_INI_DIR/php.ini" && \
        sed -e 's/pm\.max_children = 5/pm\.max_children = 50/' -i "/usr/local/etc/php-fpm.d/www.conf.default" && \
        sed -e 's/pm\.max_children = 5/pm\.max_children = 50/' -i "/usr/local/etc/php-fpm.d/www.conf" ; \
    else \
        mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" && \
        sed -e 's/max_execution_time = 30/max_execution_time = 600/' -i "$PHP_INI_DIR/php.ini" && \
        sed -e 's/memory_limit = 128M/memory_limit = 2G/' -i "$PHP_INI_DIR/php.ini" && \
        sed -e 's/;max_input_nesting_level = 64/max_input_nesting_level = 256/' -i "$PHP_INI_DIR/php.ini" && \
        sed -e 's/;max_input_vars = 1000/max_input_vars = 10000/' -i "$PHP_INI_DIR/php.ini" && \
        sed -e 's/post_max_size = 8M/post_max_size = 2G/' -i "$PHP_INI_DIR/php.ini" && \
        sed -e 's/upload_max_filesize = 2M/upload_max_filesize = 2G/' -i "$PHP_INI_DIR/php.ini" && \
        sed -e 's/max_file_uploads = 20/max_file_uploads = 1000/' -i "$PHP_INI_DIR/php.ini" && \
        sed -e 's/pm\.max_children = 5/pm\.max_children = 50/' -i "/usr/local/etc/php-fpm.d/www.conf.default" && \
        sed -e 's/pm\.max_children = 5/pm\.max_children = 50/' -i "/usr/local/etc/php-fpm.d/www.conf" ; \
    fi;
    


FROM base_php as fpm
ARG PRODUCTION=0
RUN if [ ${PRODUCTION} = 0 ] ; then \
        apt-get install -y --no-install-recommends fswatch ; \
    fi;
    
    
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
        else \
            pecl install pcov && \
            docker-php-ext-enable pcov && \
            pecl install xdebug && \
            echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini && \
            echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/xdebug.ini && \
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



FROM base_php as scheduler
COPY ./scripts/start_schedule.sh /usr/local/bin/start
RUN chmod 777 /usr/local/bin/start
CMD ["/usr/local/bin/start"]



FROM base_php as composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN mkdir -p /.composer/cache && chmod -R 777 /.composer/cache




FROM composer as tester
RUN apt-get -y install curl gnupg
RUN curl -sL https://deb.nodesource.com/setup_14.x  | bash -
RUN apt-get -y install nodejs
