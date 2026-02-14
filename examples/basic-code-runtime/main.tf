module "terraform-aws-agentcore" {
  source = "../.."
  # source = "aws-ia/agentcore/aws"
  # version = "x.x.x"

  runtimes = {
    my_agent = {
      source_type      = "CODE"
      code_source_path = "./src"
      code_entry_point = ["agent.py"]
      code_runtime     = "PYTHON_3_11"
      description      = "Basic Python agent runtime"
      
      environment_variables = {
        LOG_LEVEL = "INFO"
      }
    }
  }

  debug = true
}
