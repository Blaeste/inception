#!/bin/sh

# Stop if error
set -e

# Get secrets for WordPress shhhhhh
WORDPRESS_ADMIN_PASSWORD=$(cat /run/secrets/wordpress_admin_password)
WORDPRESS_DB_PASSWORD=$(cat /run/secrets/wordpress_db_password)
WORDPRESS_USER_PASSWORD=$(cat /run/secrets/wordpress_user_password)

# Get secrets for Redis shhhhhh
REDIS_PASSWORD=$(cat /run/secrets/redis_password)

# Check mandatory WordPress database environnement variable
if [ -z "$WORDPRESS_DB_HOST" ] || [ -z "$WORDPRESS_DB_NAME" ] || [ -z "$WORDPRESS_DB_USER" ] || [ -z "$WORDPRESS_DB_PASSWORD" ]; then
	echo "Missing required environment variables."
	echo "Must provide: WORDPRESS_DB_HOST, WORDPRESS_DB_NAME, WORDPRESS_DB_USER, WORDPRESS_DB_PASSWORD"
	exit 1
fi

# Check madatory WordPress admin environnement variable
if [ -z "$WORDPRESS_ADMIN_USER" ] || [ -z "$WORDPRESS_ADMIN_PASSWORD" ] || [ -z "$WORDPRESS_ADMIN_EMAIL" ]; then
	echo "Missing required environment variables."
	echo "Must provide: WORDPRESS_ADMIN_USER, WORDPRESS_ADMIN_PASSWORD, WORDPRESS_ADMIN_EMAIL"
	exit 1
fi

# Check madatory WordPress site environnement variable
if [ -z "$WORDPRESS_URL" ] || [ -z "$WORDPRESS_TITLE" ]; then
	echo "Missing required environment variables."
	echo "Must provide: WORDPRESS_URL, WORDPRESS_TITLE"
	exit 1
fi

# Check madatory Redis environnement variable
if [ -z "$REDIS_HOST" ] || [ -z "$REDIS_PORT" ] || [ -z "$REDIS_PASSWORD" ]; then
	echo "Missing required environment variables."
	echo "Must provide: REDIS_HOST, REDIS_PORT, REDIS_PASSWORD"
	exit 1
fi


# Wait for MariaDB to be ready
echo "Waiting for MariaDB to be ready..."
until mysql -h"$WORDPRESS_DB_HOST" -u"$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; do
	echo "MariaDB not ready yet, waiting..."
	sleep 2
done
echo "MariaDB is ready !"

# If WordPress is not installed yet
if [ ! -f "/var/www/html/wp-config.php" ]; then
	echo "Installing WordPress..."

	# Download WordPress core files
	wp core download --allow-root

	# Create wp-congig.php with database configuration
	wp config create \
		--dbname="$WORDPRESS_DB_NAME" \
		--dbuser="$WORDPRESS_DB_USER" \
		--dbpass="$WORDPRESS_DB_PASSWORD" \
		--dbhost="$WORDPRESS_DB_HOST" \
		--allow-root

	# Config Redis
	wp config set WP_REDIS_HOST $REDIS_HOST --allow-root
	wp config set WP_REDIS_PORT $REDIS_PORT --raw --allow-root
	wp config set WP_REDIS_PASSWORD "$REDIS_PASSWORD" --allow-root
	wp config set WP_REDIS_DATABASE 0 --raw --allow-root

	# Install WordPress (create database tables and admin user)
	wp core install \
		--url="$WORDPRESS_URL" \
		--title="$WORDPRESS_TITLE" \
		--admin_user="$WORDPRESS_ADMIN_USER" \
		--admin_password="$WORDPRESS_ADMIN_PASSWORD" \
		--admin_email="$WORDPRESS_ADMIN_EMAIL" \
		--skip-email \
		--allow-root

	# Install and enable Redis cache
	wp plugin install redis-cache --activate --allow-root
	wp redis enable --allow-root

	# Create user
	wp user create "$WORDPRESS_USER" "$WORDPRESS_USER_EMAIL"\
		--role=author \
		--user_pass="$WORDPRESS_USER_PASSWORD" \
		--allow-root

	# Set correct permissions for PHP-FPM
	chown -R www-data:www-data /var/www/html
	chmod -R 755 /var/www/html

	echo "WordPress installed sucessfully!"
fi

# Start PHP-FPM in foreground
echo "Starting PHP-FPM..."
exec php-fpm8.2 -F
