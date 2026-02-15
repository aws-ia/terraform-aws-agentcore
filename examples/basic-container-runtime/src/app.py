"""
AWS STRANDS Agent with BedrockAgentCoreApp
This agent uses the STRANDS framework with BedrockAgentCoreApp to provide mathematical calculation and weather assistance.
"""

import os
import json
import logging
from strands import Agent, tool
from strands_tools import calculator
from bedrock_agentcore.runtime import BedrockAgentCoreApp
from strands.models import BedrockModel

# Configure logging
log_level = os.environ.get('LOG_LEVEL', 'INFO')
logging.basicConfig(
    level=getattr(logging, log_level),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('bedrock-agent-runtime')

# Parse JSON resources from environment
try:
    runtimes = json.loads(os.environ.get("RUNTIMES", "{}"))
    memories = json.loads(os.environ.get("MEMORIES", "{}"))
    gateways = json.loads(os.environ.get("GATEWAYS", "{}"))
except json.JSONDecodeError as e:
    logger.error(f"Error parsing JSON from environment: {e}")
    runtimes = {}
    memories = {}
    gateways = {}

# Log loaded resources
logger.info("Available runtimes: %s", list(runtimes.keys()))
logger.info("Available memories: %s", list(memories.keys()))
logger.info("Available gateways: %s", list(gateways.keys()))

# Initialize the BedrockAgentCoreApp
app = BedrockAgentCoreApp()

# Create a custom weather tool


@tool
def weather():
    """Get weather information"""
    # Dummy implementation - in production, this would call a weather API
    logger.info("Weather tool called")
    return "It's sunny with a temperature of 72°F (22°C). Perfect weather for outdoor activities!"

# Create a custom greeting tool


@tool
def greeting(name: str = "there"):
    """Generate a personalized greeting"""
    logger.info(f"Greeting tool called with name: {name}")
    return f"Hello, {name}! Welcome to the Bedrock Agent Runtime."


# Configure the Bedrock model
model_id = "us.anthropic.claude-3-7-sonnet-20250219-v1:0"
model = BedrockModel(
    model_id=model_id,
    additional_request_fields={
        "temperature": 0.1,  # Lower temperature for more consistent results
        "max_tokens": 500,
    }
)

# Create the agent with the model and tools
agent = Agent(
    model=model,
    tools=[calculator, weather, greeting],
    system_prompt="You're a helpful assistant. You can do simple math calculations, tell the weather, and provide personalized greetings."
)


@app.entrypoint
def bedrock_agent_runtime(payload):
    """
    Invoke the agent with a payload
    This is the main entrypoint for the Runtime
    """
    # Log the full payload for debugging
    logger.info(f"Received payload: {json.dumps(payload)}")

    # Extract the prompt from the payload
    user_input = payload.get("prompt", "")

    # Log the input for debugging
    logger.info(f"User input: {user_input}")

    # Process the message through the agent
    response = agent(user_input)

    # Extract the text content from the response and return it as a plain string
    # The response structure is: response.message['content'][0]['text']
    if response and hasattr(response, 'message'):
        content = response.message.get('content', [])
        if content and len(content) > 0:
            # Return the plain text string directly (not wrapped in a dictionary)
            text_response = content[0].get('text', 'No response generated')
            logger.info(f"Returning response: {text_response}")
            return text_response

    # Return a plain string for error cases too
    logger.warning("No valid response from agent")
    return "No response generated"


if __name__ == "__main__":
    # Run the app without any parameters - BedrockAgentCoreApp handles defaults
    logger.info("Starting Bedrock Agent Runtime with STRANDS framework")
    app.run()
