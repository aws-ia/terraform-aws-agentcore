provider "aws" {
  region = "us-east-1"
}

provider "awscc" {
  region = "us-east-1"
}

module "agentcore_memory" {
  source = "../../"

  # Enable Agent Core Memory
  create_memory = true
  memory_name   = "AgentMemory"
  memory_description = "Example memory for Bedrock agent"
  memory_event_expiry_duration = 90
  
  # Configure multiple memory strategies
  memory_strategies = [
    # Semantic memory strategy for understanding context
    {
      semantic_memory_strategy = {
        name = "SemanticMemory"
        description = "Semantic memory for contextual understanding"
        namespaces = ["/strategies/{memoryStrategyId}/actors/{actorId}"]
      }
    },
    # Summary memory strategy for conversation summaries
    {
      summary_memory_strategy = {
        name = "SummaryMemory"
        description = "Summary memory for conversation tracking"
        namespaces = ["/strategies/{memoryStrategyId}/actors/{actorId}/sessions/{sessionId}"]
      }
    },
    # User preference memory strategy for personalization
    {
      user_preference_memory_strategy = {
        name = "UserPreferences"
        description = "Memory for user preferences and settings"
        namespaces = ["/strategies/{memoryStrategyId}/actors/{actorId}"]
      }
    },
  ]
  
  memory_tags = {
    Environment = "development"
    Project     = "bedrock-memory-example"
  }
}
