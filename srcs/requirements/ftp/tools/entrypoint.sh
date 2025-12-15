#!/bin/sh

# Stop if error
set -e

# Get secrets shhhhhh
FTP_PASSWORD=$(cat /run/secrets/ftp_password)

# Check mandatory environnement variable
if [ -z "$FTP_PASSWORD" ]; then
	echo "Missing required environment variables."
	echo "Must provide: FTP_PASSWORD"
	exit 1
fi

# Create ftp user if doesn't exit
if ! id -u "$FTP_USER" > /dev/null 2>&1; then
	echo "Creating FTP user: $FTP_USER"

	# Create user zith home at WordPress directory
	useradd -m -d /var/www/html -s /bin/bash "$FTP_USER"

	# Set password
	echo "$FTP_USER:$FTP_PASSWORD" | chpasswd
fi

# Configure vsftpd
cat > /etc/vsftpd.conf << EOF
# Run in stqndqlone mode
listen=YES
listen_ipv6=NO

# Disable anonymous login
anonymous_enable=NO

# Enable local users
local_enable=YES
write_enable=YES

# Chroot users to their home directory
chroot_local_user=YES
allow_writeable_chroot=YES

# Passive mode configuration
pasv_enable=YES
pasv_min_port=21000
pasv_max_port=21010
pasv_address=0.0.0.0

# Security
seccomp_sandbox=NO
EOF

echo "Starting vsftpd..."
exec /usr/sbin/vsftpd /etc/vsftpd.conf

