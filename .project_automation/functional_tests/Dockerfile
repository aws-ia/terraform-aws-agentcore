FROM public.ecr.aws/amazonlinux/amazonlinux:2023

# Install basic tools (curl-minimal already installed)
RUN yum install -y wget unzip tar gzip python3 python3-pip git && yum clean all

ENV TERRAFORM_VERSION=1.14.0
RUN cd /tmp && \
    wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin && chmod 755 /usr/local/bin/terraform