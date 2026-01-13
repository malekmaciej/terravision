# Multi-stage Dockerfile for TerraVision
# Supports both linux/amd64 and linux/arm64 architectures

FROM python:3.11-slim AS base

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    graphviz \
    git \
    curl \
    unzip \
    ca-certificates \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Terraform
ARG TERRAFORM_VERSION=1.9.8
ARG TARGETARCH
RUN case ${TARGETARCH} in \
    "amd64")  TERRAFORM_ARCH=amd64  ;; \
    "arm64")  TERRAFORM_ARCH=arm64  ;; \
    *)        echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac && \
    curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TERRAFORM_ARCH}.zip" -o terraform.zip && \
    unzip terraform.zip -d /usr/local/bin/ && \
    rm terraform.zip && \
    chmod +x /usr/local/bin/terraform

# Set working directory
WORKDIR /app

# Copy dependency files
COPY requirements.txt pyproject.toml README.md ./
COPY poetry.lock* ./

# Install Python dependencies
# Note: In production builds, --trusted-host flags should not be needed.
# They are used here to handle corporate proxy/firewall scenarios.
RUN pip install --no-cache-dir --trusted-host pypi.org --trusted-host files.pythonhosted.org -r requirements.txt

# Copy application code
COPY terravision/ ./terravision/
COPY modules/ ./modules/
COPY resource_classes/ ./resource_classes/
COPY resource_images/ ./resource_images/
COPY hcl2/ ./hcl2/
COPY shiftLabel.gvpr override.tf terravision.bat ./

# Install terravision package
# Note: In production builds, --trusted-host flags should not be needed.
# They are used here to handle corporate proxy/firewall scenarios.
RUN pip install --no-cache-dir --trusted-host pypi.org --trusted-host files.pythonhosted.org -e .

# Create workspace directory
RUN mkdir -p /workspace
WORKDIR /workspace

# Set entrypoint
ENTRYPOINT ["terravision"]
CMD ["--help"]
