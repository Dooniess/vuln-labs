# Image Joomla construite depuis l'archive officielle GitHub.
#
# Compatibilité CLI d'installation (installation/joomla.php) :
#   3.x, 4.0.x, 4.1.x, 4.2.x -> PAS de CLI (wizard navigateur)
#   4.3.x, 4.4.x               -> CLI disponible (install automatique)
#
# Versions disponibles sur GitHub Releases :
#   3.x  : jusqu'à 3.10.12
#   4.x  : 4.0.0-4.0.6, 4.1.0/4.1.2-4.1.5, 4.2.0-4.2.9,
#           4.3.0-4.3.4, 4.4.0-4.4.9
#   (4.1.1, 4.2.10+, 4.3.5-4.3.6 n'existent pas)
#
# Compatibilités PHP :
#   Joomla 3.x       -> PHP 7.4
#   Joomla 4.0-4.2   -> PHP 8.1
#   Joomla 4.3-4.4   -> PHP 8.1 ou 8.2

ARG PHP_VERSION=8.1
FROM php:${PHP_VERSION}-apache

ARG JOOMLA_VERSION
RUN test -n "$JOOMLA_VERSION" || \
    { echo "ERREUR: JOOMLA_VERSION requis en build-arg"; exit 1; }

RUN apt-get update && apt-get install -y --no-install-recommends \
      libpng-dev libjpeg-dev libfreetype6-dev \
      libicu-dev libzip-dev libbz2-dev libonig-dev \
      curl ca-certificates bzip2 \
 && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j"$(nproc)" \
      gd intl zip bz2 mysqli opcache mbstring

# Toutes les versions 3.x et 4.x utilisent le format tar.bz2
RUN curl -fSL \
      "https://github.com/joomla/joomla-cms/releases/download/${JOOMLA_VERSION}/Joomla_${JOOMLA_VERSION}-Stable-Full_Package.tar.bz2" \
      -o /tmp/joomla.tar.bz2 \
 && tar -xjf /tmp/joomla.tar.bz2 -C /var/www/html \
 && rm /tmp/joomla.tar.bz2 \
 && chown -R www-data:www-data /var/www/html

RUN { \
      echo "memory_limit=256M"; \
      echo "upload_max_filesize=20M"; \
      echo "post_max_size=20M"; \
      echo "max_execution_time=120"; \
    } > /usr/local/etc/php/conf.d/joomla.ini

RUN a2enmod rewrite \
 && sed -ri 's!AllowOverride None!AllowOverride All!g' /etc/apache2/apache2.conf
