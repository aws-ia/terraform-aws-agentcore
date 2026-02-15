FROM public.ecr.aws/amazonlinux/amazonlinux:2023

# Install basic tools (curl-minimal already installed)
RUN yum install -y wget unzip tar gzip python3 python3-pip git && yum clean all

RUN yum install -y yum-utils && yum-config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo && yum install -y gh 
RUN pip install awscli
