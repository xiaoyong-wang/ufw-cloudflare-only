#!/bin/bash

# Get Cloudflare IP ranges
CF_IPV4_URL="https://www.cloudflare.com/ips-v4"
CF_IPV6_URL="https://www.cloudflare.com/ips-v6"

# Fetch the IP ranges
echo "Fetching Cloudflare IPv4 IP ranges..."
CF_IPV4_RANGES=$(curl -s "$CF_IPV4_URL")

echo "Fetching Cloudflare IPv6 IP ranges..."
CF_IPV6_RANGES=$(curl -s "$CF_IPV6_URL")

# Get SSH port from SSH configuration
SSH_PORT=$(grep "^Port " /etc/ssh/sshd_config | awk '{print $2}')

# Default to port 22 if SSH port is not found in configuration
if [ -z "$SSH_PORT" ]; then
  SSH_PORT=22
fi

echo "Detected SSH running on port $SSH_PORT"

# Configure UFW
echo "Resetting UFW rules..."
ufw reset --force

echo "Denying all incoming traffic by default..."
ufw default deny incoming

echo "Allowing all outgoing traffic..."
ufw default allow outgoing

echo "Allowing SSH traffic on port $SSH_PORT..."
ufw allow $SSH_PORT/tcp

# Allow HTTP and HTTPS traffic from Cloudflare IP ranges
echo "Allowing HTTP and HTTPS traffic from Cloudflare IP ranges..."

# Allow IPv4 ranges
IFS=$'\n'
for ip_range in $CF_IPV4_RANGES; do
  ufw allow from $ip_range to any port 80,443 proto tcp
done

# Allow IPv6 ranges
for ip_range in $CF_IPV6_RANGES; do
  ufw allow from $ip_range to any port 80,443 proto tcp
done

# Enable UFW
echo "Enabling UFW..."
ufw enable

echo "UFW configuration completed successfully."
