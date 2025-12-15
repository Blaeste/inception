# Import stable Debian base image (Bookworm)
FROM debian:12

# Skip interactivity (timezone, etc)
ENV DEBIAN_FRONTEND=noninteractive

# Update packages & install Nginx and OpenSSL
# # Nginx web server
# # openssl generate certificats
RUN apt-get update && \
    apt-get install -y \
    nginx \
	openssl && \
	rm -rf /var/lib/apt/lists/*

# Generate self-signed SSL certificate (650 days validitie)
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-keyout /etc/ssl/private/nginx.key \
	-out /etc/ssl/certs/nginx.crt \
	-subj "/C=FR/ST=Paris/L=Paris/O=42/OU=42/CN=eschwart.42.fr"

# Copy Nginx configuration
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Nginx listening on 443 HTTPS port
EXPOSE 443

# Declare entry point
CMD ["nginx", "-g", "daemon off;"]
