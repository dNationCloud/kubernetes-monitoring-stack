FROM alpine:latest

# Install psmisc to get the 'fuser' utility
RUN apk add --no-cache psmisc

# Copy the script into the container and make it executable
COPY monitor.sh /monitor.sh
RUN chmod +x /monitor.sh

ENTRYPOINT ["/bin/sh", "/monitor.sh"]
