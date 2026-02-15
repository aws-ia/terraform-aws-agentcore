# Use Amazon Linux 2023 ARM64 Python image for Graviton compatibility
FROM public.ecr.aws/amazonlinux/amazonlinux:2023

# Install Python 3.11
RUN yum install -y python3.11 python3.11-pip && \
    yum clean all && \
    rm -rf /var/cache/yum

# Set working directory
WORKDIR /app

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies
RUN pip3.11 install --upgrade pip && \
    pip3.11 install --no-cache-dir -r requirements.txt

# Copy agent source code
COPY app.py .

# Set environment variables for BedrockAgentCore
ENV PYTHONUNBUFFERED=1

# Run the agent directly - BedrockAgentCoreApp handles the server
CMD ["python3.11", "app.py"]
