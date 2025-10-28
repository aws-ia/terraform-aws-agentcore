## Test for the Bedrock AgentCore Browser Custom functionality

run "plan_ai-assistants" {
  command = plan
  module {
    source = "./examples/ai-assistants-example"
  }
}

run "apply_ai-assistants" {
  command = apply
  module {
    source = "./examples/ai-assistants-example"
  }
}