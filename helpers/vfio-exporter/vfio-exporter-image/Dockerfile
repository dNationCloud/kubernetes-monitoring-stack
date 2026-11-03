FROM alpine:latest

# Install libvirt-client to get the 'virsh' utility
RUN apk add --no-cache libvirt-client

# Copy the script into the container and make it executable
COPY monitor.sh /monitor.sh
RUN chmod +x /monitor.sh

ENTRYPOINT ["/bin/sh", "/monitor.sh"]
