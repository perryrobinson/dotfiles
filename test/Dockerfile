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

# Match the version exercised by the justfiles skill checks.
RUN curl -fsSL -o /tmp/just.tar.gz \
    "https://github.com/casey/just/releases/download/1.59.0/just-1.59.0-$(uname -m)-unknown-linux-musl.tar.gz" \
    && tar -xzf /tmp/just.tar.gz -C /usr/local/bin just \
    && rm /tmp/just.tar.gz

# Create a test user with sudo access
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/testuser

# Copy dotfiles into the container
COPY --chown=testuser:testuser . /home/testuser/dotfiles

# Switch to the test user
USER testuser
WORKDIR /home/testuser

CMD ["/bin/bash"]
