module "terraform-aws-agentcore" {
  source = "../.."
  # source = "aws-ia/agentcore/aws"
  # version = "x.x.x"

  project_prefix = "registry-example"
  debug          = true

  registries = {
    team-agent-registry = {
      description          = "Catalog of the team's agents, MCP servers and skills"
      authorizer_type      = "AWS_IAM"
      auto_approve_records = false # a curator approves submitted records

      # IAM for the pipeline that publishes records at run time:
      # a managed policy, plus a role that CodeBuild can assume
      publisher = {
        trusted_services = ["codebuild.amazonaws.com"]
      }

      # Records can also be managed by Terraform. This MCP server record uses the
      # minimal server.json and tools documents from the AWS Agent Registry docs.
      records = {
        weather-mcp-server = {
          record_type    = "MCP"
          display_name   = "Weather MCP server"
          description    = "Weather data and forecasts"
          record_version = "1.0.0"
          descriptor_data = jsonencode({
            name        = "io.example/weather-server"
            description = "Weather data and forecasts"
            version     = "1.0.0"
          })
          descriptor_data_schema_version = "2025-12-11"
          tools_data = jsonencode({
            tools = [{
              name        = "get_weather"
              description = "Get the current weather for a location"
              inputSchema = {
                type = "object"
                properties = {
                  location = {
                    type        = "string"
                    description = "City name"
                  }
                }
                required = ["location"]
              }
            }]
          })
          tools_data_schema_version = "2025-11-25"
        }
      }

      tags = {
        Component = "Registry"
      }
    }
  }

  tags = {
    Environment = "development"
    Example     = "agent-registry"
    ManagedBy   = "terraform"
  }
}
