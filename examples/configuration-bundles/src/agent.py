import json
import logging
import os

from bedrock_agentcore.runtime import BedrockAgentCoreApp, BedrockAgentCoreContext

# Set up logging
log_level = os.getenv("LOG_LEVEL", "INFO")
logging.basicConfig(level=getattr(logging, log_level))
logger = logging.getLogger(__name__)

# Defaults used when the request carries no configuration bundle reference
DEFAULT_SYSTEM_PROMPT = "You are a helpful customer support assistant."
DEFAULT_MODEL_ID = "global.anthropic.claude-sonnet-4-5-20250929-v1:0"

# Initialize the BedrockAgentCoreApp
app = BedrockAgentCoreApp()


def active_configuration():
    """
    Return the configuration bundle component for this runtime.

    The runtime parses the W3C baggage header of the request
    (aws.agentcore.configbundle_arn / aws.agentcore.configbundle_version),
    resolves the bundle version and caches it. Without a bundle reference the
    SDK returns an empty dict, so the defaults above apply.
    """
    try:
        return BedrockAgentCoreContext.get_config_bundle() or {}
    except Exception as exc:  # degrade gracefully if the lookup fails
        logger.warning("Configuration bundle lookup failed: %s", exc)
        return {}


@app.entrypoint
def handler(payload):
    """
    Main handler function for AgentCore Runtime
    """
    logger.info("Received payload: %s", json.dumps(payload))

    config = active_configuration()
    system_prompt = config.get("system_prompt", DEFAULT_SYSTEM_PROMPT)
    model_id = config.get("model_id", DEFAULT_MODEL_ID)
    user_input = payload.get("prompt", "")

    logger.info("Model: %s | System prompt: %s", model_id, system_prompt)

    # A real agent would call the model here; this example echoes the active configuration
    return json.dumps({
        "model_id": model_id,
        "system_prompt": system_prompt,
        "response": f"You said: {user_input}",
    })


if __name__ == "__main__":
    logger.info("Starting Bedrock Agent Runtime")
    app.run()
