# Default build arguments (modify .env instead when "docker compose build")
ARG BUILD_PKP_TOOL=ojs                     # Options are: ojs, omp, ops.
ARG BUILD_PKP_VERSION=3_3_0-21             # Same as PKP's versions.
ARG BUILD_PKP_APP_OS=alpine:3.22           # OS used to build (not run).  
ARG BUILD_PKP_APP_PATH=/app                # Where app is built.
ARG BUILD_WEB_SERVER=php:8.2-apache        # Web server and PHP version
ARG BUILD_LABEL=notset


# Stage 1: Download PKP source code from released tarball.
FROM ${BUILD_PKP_APP_OS} AS pkp_code

ARG BUILD_PKP_TOOL	    \
    BUILD_PKP_VERSION	\
    BUILD_PKP_APP_OS	\
    BUILD_PKP_APP_PATH

RUN apk add --no-cache curl tar && \
    mkdir -p "${BUILD_PKP_APP_PATH}" && \
    cd "${BUILD_PKP_APP_PATH}" && \
    pkpVersion="${BUILD_PKP_VERSION//_/.}" && \
    curl -sSL -O "https://pkp.sfu.ca/${BUILD_PKP_TOOL}/download/${BUILD_PKP_TOOL}-${pkpVersion}.tar.gz" && \
    tar --strip-components=1 -xzf "${BUILD_PKP_TOOL}-${pkpVersion}.tar.gz" && \
    rm ${BUILD_PKP_TOOL}-${pkpVersion}.tar.gz


# Stage 2: Build PHP extensions and dependencies
FROM ${BUILD_WEB_SERVER} AS pkp_build

# Packages needed to build PHP extensions
ENV PKP_DEPS="\
    # Basic tools
    curl \
    unzip \
    ca-certificates \
    build-essential \
    
    # PHP extension development libraries
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libwebp-dev \
    libonig-dev \
    libxml2-dev \
    libxslt1-dev \
    libfreetype6-dev \
    
    # Modern image formats support
    libavif-dev \
    
    # Graphics/X11 support
    libxpm-dev \
    libfontconfig-dev \

    # PostgreSQL development
    libpq-dev"

ENV PHP_EXTENSIONS="\
    # Image processing
    gd \
    
    # Internationalization
    gettext \
    intl \
    
    # String handling
    mbstring \

    # Database connectivity - MySQL/MariaDB
    mysqli \
    pdo_mysql \
    
    # Database connectivity - PostgreSQL
    pgsql \
    pdo_pgsql \
    
    # XML processing
    xml \
    xsl \
    
    # Compression
    zip \

    # PKP 3.5
    bcmath \
    ftp"

RUN apt-get update && \
    apt-get upgrade && \
    apt-get install -y --no-install-recommends $PKP_DEPS && \
    \
    curl -sSLf https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions \
    -o /usr/local/bin/install-php-extensions && \
    chmod +x /usr/local/bin/install-php-extensions && \
    install-php-extensions $PHP_EXTENSIONS && \
    \
    apt-get purge -y --auto-remove build-essential && \
    rm -rf /var/lib/apt/lists/*


# Stage 3: Final lightweight image
FROM ${BUILD_WEB_SERVER}

ARG BUILD_PKP_TOOL \
    BUILD_PKP_VERSION \
    BUILD_PKP_APP_PATH \
    BUILD_WEB_SERVER \
    BUILD_LABEL

LABEL maintainer="Public Knowledge Project <marc.bria@uab.es>"
LABEL org.opencontainers.image.vendor="Public Knowledge Project"
LABEL org.opencontainers.image.title="PKP ${BUILD_PKP_TOOL} Web Application"
LABEL org.opencontainers.image.version="${BUILD_PKP_VERSION}"
LABEL org.opencontainers.image.revision="${BUILD_PKP_TOOL}-${BUILD_PKP_VERSION}#${BUILD_LABEL}"
LABEL org.opencontainers.image.description="Runs a ${BUILD_PKP_TOOL} application over ${BUILD_WEB_SERVER} (with rootless support)."
LABEL io.containers.rootless="true"

# Environment variables:
# - WWW_USER will be automtically set to the propper webserver's user.
ENV SERVERNAME="localhost" \
    WWW_USER=$(getent passwd www-data apache nginx | cut -d: -f1 | head -n1) \
    WWW_PATH_CONF="/etc/apache2/apache2.conf" \
    WWW_PATH_ROOT="/var/www" \
    HTTPS="on" \
    PKP_TOOL="${BUILD_PKP_TOOL}" \
    PKP_VERSION="${BUILD_PKP_VERSION}" \
    PKP_CLI_INSTALL="0" \
    PKP_DB_HOST="${PKP_DB_HOST:-db}" \
    PKP_DB_NAME="${PKP_DB_NAME:-pkp}" \
    PKP_DB_USER="${PKP_DB_USER:-pkp}" \
    PKP_DB_PASSWORD="${PKP_DB_PASSWORD:-changeMePlease}" \
    PKP_WEB_CONF="/etc/apache2/conf-enabled/pkp.conf" \
    PKP_CONF="config.inc.php" \
    PKP_CMD="/usr/local/bin/pkp-start"

ENV PKP_RUNTIME_LIBS="\
    # Core libraries
    libxml2 \
    libxslt1.1 \
    libicu72 \
    libzip4 \
    
    # Image processing
    libjpeg62-turbo \
    libpng16-16 \
    libfreetype6 \
    libonig5 \
    libavif15 \
    libwebp7 \
    
    # Graphics/X11 support
    libxpm4 \
    libfontconfig1 \
    libx11-6 \

    # PostgreSQL runtime
    libpq5"

ENV PKP_APPS="\
    # If we like cron in the container (under discussion at #179)
    cron \

    # PDF support: pdf2text
    poppler-utils \

    # PostScript support: ps2acii
    ghostscript \

    # Word suport: antiword
    antiword "

# Updates the OS and Installs required apps and runtime libraries
RUN apt-get update && \
    apt-get upgrade && \
    apt-get install -y $PKP_APPS $PKP_RUNTIME_LIBS && \
    \
    apt-get purge -y --auto-remove build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


# Copy PHP extensions and configs from build stage
COPY --from=pkp_build /usr/local/lib/php/extensions /usr/local/lib/php/extensions
COPY --from=pkp_build /usr/local/etc/php/conf.d /usr/local/etc/php/conf.d
COPY --from=pkp_build /usr/local/bin/install-php-extensions /usr/local/bin/install-php-extensions

# Set working directory
WORKDIR ${WWW_PATH_ROOT}/html

# Copy source code and configuration files
COPY --from=pkp_code "${BUILD_PKP_APP_PATH}" .
COPY "templates/pkp/root/" /
COPY "volumes/config/apache.pkp.conf" "${PKP_WEB_CONF}"

# Final configuration steps
RUN a2enmod rewrite ssl && \
    mkdir -p /etc/ssl/apache2 "${WWW_PATH_ROOT}/files" /run/apache2 && \
    \
    echo "log_errors = On" >> /usr/local/etc/php/conf.d/log-errors.ini && \
    echo "error_log = /dev/stderr" >> /usr/local/etc/php/conf.d/log-errors.ini && \
    \
    cp -a config.TEMPLATE.inc.php "${PKP_CONF}" && \
    chown -R ${WWW_USER:-33}:${WWW_USER:-33} "${WWW_PATH_ROOT}" && \
    \
    echo "0 * * * *   pkp-run-scheduled" | crontab - && \
    \
    sed -i -e '\#<Directory />#,\#</Directory>#d' ${WWW_PATH_CONF} && \
    sed -i -e "s/^ServerSignature.*/ServerSignature Off/" ${WWW_PATH_CONF} && \
    \
    . /etc/os-release && \
    echo "${PKP_TOOL}-${PKP_VERSION} with ${BUILD_WEB_SERVER} over ${ID}-${VERSION_ID} [build: $(date +%Y%m%d-%H%M%S)]" \
        > "${WWW_PATH_ROOT}/container.version" && \
    cat "${WWW_PATH_ROOT}/container.version" && \
    \
    chmod +x "${PKP_CMD}"

# Expose web ports and declare volumes
EXPOSE ${HTTP_PORT:-8080}
EXPOSE ${HTTPS_PORT:-8443}

VOLUME [ "${WWW_PATH_ROOT}/files", "${WWW_PATH_ROOT}/public" ]

# Changing to a rootless user
USER ${WWW_USER:-33} 

# Default start command
CMD "${PKP_CMD}"
