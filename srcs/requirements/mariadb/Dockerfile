# Import stable Debian base image (Bookworm)
FROM debian:12

# Skip interactivity (timezone, etc)
ENV DEBIAN_FRONTEND=noninteractive

# Update packages & install MariaDB
RUN apt-get update && \
    apt-get install -y mariadb-server mariadb-client && \
    rm -rf /var/lib/apt/lists/*

# Ensure database directory exists and has correct permissions
RUN mkdir -p /var/lib/mysql && chown -R mysql:mysql /var/lib/mysql

# Create directory for MariaDB socket
RUN mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld

# Copy install script to entrypoint
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

# Chmod on entrypoint.sh (executable)
RUN chmod +x /usr/local/bin/entrypoint.sh

# MariaDB listening on 3306 port
EXPOSE 3306

# Declare entry point
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
