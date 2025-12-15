# Import stable Debian base image (Bookworm)
FROM debian:12

# Skip interactivity (timezone, etc)
ENV DEBIAN_FRONTEND=noninteractive

# Install PHP and wget for Adminer
RUN apt-get update && \
	apt-get install -y \
		php8.2 \
		php8.2-mysqli \
		wget \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# Create directory for Adminer
RUN mkdir -p /var/www/html

# Download latest Adminer
RUN wget -O /var/www/html/index.php https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1-mysql.php

# Adminer listening ports 8080
EXPOSE 8080

# Start PHP built-in server
CMD ["php", "-S", "0.0.0.0:8080", "-t", "/var/www/html"]
