# Import stable Debian base image (Bookworm)
FROM debian:12

# Skip interactivity (timezone, etc)
ENV DEBIAN_FRONTEND=noninteractive

# Install wget to download cAdvisor
RUN apt-get update && \
	apt-get install -y wget ca-certificates && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

# Download cAdvisor binary (latest version with Docker API 1.44+ support)
RUN wget https://github.com/google/cadvisor/releases/download/v0.50.0/cadvisor-v0.50.0-linux-amd64 -O /usr/local/bin/cadvisor && \
	chmod +x /usr/local/bin/cadvisor

# Expose port 8081
EXPOSE 8081

# Start cAdvisor
CMD ["/usr/local/bin/cadvisor", "-port=8081"]
