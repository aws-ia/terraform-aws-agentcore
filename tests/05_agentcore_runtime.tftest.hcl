## Test for the Bedrock AgentCore Runtime functionality

run "plan_runtime" {
  command = plan
  module {
    source = "./examples/code-runtime-example"
  }
}

run "apply_runtime" {
  command = apply
  module {
    source = "./examples/code-runtime-example"
  }
}