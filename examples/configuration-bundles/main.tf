module "terraform-aws-agentcore" {
  source = "../.."
  # source = "aws-ia/agentcore/aws"
  # version = "x.x.x"

  project_prefix = "bundles-example"
  debug          = true

  # A CODE runtime whose agent reads its system prompt and model from the
  # configuration bundle named in each request (see src/agent.py)
  runtimes = {
    support_agent = {
      source_type      = "CODE"
      code_source_path = "./src"
      code_entry_point = ["agent.py"]
      code_runtime     = "PYTHON_3_11"
      description      = "Support agent configured through configuration bundles"

      environment_variables = {
        LOG_LEVEL = "INFO"
      }
    }
  }

  # Two bundles (control and treatment). Components are keyed by the ARN of the
  # resource they configure; {{runtime:support_agent}} resolves to the runtime ARN.
  configuration_bundles = {
    support_agent_control = {
      description    = "Current support agent configuration"
      commit_message = "Initial configuration"
      components = {
        "{{runtime:support_agent}}" = {
          system_prompt = "You are a helpful customer support assistant for Acme Store."
          model_id      = "global.anthropic.claude-sonnet-4-5-20250929-v1:0"
          temperature   = 0.7
        }
      }
      tags = {
        Variant = "control"
      }
    }

    support_agent_treatment = {
      description    = "Proactive support agent configuration"
      commit_message = "Proactive prompt"
      components = {
        "{{runtime:support_agent}}" = {
          system_prompt = "You are a customer support assistant for Acme Store. Be proactive: check order status before the customer asks and summarize the actions taken."
          model_id      = "global.anthropic.claude-sonnet-4-5-20250929-v1:0"
          temperature   = 0.4
        }
      }
      tags = {
        Variant = "treatment"
      }
    }
  }

  tags = {
    Environment = "development"
    Example     = "configuration-bundles"
    ManagedBy   = "terraform"
  }
}
