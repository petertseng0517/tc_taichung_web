FROM php:7.4-apache

RUN apt-get update && apt-get install -y \
        libpng-dev \
        libjpeg-dev \
        libfreetype6-dev \
        libzip-dev \
        zip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install mysqli pdo_mysql gd zip \
    && a2enmod rewrite \
    && chown -R www-data:www-data /var/www/html \
    && rm -rf /var/lib/apt/lists/*
