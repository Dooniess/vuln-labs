# Image GLPI construite depuis l'archive officielle, pour tester N'IMPORTE QUELLE
# version (y compris anciennes, absentes des images Docker officielles).
#
# Deux paramètres de build (fournis par docker-compose depuis le .env) :
#   - GLPI_VERSION : version à installer (ex. 9.5.11, 10.0.6)
#   - PHP_VERSION  : version de PHP de base (défaut 7.4)
#
# Compatibilités PHP (à respecter via PHP_VERSION) :
#   GLPI 9.5.x        -> PHP 7.2 à 7.4   (utiliser 7.4)
#   GLPI 10.0.0-10.0.5-> PHP 7.4 à 8.1
#   GLPI 10.0.6+      -> PHP 7.4 à 8.2/8.3
#   GLPI 11.0.x       -> PHP 8.2+  (mais l'image officielle existe : préférez-la)

ARG PHP_VERSION=7.4
FROM php:${PHP_VERSION}-apache

ARG GLPI_VERSION
RUN test -n "$GLPI_VERSION" || { echo "ERREUR: build-arg GLPI_VERSION requis"; exit 1; }

# Dépendances système des extensions PHP requises par GLPI
RUN apt-get update && apt-get install -y --no-install-recommends \
      libpng-dev libjpeg-dev libfreetype6-dev \
      libicu-dev libzip-dev libbz2-dev libldap2-dev libonig-dev libxml2-dev \
      curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Extensions PHP.
# NB : les flags gd ci-dessous sont ceux de PHP >= 7.4. Pour GLPI <= 9.4
# (PHP <= 7.3), remplacer par :
#   docker-php-ext-configure gd --with-freetype-dir --with-jpeg-dir --with-png-dir
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-configure ldap --with-libdir=lib/$(uname -m)-linux-gnu \
 && docker-php-ext-install -j"$(nproc)" \
      gd intl zip bz2 ldap mysqli exif opcache mbstring

# Récupération + extraction de la version demandée dans le docroot Apache
RUN curl -fSL "https://github.com/glpi-project/glpi/releases/download/${GLPI_VERSION}/glpi-${GLPI_VERSION}.tgz" \
      -o /tmp/glpi.tgz \
 && tar -xzf /tmp/glpi.tgz -C /var/www/html --strip-components=1 \
 && rm /tmp/glpi.tgz \
 && chown -R www-data:www-data /var/www/html

# Apache : activer la réécriture et autoriser les .htaccess de GLPI
RUN a2enmod rewrite \
 && sed -ri 's!AllowOverride None!AllowOverride All!g' /etc/apache2/apache2.conf

# Réglages PHP conseillés par GLPI
RUN { \
      echo "memory_limit=256M"; \
      echo "upload_max_filesize=20M"; \
      echo "post_max_size=20M"; \
      echo "max_execution_time=120"; \
      echo "session.cookie_httponly=On"; \
    } > /usr/local/etc/php/conf.d/glpi.ini
