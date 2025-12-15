# Import stable Debian base image (Bookworm)
FROM debian:12

# Skip interactivity (timezone, etc)
ENV DEBIAN_FRONTEND=noninteractive

# Install redis-server
RUN apt-get update && apt-get install -y redis-server && rm -rf /var/lib/apt/lists/*

# Configure Redis for listening on 0.0.0.0
RUN sed -i 's/bind 127.0.0.1/bind 0.0.0.0/g' /etc/redis/redis.conf

# Copy install script to entrypoint
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

# Chmod on entrypoint.sh (executable)
RUN chmod +x /usr/local/bin/entrypoint.sh

# Redis listening on 6379 port
EXPOSE 6379

# Declare entry point
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
