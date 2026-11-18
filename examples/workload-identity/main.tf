module "terraform-aws-agentcore" {
  source = "../.."
  # source = "aws-ia/agentcore/aws"
  # version = "x.x.x"

  project_prefix = "identity-example"
  debug          = true

  # AgentCore Identity creates a workload identity for every runtime; the module
  # exposes its ARN through runtime_workload_identity_arns
  runtimes = {
    my_agent = {
      source_type      = "CODE"
      code_source_path = "../basic-code-runtime/src"
      code_entry_point = ["agent.py"]
      code_runtime     = "PYTHON_3_11"
      description      = "Runtime whose workload identity is exposed as an output"
    }
  }

  # Explicitly managed workload identities, for agents that run outside AgentCore
  # Runtime or that need OAuth2 return URLs for 3-legged OAuth flows
  workload_identities = {
    external-support-agent = {
      allowed_resource_oauth2_return_urls = ["https://support.example.com/oauth2/callback"]
      tags = {
        Component = "Identity"
      }
    }
  }

  tags = {
    Environment = "development"
    Example     = "workload-identity"
    ManagedBy   = "terraform"
  }
}
