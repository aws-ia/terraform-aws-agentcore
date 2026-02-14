FROM public.ecr.aws/amazonlinux/amazonlinux:2023

# Install basic tools (curl-minimal already installed)
RUN yum install -y wget unzip tar gzip python3 python3-pip git && yum clean all

ENV TERRAFORM_VERSION=1.14.0
RUN cd /tmp && \
    wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin && chmod 755 /usr/local/bin/terraform

ENV TFLINT_VERSION=v0.45.0
ENV TFLINT_RULESET_AWS_VERSION=v0.35.0

RUN cd /tmp && \
    wget https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/tflint_linux_amd64.zip && \
    unzip tflint_linux_amd64.zip -d /usr/local/bin && chmod 755 /usr/local/bin/tflint

RUN mkdir -p ~/.tflint.d/plugins

RUN wget -O /tmp/tflint-ruleset-aws.zip https://github.com/terraform-linters/tflint-ruleset-aws/releases/download/${TFLINT_RULESET_AWS_VERSION}/tflint-ruleset-aws_linux_amd64.zip \
  && unzip /tmp/tflint-ruleset-aws.zip -d ~/.tflint.d/plugins \
  && rm /tmp/tflint-ruleset-aws.zip

RUN curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash

RUN pip3 install checkov

# Install Node.js 18.x and markdownlint-cli
RUN curl -fsSL https://rpm.nodesource.com/setup_18.x | bash - && \
    yum install -y nodejs && \
    npm install -g markdownlint-cli

ENV TERRAFORM_DOCS_VERSION=v0.16.0
RUN wget https://github.com/terraform-docs/terraform-docs/releases/download/${TERRAFORM_DOCS_VERSION}/terraform-docs-${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz && \
    tar -C /usr/local/bin -xzf terraform-docs-${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz && chmod +x /usr/local/bin/terraform-docs