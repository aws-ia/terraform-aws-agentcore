module "terraform-aws-agentcore" {
  source = "../.."
  # source = "aws-ia/agentcore/aws"
  # version = "x.x.x"

  debug = true

  runtimes = {
    my_agent = {
      source_type           = "CONTAINER"
      container_source_path = "./src"
      description           = "Basic CONTAINER runtime with STRANDS framework"
      
      environment_variables = {
        LOG_LEVEL = "INFO"
      }
    }
  }
}
