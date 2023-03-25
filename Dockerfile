# docker build --build-arg TERRAFORM_VERSION="1.3.3" -t devcontainers-terraform .
# https://github.com/devcontainers/images/tree/main/src/go/history
ARG IMAGE_REPO="mcr.microsoft.com/devcontainers/go"
ARG IMAGE_VERSION="0.207.18-1.20-bullseye"
ARG TERRAFORM_VERSION="1.4.2"

FROM ${IMAGE_REPO}:${IMAGE_VERSION} AS builder
ARG TERRAFORM_VERSION

# https://releases.hashicorp.com/terraform/1.3.3/terraform_1.3.3_linux_amd64.zip
# Terraform
RUN wget --quiet https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    mv terraform /usr/bin

FROM ${IMAGE_REPO}:${IMAGE_VERSION}
ARG AZURE_CLI_VERSION="2.46.0"
ARG tflint_version="v0.45.0"
ARG terrascan_version="latest"
ARG USERNAME=vscode
ARG USER_UID=1000

# Copy files from builder
COPY --from=builder ["/usr/bin/terraform", "/usr/bin/terraform"]

RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

# update yarn gpg
# RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor > /usr/share/keyrings/yarn-archive-keyring.gpg
# RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
# RUN apt-key adv --keyserver keys.gnupg.net --recv-keys 23E7166788B63E1E

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor > /usr/share/keyrings/yarn-archive-keyring.gpg

# RUN rm -f /etc/apt/sources.list.d/yarn.list || echo "yarn.list not found"

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    apt-transport-https \
    lsb-release \
    gnupg \
    python3-pip \
    python3-venv
    
# RUN export YARNKEY=yarn-keyring.gpg && \
#     curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmour -o /usr/share/keyrings/$YARNKEY && \
#     echo "deb [signed-by=/usr/share/keyrings/$YARNKEY] https://dl.yarnpkg.com/debian stable main" > /etc/apt/sources.list.d/yarn.list && \
#     gpg --refresh-keys 23E7166788B63E1E

ENV PIPX_HOME=/usr/local/pipx
ENV PIPX_BIN_DIR=/usr/local/bin

# install pre-commit
RUN python3 -m pip install pipx && \
    pipx install pre-commit

# Install Azure CLI system level
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor | \
    tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

RUN AZ_REPO=$(lsb_release -cs) && \
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
    tee /etc/apt/sources.list.d/azure-cli.list && \
    apt-get update && \
    apt-get install -y "azure-cli=${AZURE_CLI_VERSION}-1~bullseye"

# install tflint
RUN wget https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh -O /tmp/tflint_install_linux.sh && \
    chmod +x /tmp/tflint_install_linux.sh && \
    TFLINT_VERSION="$tflint_version" /tmp/tflint_install_linux.sh

# install terrascan - https://github.com/tenable/terrascan/releases
RUN curl -L "$(curl -s https://api.github.com/repos/tenable/terrascan/releases/latest | grep -o -E "https://.+?_Linux_x86_64.tar.gz")" > terrascan.tar.gz && \
    tar -xf terrascan.tar.gz terrascan && \
    rm terrascan.tar.gz && \
    install terrascan /usr/local/bin && \
    rm terrascan && \
    terrascan version

# Clean up
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
