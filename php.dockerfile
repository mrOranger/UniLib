# Used for prod build.
FROM php:8.3-fpm as php

# OpCache environment variables
ENV PHP_OPCACHE_ENABLE=1
ENV PHP_OPCACHE_ENABLE_CLI=0
ENV PHP_OPCACHE_VALIDATE_TIMESTAMPS=0
ENV PHP_OPCACHE_REVALIDATE_FREQ=0
ENV PHP_OPCACHE_MEMORY_CONSUMPTION=128

# XDebug environment variables
ENV XDEBUG_MODE=debug
ENV XDEBUG_START_WITH_REQUEST=yes
ENV XDEBUG_CLIENT_HOST=host.docker.internal
ENV XDEBUG_REMOTE_ENABLE=on
ENV XDEBUG_REMOTE_AUTOSTART=on
ENV XDEBUG_IDEKEY=VSCODE
ENV XDEBUG_CLIENT_PORT=9003

RUN usermod -u 1000 www-data

RUN apt-get update -y
RUN apt-get install -y unzip libpq-dev libcurl4-gnutls-dev nginx libonig-dev
RUN docker-php-ext-install mysqli pdo pdo_mysql bcmath curl opcache mbstring
RUN pecl install -o -f redis \
      && pecl install xdebug \
      && rm -rf /tmp/pear \
      && docker-php-ext-enable redis \
      && docker-php-ext-enable xdebug

# Copy configuration files.
COPY ./unilib/docker/config/php/php.ini /usr/local/etc/php/php.ini
COPY ./unilib/docker/config/php/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf
COPY ./unilib/docker/config/nginx/nginx.conf /etc/nginx/nginx.conf

# Set working directory to /var/www.
WORKDIR /var/www

# Copy files from current folder to container current folder (set in workdir).
COPY --chown=www-data:www-data unilib .

# Create laravel caching folders.
RUN mkdir -p /var/www/storage/framework
RUN mkdir -p /var/www/storage/framework/cache
RUN mkdir -p /var/www/storage/framework/testing
RUN mkdir -p /var/www/storage/framework/sessions
RUN mkdir -p /var/www/storage/framework/views

# Fix files ownership.
RUN chown -R www-data /var/www/storage
RUN chown -R www-data /var/www/storage/framework
RUN chown -R www-data /var/www/storage/framework/sessions

# Set correct permission.
RUN chmod -R 755 /var/www/storage
RUN chmod -R 755 /var/www/storage/logs
RUN chmod -R 755 /var/www/storage/framework
RUN chmod -R 755 /var/www/storage/framework/sessions
RUN chmod -R 755 /var/www/bootstrap

# Adjust user permission & group
RUN usermod --uid 1000 www-data
RUN groupmod --gid 1001 www-data

ENTRYPOINT [ "docker/entrypoint.sh" ]