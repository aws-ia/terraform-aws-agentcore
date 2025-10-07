"""
Simple client to invoke the Bedrock Agent Core Runtime endpoint
"""

import json
import boto3
from botocore.exceptions import ClientError

def invoke_agent_runtime(runtime_arn=None, endpoint_qualifier=None, prompt=None):
    """Invoke the agent runtime endpoint"""
    
    # Initialize the Bedrock Agent Core Runtime client
    client = boto3.client('bedrock-agentcore', region_name='us-east-1')
    
    # Default values if not provided
    if runtime_arn is None:
        # This is a placeholder - you need to replace with your actual runtime ARN after deployment
        runtime_arn = "arn:aws:bedrock-agentcore:us-east-1:ACCOUNT_ID:runtime/RUNTIME_ID"
    
    if endpoint_qualifier is None:
        endpoint_qualifier = "bedrock_agent_runtime_example_endpoint"
    
    if prompt is None:
        prompt = "What is 2+2?"
    
    # Test payload
    input_text = {"prompt": prompt}
    
    print("="*60)
    print("Bedrock Agent Core Runtime Invocation")
    print("="*60)
    print(f"Runtime ARN: {runtime_arn}")
    print(f"Endpoint: {endpoint_qualifier}")
    print(f"Payload: {input_text}")
    print("-"*60)
    
    try:
        # Invoke the runtime
        print("\nInvoking runtime...")
        response = client.invoke_agent_runtime(
            agentRuntimeArn=runtime_arn,
            qualifier=endpoint_qualifier,
            payload=json.dumps(input_text)  # Convert to JSON string
        )
        
        print("\n✓ Invocation successful!")
        print("\nResponse metadata:")
        print(f"  HTTP Status Code: {response['ResponseMetadata']['HTTPStatusCode']}")
        print(f"  Request ID: {response['ResponseMetadata']['RequestId']}")
        
        # Debug: Print all response keys
        print("\nResponse keys:", list(response.keys()))
        
        # Parse the response payload - handle different response formats
        if 'payload' in response:
            payload_stream = response['payload']
            payload_data = payload_stream.read()
            
            print("\nResponse payload (raw bytes):")
            print(f"  Length: {len(payload_data)} bytes")
            print(f"  Content: {payload_data}")
            
            # Try to parse as JSON
            if payload_data:
                try:
                    # First try to decode as UTF-8
                    text_data = payload_data.decode('utf-8')
                    print("\nResponse payload (decoded text):")
                    print(f"  {text_data}")
                    
                    # Then try to parse as JSON
                    try:
                        result = json.loads(text_data)
                        print("\nResponse payload (parsed JSON):")
                        print(f"  {json.dumps(result, indent=2)}")
                    except json.JSONDecodeError:
                        # It's plain text, not JSON
                        print("\nResponse is plain text (not JSON)")
                except UnicodeDecodeError:
                    print("\nResponse payload (binary - cannot decode):")
                    print(f"  {payload_data.hex()}")
            else:
                print("\nResponse payload is empty (0 bytes)")
        elif 'response' in response:
            # Handle streaming response format
            print("\nStreaming response detected...")
            try:
                events = []
                for event in response.get("response", []):
                    events.append(event)
                    # Decode the event if it's bytes
                    if isinstance(event, bytes):
                        decoded_event = event.decode('utf-8')
                        # Try to parse as JSON string
                        try:
                            parsed_event = json.loads(decoded_event)
                            print(f"\n✅ Agent Response: {parsed_event}")
                        except json.JSONDecodeError:
                            print(f"\n✅ Agent Response: {decoded_event}")
                    else:
                        print(f"\n✅ Agent Response: {event}")
                
                if not events:
                    print("\n⚠️ No events in stream")
            except Exception as e:
                print(f"  Error reading stream: {e}")
        else:
            print("\nNo 'payload' or 'response' key in response")
            print("Available keys:", list(response.keys()))
            
    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_message = e.response['Error']['Message']
        
        print(f"\n✗ AWS Error: {error_code}")
        print(f"  Message: {error_message}")
        
        # Provide specific guidance based on error
        if error_code == 'ResourceNotFoundException':
            print("\n⚠ The runtime or endpoint was not found.")
            print("  Check that the runtime ARN and qualifier are correct.")
            
        elif error_code == 'ValidationException':
            print("\n⚠ The request format is invalid.")
            print("  Check the payload structure.")
            
        elif error_code == 'AccessDeniedException':
            print("\n⚠ Access denied.")
            print("  Check your AWS credentials and IAM permissions.")
            
        elif error_code == 'InternalServerError' or '404' in error_message:
            print("\n⚠ The runtime returned an error (possibly 404).")
            print("  This usually means the container is running but the app isn't responding.")
            print("\n  Possible causes:")
            print("  1. The BedrockAgentCoreApp isn't starting correctly")
            print("  2. The @app.entrypoint decorator isn't registering the function")
            print("  3. The container CMD/ENTRYPOINT isn't correct")
            print("\n  To debug:")
            print("  1. Check CloudWatch logs for the runtime")
            print("  2. Verify the Dockerfile CMD is correct")
            print("  3. Ensure app.run() is being called in the container")
            
    except Exception as e:
        print(f"\n✗ Unexpected error: {e}")
        print(f"  Type: {type(e).__name__}")


def check_runtime_status(runtime_id=None):
    """Check the status of the runtime"""
    
    client = boto3.client('bedrock-agentcore-control', region_name='us-east-1')
    
    # Default value if not provided
    if runtime_id is None:
        # This is a placeholder - you need to replace with your actual runtime ID after deployment
        runtime_id = "RUNTIME_ID"
    
    print("\n" + "="*60)
    print("Runtime Status Check")
    print("="*60)
    
    try:
        response = client.get_agent_runtime(
            agentRuntimeId=runtime_id
        )
        
        print(f"Runtime ID: {runtime_id}")
        print(f"Name: {response.get('agentRuntimeName', 'N/A')}")
        print(f"Status: {response.get('agentStatus', 'N/A')}")
        print(f"Created: {response.get('createdAt', 'N/A')}")
        print(f"Updated: {response.get('lastUpdatedAt', 'N/A')}")
        
        if 'agentRuntimeArtifact' in response:
            artifact = response['agentRuntimeArtifact']
            if 'containerConfiguration' in artifact:
                container = artifact['containerConfiguration']
                print(f"Container URI: {container.get('containerUri', 'N/A')}")
        
    except ClientError as e:
        print(f"✗ Could not get runtime status: {e.response['Error']['Message']}")
    except Exception as e:
        print(f"✗ Error: {e}")


if __name__ == "__main__":
    import sys
    import argparse
    
    parser = argparse.ArgumentParser(description='Invoke Bedrock Agent Runtime')
    parser.add_argument('--runtime-arn', type=str, help='ARN of the runtime')
    parser.add_argument('--runtime-id', type=str, help='ID of the runtime (for status check)')
    parser.add_argument('--qualifier', type=str, help='Endpoint qualifier')
    parser.add_argument('--prompt', type=str, help='Prompt to send to the agent')
    parser.add_argument('--status-only', action='store_true', help='Only check runtime status')
    
    args = parser.parse_args()
    
    # Check runtime status first
    check_runtime_status(args.runtime_id)
    
    if not args.status_only:
        # Then invoke the runtime
        print("\n")
        invoke_agent_runtime(args.runtime_arn, args.qualifier, args.prompt)
        
        # Interactive mode
        print("\n" + "="*60)
        print("Interactive Mode (press Ctrl+C to exit)")
        print("="*60)
        
        runtime_arn = args.runtime_arn
        qualifier = args.qualifier
        
        if runtime_arn is None:
            runtime_arn = input("Enter runtime ARN: ").strip()
        
        if qualifier is None:
            qualifier = input("Enter endpoint qualifier: ").strip()
        
        while True:
            try:
                user_input = input("\nEnter prompt (or 'quit' to exit): ").strip()
                
                if user_input.lower() in ['quit', 'exit', 'q']:
                    break
                    
                if not user_input:
                    continue
                
                # Create new client for each request
                client = boto3.client('bedrock-agentcore', region_name='us-east-1')
                
                # Invoke with user input
                response = client.invoke_agent_runtime(
                    agentRuntimeArn=runtime_arn,
                    qualifier=qualifier,
                    payload=json.dumps({"prompt": user_input})
                )
                
                # Display response - handle both payload and streaming formats
                if 'response' in response:
                    # Handle streaming response
                    try:
                        for event in response.get("response", []):
                            if isinstance(event, bytes):
                                decoded_event = event.decode('utf-8')
                                try:
                                    parsed_event = json.loads(decoded_event)
                                    print(f"\n✅ Agent Response: {parsed_event}")
                                except json.JSONDecodeError:
                                    print(f"\n✅ Agent Response: {decoded_event}")
                            else:
                                print(f"\n✅ Agent Response: {event}")
                    except Exception as e:
                        print(f"Error reading response: {e}")
                elif 'payload' in response:
                    # Handle payload format
                    payload_data = response['payload'].read()
                    if payload_data:
                        try:
                            result = json.loads(payload_data)
                            print(f"\n✅ Agent Response: {result}")
                        except:
                            print(f"\n✅ Agent Response: {payload_data.decode('utf-8')}")
                else:
                    print("No response data found")
                            
            except KeyboardInterrupt:
                print("\n\nExiting...")
                break
            except Exception as e:
                print(f"Error: {e}")
