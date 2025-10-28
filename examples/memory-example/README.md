<!-- BEGIN_TF_DOCS -->
# Amazon Bedrock AgentCore Memory Example

This example demonstrates how to use the AgentCore module to create and configure an Amazon Bedrock AgentCore Memory resource with various memory strategies.

## Overview

This example sets up:

1. A Bedrock AgentCore Memory resource
2. Multiple memory strategies:
   - Semantic memory strategy for contextual understanding
   - Summary memory strategy for conversation tracking
   - User preference memory strategy for personalization

## Usage

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply

# Clean up resources when done
terraform destroy
```

## Memory Strategies

This example demonstrates all available memory strategy types:

### Semantic Memory Strategy

Helps agents understand and recall semantic information from past interactions. This strategy is useful for contextual awareness and tracking concepts discussed throughout a conversation.

### Summary Memory Strategy

Creates summaries of conversations to help maintain long-term context. This is particularly useful for tracking the overall flow of a conversation without storing every detail.

### User Preference Memory Strategy

Tracks user preferences and settings to provide a more personalized experience. This strategy helps agents remember individual user preferences across multiple conversations.

## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_agentcore_memory"></a> [agentcore\_memory](#module\_agentcore\_memory) | ../../ | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->