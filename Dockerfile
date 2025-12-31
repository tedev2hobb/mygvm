FROM debian:12

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    sudo \
    redis-server \
    postgresql \
    postgresql-contrib \
    python3 \
    rsync \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Add Greenbone repository
RUN curl -fsSL https://packages.greenbone.net/GBCommunitySigningKey.asc \
    | gpg --dearmor -o /usr/share/keyrings/greenbone.gpg

RUN echo "deb [signed-by=/usr/share/keyrings/greenbone.gpg] \
    https://packages.greenbone.net/community/debian stable main" \
    > /etc/apt/sources.list.d/greenbone.list

# Install OpenVAS / Greenbone
RUN apt-get update && apt-get install -y \
    greenbone-community \
    && rm -rf /var/lib/apt/lists/*

# Initialize Greenbone
RUN gvm-setup

# Update ALL feeds during build
RUN greenbone-feed-sync --type GVMD_DATA && \
    greenbone-feed-sync --type SCAP && \
    greenbone-feed-sync --type CERT && \
    greenbone-feed-sync --type NVT

# Create admin user (change password!)
RUN gvmd --create-user=admin --password=admin

EXPOSE 9392

# Start services
CMD service redis-server start && \
    service postgresql start && \
    gvm-start && \
    tail -f /var/log/gvm/gvmd.log
