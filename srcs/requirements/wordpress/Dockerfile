# Import stable Debian base image (Bookworm)
FROM debian:12

# Skip interactivity (timezone, etc)
ENV DEBIAN_FRONTEND=noninteractive

# Update packages & install PHP-FPM + extension needed for WordPress
# # fpm PHP fastCGI Process Manager (for Nginx)
# # mysql extension for MariaDB connection
# # curl / gd extension require by WordPress
# # intl extension international character
# # mbstring extension for no ASCII character
# # xml extension form usage of xml files
# # zip extension for usage of zip files
# # wget for download WP-CLI
# # ca-certificates for HTTPS
RUN apt-get update && \
	apt-get install -y \
	php8.2-fpm \
	php8.2-mysql \
	php8.2-curl \
	php8.2-gd \
	php8.2-intl \
	php8.2-mbstring \
	php8.2-xml \
	php8.2-zip \
	wget \
	mariadb-client \
	ca-certificates && \
	rm -rf /var/lib/apt/lists/*

# Install WP-CLI (WordPress Command Line Interface)
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
	chmod +x wp-cli.phar && \
	mv wp-cli.phar /usr/local/bin/wp

# Create directory for PHP-FPM socket and set permissions
RUN mkdir -p /run/php && \
	chown -R www-data:www-data /run/php

# Configure PHP-FPM to listen on port 9000 on all interfaces
RUN sed -i 's|listen = /run/php/php8.2-fpm.sock|listen = 0.0.0.0:9000|g' /etc/php/8.2/fpm/pool.d/www.conf

# Copy install script to entrypoint
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

# Chmod on entrypoint.sh (executable)
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set working directory
WORKDIR /var/www/html

# PHP-FPM listening on 9000 port
EXPOSE 9000

# Declare entry point
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
