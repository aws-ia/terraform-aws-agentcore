import json
import logging
import os
from datetime import datetime
from bedrock_agentcore.runtime import BedrockAgentCoreApp

# Set up logging
log_level = os.getenv('LOG_LEVEL', 'INFO')
logging.basicConfig(level=getattr(logging, log_level))
logger = logging.getLogger(__name__)

# Initialize the BedrockAgentCoreApp
app = BedrockAgentCoreApp()


@app.entrypoint
def handler(payload):
    """
    Main handler function for AgentCore Runtime
    """
    logger.info("Received payload: %s", json.dumps(payload))

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

    # Get user input
    user_input = payload.get('prompt', '')
    logger.info("User input: %s", user_input)

    # Get runtime info
    runtime_info = list(runtimes.values())[0] if runtimes else {}

    # Return response as plain string (not dict)
    response_text = f"Hello from AgentCore Runtime! You said: {user_input}"
    logger.info("Returning response: %s", response_text)
    return response_text


if __name__ == "__main__":
    logger.info("Starting Bedrock Agent Runtime")
    app.run()
