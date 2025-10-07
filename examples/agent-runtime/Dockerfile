# Use Python 3.13 slim image for BedrockAgentCore
FROM python:3.13-slim

# Set working directory
WORKDIR /app

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies
RUN pip3 install --upgrade pip && \
    pip3 install --no-cache-dir -r requirements.txt

# Copy agent source code
COPY app.py .

# Set environment variables for BedrockAgentCore
ENV PYTHONUNBUFFERED=1

# Run the agent directly - BedrockAgentCoreApp handles the server
CMD ["python", "app.py"]
