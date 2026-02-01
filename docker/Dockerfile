FROM felddy/foundryvtt:release-13.351.0

USER root

# Install AWS CLI v2 and required tools
RUN apt-get update && \
    apt-get install -y curl unzip && \
    curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" && \
    unzip -q /tmp/awscliv2.zip -d /tmp && \
    /tmp/aws/install && \
    rm -rf /tmp/aws /tmp/awscliv2.zip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Override the entrypoint to fetch options.json first
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["resources/app/main.mjs", "--port=30000", "--headless", "--noupdate", "--dataPath=/data"]
