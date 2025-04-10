FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install basic requirements
RUN apt-get update && apt-get install -y \
    sudo \
    git \
    curl \
    vim \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a test user with sudo access
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/testuser

# Switch to the test user
USER testuser
WORKDIR /home/testuser

CMD ["/bin/bash"]