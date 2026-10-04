FROM jenkins/jenkins:lts

USER root

RUN apt-get update \
    && apt-get install -y \
        ca-certificates \
        curl \
        python3 \
        python3-venv \
        python3-pip \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg \
       -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo \
       "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
       $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
       > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y docker-ce-cli \
    && curl -Lo /usr/local/bin/kind \
       https://kind.sigs.k8s.io/dl/v0.33.0/kind-linux-amd64 \
    && chmod +x /usr/local/bin/kind \
    && curl -Lo /tmp/kubectl \
       https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl \
    && install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl \
    && rm /tmp/kubectl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
