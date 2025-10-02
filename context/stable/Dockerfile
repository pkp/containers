# Default build arguments
ARG PKP_CODE_BASE_IMAGE=alpine:3.22 # Base image used for pkp_code stage
ARG PHP_BASE_IMAGE=php:8.2-apache   # Web server and PHP version

ARG PKP_TOOL=ojs                    # Options are: ojs, omp, ops
ARG PKP_VERSION=3_5_0-1             # Same as PKP's versions

ARG PKP_VERSION_SHORT="${PKP_VERSION//_/.}"

# Stage 1: Download PKP source code from released tarball
FROM ${PKP_CODE_BASE_IMAGE:-alpine:3.22} AS pkp_code

ARG PKP_TOOL
ARG PKP_VERSION_SHORT

RUN apk add --no-cache curl tar && \
  mkdir -p "/opt/${PKP_TOOL}" && \
  cd "/opt/${PKP_TOOL}" && \
  curl -sSL -O "https://pkp.sfu.ca/${PKP_TOOL}/download/${PKP_TOOL}-${PKP_VERSION_SHORT}.tar.gz" && \
  tar --strip-components=1 -xzf "${PKP_TOOL}-${PKP_VERSION_SHORT}.tar.gz" && \
  rm ${PKP_TOOL}-${PKP_VERSION_SHORT}.tar.gz


# Stage 2: Build PHP extensions and dependencies
FROM ${PHP_BASE_IMAGE:-php:8.2-apache} AS pkp_build

RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends \
  curl \
  unzip \
  ca-certificates \
  build-essential \
  \
  libzip-dev \
  libpng-dev \
  libjpeg62-turbo-dev \
  libwebp-dev \
  libxml2-dev \
  libxslt-dev \
  libfreetype6-dev \
  \
  libavif-dev \
  \
  libxpm-dev \
  libfontconfig1-dev \
  \
  libpq-dev && \
  \
  curl -sSLf https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions \
  -o /usr/local/bin/install-php-extensions && \
  chmod +x /usr/local/bin/install-php-extensions && \
  install-php-extensions \
  gd \
  \
  gettext \
  intl \
  \
  mbstring \
  \
  mysqli \
  pdo_mysql \
  \
  pgsql \
  pdo_pgsql \
  \
  xml \
  xsl \
  \
  zip \
  \
  bcmath \
  ftp && \
  \
  apt-get purge -y --auto-remove build-essential && \
  rm -rf /var/lib/apt/lists/*


# Stage 3: Final lightweight image
FROM ${PHP_BASE_IMAGE:-php:8.2-apache}

ARG PKP_TOOL
ARG PKP_VERSION
ARG PHP_BASE_IMAGE

# Updates the OS and Installs required apps and runtime libraries
RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y \
  cron \
  poppler-utils \
  ghostscript \
  antiword \
  \
  libxml2 \
  libxslt1.1 \
  libicu-dev \
  libzip-dev \
  \
  libjpeg62-turbo \
  libpng16-16 \
  libfreetype6 \
  libonig-dev \
  libavif-dev \
  libwebp-dev \
  \
  libxpm4 \
  libfontconfig1 \
  libx11-6 \
  \
  libpq5 && \
  \
  apt-get purge -y --auto-remove build-essential && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*


# Copy PHP extensions and configs from build stage
COPY --from=pkp_build /usr/local/lib/php/extensions /usr/local/lib/php/extensions
COPY --from=pkp_build /usr/local/etc/php/conf.d /usr/local/etc/php/conf.d
COPY --from=pkp_build /usr/local/bin/install-php-extensions /usr/local/bin/install-php-extensions

# Set working directory
WORKDIR /var/www/html

# Copy source code and configuration files
COPY --from=pkp_code "/opt/${PKP_TOOL}" .
COPY --chmod=755 bin/ /usr/local/bin/
COPY etc/apache2/pkp.conf /etc/apache2/conf-enabled/pkp.conf
COPY etc/php/custom.ini /usr/local/etc/php/conf.d/

# Final configuration steps:
# - Enable apache modules (rewrite, ssl)
# - Redirect errors to stderr
# - Set a config.inc.php
# - Add pkp-run-sheduled to crontab
# - Set certificates
# - Create container.version file
RUN a2enmod rewrite && \
  rm /etc/apache2/sites-enabled/000-default.conf && \
  sed -e 's/^Listen 80$/Listen 8080/' -i /etc/apache2/ports.conf && \
  mkdir -p /var/www/files /run/apache2 && \
  \
  echo "log_errors = On" >> /usr/local/etc/php/conf.d/log-errors.ini && \
  echo "error_log = /dev/stderr" >> /usr/local/etc/php/conf.d/log-errors.ini && \
  \
  chown -R www-data:www-data /var/www && \
  \
  echo "0 * * * *   pkp-run-scheduled" | crontab - && \
  \
  sed -i -e '\#<Directory />#,\#</Directory>#d' /etc/apache2/apache2.conf && \
  sed -i -e "s/^ServerSignature.*/ServerSignature Off/" /etc/apache2/apache2.conf && \
  \
  . /etc/os-release && \
  echo "${PKP_TOOL}-${PKP_VERSION} with ${PHP_BASE_IMAGE} on ${ID}-${VERSION_ID} [build: $(date +%Y%m%d-%H%M%S)]" \
  > "/version"

# Expose web ports and declare volumes
EXPOSE 8080

VOLUME [ "/var/www/files", "/var/www/public" ]

# Changing to a rootless user
USER www-data

# Default start command
CMD ["/usr/local/bin/pkp-start"]
