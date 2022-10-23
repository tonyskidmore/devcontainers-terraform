# docker build --build-arg TERRAFORM_VERSION="1.3.3" -t devcontainers-terraform .
ARG IMAGE_REPO="mcr.microsoft.com/devcontainers/go"
ARG IMAGE_VERSION="0.207.8-1.19-bullseye"
ARG TERRAFORM_VERSION="1.3.3"

FROM ${IMAGE_REPO}:${IMAGE_VERSION} AS builder
ARG TERRAFORM_VERSION

# https://releases.hashicorp.com/terraform/1.3.3/terraform_1.3.3_linux_amd64.zip
# Terraform
RUN wget --quiet https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    mv terraform /usr/bin

FROM ${IMAGE_REPO}:${IMAGE_VERSION}
ARG AZURE_CLI_VERSION="2.41.0"
ARG USERNAME=vscode
ARG USER_UID=1000

# Copy files from builder
COPY --from=builder ["/usr/bin/terraform", "/usr/bin/terraform"]

RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    apt-transport-https \
    lsb-release \
    gnupg \
    python3-pip \
    python3-venv

# install pre-commit
RUN python3 -m pip install pipx && \
    pipx ensurepath && \
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

# Clean up
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
