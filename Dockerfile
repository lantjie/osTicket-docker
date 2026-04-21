FROM php:8.2-apache-bookworm

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        unzip \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libicu-dev \
        libc-client-dev \
        libkrb5-dev \
        libxml2-dev \
        libzip-dev \
        libonig-dev \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install -j"$(nproc)" \
        gd \
        imap \
        intl \
        mysqli \
        mbstring \
        opcache \
        zip \
        xml \
        dom \
    && pecl install apcu \
    && docker-php-ext-enable apcu

RUN a2enmod rewrite headers expires \
    && echo "ServerName localhost" >> /etc/apache2/apache2.conf \
    && sed -ri 's!<Directory /var/www/>.*?AllowOverride None!<Directory /var/www/>\n\tOptions FollowSymLinks\n\tAllowOverride All!' /etc/apache2/apache2.conf || true \
    && printf '<Directory /var/www/html>\n\tAllowOverride All\n\tRequire all granted\n</Directory>\n' > /etc/apache2/conf-available/osticket.conf \
    && a2enconf osticket

RUN cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

RUN printf 'upload_max_filesize=25M\n\
post_max_size=26M\n\
memory_limit=256M\n\
max_execution_time=120\n\
date.timezone=UTC\n\
session.cookie_httponly=1\n\
session.cookie_secure=1\n\
' > /usr/local/etc/php/conf.d/osticket.ini

COPY upload/ /var/www/html/
COPY scripts/ /opt/osticket-scripts/

# Seed ost-config.php from the sample so the installer can write to it on first run.
# After install completes, chmod 0644 it (see README / deploy docs).
RUN if [ ! -f /var/www/html/include/ost-config.php ]; then \
        cp /var/www/html/include/ost-sampleconfig.php /var/www/html/include/ost-config.php; \
    fi \
    && chown -R www-data:www-data /var/www/html \
    && chmod 0666 /var/www/html/include/ost-config.php

EXPOSE 80
