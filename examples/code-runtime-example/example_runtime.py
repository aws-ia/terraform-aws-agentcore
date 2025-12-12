import sys
import json
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def handler(event, context):
    """
    Main handler function for the Bedrock Agent Runtime
    """
    logger.info("Received event: %s", json.dumps(event))
    
    # Parse the request
    request_type = event.get('requestType', '')
    request_payload = event.get('payload', {})
    
    logger.info("Request type: %s", request_type)
    
    # Handle different request types
    if request_type == 'InvokeAgent':
        # Process agent invocation
        return {
            'response': {
                'message': 'Hello from the Bedrock Agent Code Runtime!',
                'timestamp': '2023-08-01T12:34:56Z',
                'data': request_payload
            }
        }
    else:
        # Handle unknown request type
        return {
            'response': {
                'error': f'Unknown request type: {request_type}',
                'status': 'error'
            }
        }

# For local testing
if __name__ == "__main__":
    # Sample event for testing
    test_event = {
        'requestType': 'InvokeAgent',
        'payload': {'query': 'test query'}
    }
    
    result = handler(test_event, None)
    print(json.dumps(result, indent=2))
