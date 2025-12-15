#!/bin/sh

# Stop if error
set -e

# Get secrets shhhhhh
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/mysql_root_password)
MYSQL_PASSWORD=$(cat /run/secrets/mysql_password)

# Check mandatory environnement variable
if [ -z "$MYSQL_ROOT_PASSWORD" ] || [ -z "$MYSQL_DATABASE" ] || [ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASSWORD" ]; then
	echo "Missing required environment variables."
	echo "Must provide: MYSQL_ROOT_PASSWORD, MYSQL_DATABASE, MYSQL_USER, MYSQL_PASSWORD"
	exit 1
fi

# If MariaDB isnt already initialized (check for a specific marker file)
if [ ! -f "/var/lib/mysql/.initialized" ]; then
	echo "Initializing MariaDB..."

	# Change directory ownership for mysql user
	chown -R mysql:mysql /var/lib/mysql

	# Create default MySQL tables
	mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

	echo "Creating database and user..."

	# Bootstrap MariaDB for initial configuration
	mysqld --user=mysql --datadir=/var/lib/mysql --bootstrap <<EOF
FLUSH PRIVILEGES;

ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';

FLUSH PRIVILEGES;
EOF

	# Create marker file to indicate initialization is complete
	touch /var/lib/mysql/.initialized

	echo "MariaDB initialized."
fi

echo "Starting MariaDB..."
exec mysqld --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0
