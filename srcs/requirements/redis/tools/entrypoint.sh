#!/bin/sh

# Stop if error
set -e

# Get secrets shhhhhh
REDIS_PASSWORD=$(cat /run/secrets/redis_password)

# Check mandatory WordPress database environnement variable
if [ -z "$REDIS_PASSWORD" ] ; then
	echo "Missing required environment variables."
	echo "Must provide: REDIS_PASSWORD"
	exit 1
fi

# Start Redis server
exec redis-server --requirepass "$REDIS_PASSWORD" --bind 0.0.0.0
