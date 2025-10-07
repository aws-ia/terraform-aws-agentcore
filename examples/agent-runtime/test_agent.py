"""
Test script for the Bedrock Agent Runtime
"""

import json
import unittest
from unittest.mock import patch, MagicMock
import sys
import os

# Import the agent module
from app import bedrock_agent_runtime, agent

class TestBedrockAgentRuntime(unittest.TestCase):
    """Test class for Bedrock Agent Runtime functionality"""
    
    def test_agent_math(self):
        """Test agent with math calculation"""
        print("\n" + "="*50)
        print("TEST: Agent - Math Calculation")
        print("="*50)
        
        # Test math calculation
        payload = {"prompt": "What is 2+2?"}
        
        try:
            response = bedrock_agent_runtime(payload)
            print(f"Input: {payload['prompt']}")
            print(f"Response: {response}")
            
            # Assert that we got a response
            self.assertIsNotNone(response)
            self.assertIsInstance(response, str)
            
            # Check if the response contains "4" (the answer)
            self.assertIn("4", response.lower())
            
            print("✓ Math test passed")
        except Exception as e:
            self.fail(f"Agent failed with error: {e}")
    
    def test_agent_weather(self):
        """Test agent with weather query"""
        print("\n" + "="*50)
        print("TEST: Agent - Weather Query")
        print("="*50)
        
        # Test weather query
        payload = {"prompt": "What's the weather like?"}
        
        try:
            response = bedrock_agent_runtime(payload)
            print(f"Input: {payload['prompt']}")
            print(f"Response: {response}")
            
            # Assert that we got a response
            self.assertIsNotNone(response)
            self.assertIsInstance(response, str)
            
            # Check if the response contains weather-related words
            weather_keywords = ["sunny", "weather", "temperature", "72°f", "22°c"]
            has_weather_info = any(keyword in response.lower() for keyword in weather_keywords)
            self.assertTrue(has_weather_info, "Response should contain weather information")
            
            print("✓ Weather test passed")
        except Exception as e:
            self.fail(f"Agent failed with error: {e}")
    
    def test_agent_greeting(self):
        """Test agent with greeting"""
        print("\n" + "="*50)
        print("TEST: Agent - Greeting")
        print("="*50)
        
        # Test greeting
        payload = {"prompt": "Can you greet John?"}
        
        try:
            response = bedrock_agent_runtime(payload)
            print(f"Input: {payload['prompt']}")
            print(f"Response: {response}")
            
            # Assert that we got a response
            self.assertIsNotNone(response)
            self.assertIsInstance(response, str)
            
            # Check if the response contains greeting-related words
            greeting_keywords = ["hello", "john", "welcome"]
            has_greeting = any(keyword in response.lower() for keyword in greeting_keywords)
            self.assertTrue(has_greeting, "Response should contain a greeting")
            
            print("✓ Greeting test passed")
        except Exception as e:
            self.fail(f"Agent failed with error: {e}")


class InteractiveTest:
    """Interactive testing mode for the agent"""
    
    @staticmethod
    def run():
        """Run interactive testing mode"""
        print("\n" + "="*50)
        print("INTERACTIVE TEST MODE")
        print("="*50)
        print("Type 'quit' to exit")
        print("-"*50)
        
        while True:
            user_input = input("\nEnter your prompt: ").strip()
            
            if user_input.lower() in ['quit', 'exit', 'q']:
                print("Goodbye!")
                break
            
            if not user_input:
                continue
            
            # Test locally
            try:
                payload = {"prompt": user_input}
                response = bedrock_agent_runtime(payload)
                print(f"\nAgent Response: {response}")
            except Exception as e:
                print(f"Error: {e}")


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Test Bedrock Agent Runtime')
    parser.add_argument('--interactive', '-i', action='store_true', 
                       help='Run in interactive mode')
    parser.add_argument('--test', '-t', action='store_true',
                       help='Run unit tests')
    
    args = parser.parse_args()
    
    if args.interactive:
        # Run interactive mode
        InteractiveTest.run()
    else:
        # Run all tests
        unittest.main(argv=[''], verbosity=2, exit=False)
