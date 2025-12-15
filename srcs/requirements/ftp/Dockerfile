# Import stable Debian base image (Bookworm)
FROM debian:12

# Skip interactivity (timezone, etc)
ENV DEBIAN_FRONTEND=noninteractive

# Install vsftpd (Very Secure FTP Daemon)
RUN apt-get update && \
	apt-get install -y vsftpd && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

# Copy install script to entrypoint
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

# Chmod on entrypoint.sh (executable)
RUN chmod +x /usr/local/bin/entrypoint.sh

# Vsftpd listening ports
## 21 => control port (cmd)
## 21000-21010 => passive mode data ports
EXPOSE 21 21000-21010

# Create vsftpd secure directory
RUN mkdir -p /var/run/vsftpd/empty

# Declare entry point
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
