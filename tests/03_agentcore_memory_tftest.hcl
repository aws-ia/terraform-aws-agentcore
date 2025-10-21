## Test for the Bedrock AgentCore Memory functionality
# This test validates the memory example module

run "plan_memory" {
  command = plan
  module {
    source = "./examples/memory-example"
  }
}

run "apply_memory" {
  command = apply
  module {
    source = "./examples/memory-example"
  }
}
