run "plan_gateway_policy" {
  command = plan
  module {
    source = "./examples/gateway-policy"
  }
}

run "apply_gateway_policy" {
  command = apply
  module {
    source = "./examples/gateway-policy"
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.policy_engine_ids)) == 1
    error_message = "Should create exactly 1 policy engine"
  }

  assert {
    condition     = contains(keys(module.terraform-aws-agentcore.policy_engine_ids), "orders_policy_engine")
    error_message = "Should create orders_policy_engine"
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.policy_ids)) == 3
    error_message = "Should create exactly 3 policies (2 Cedar, 1 Dogwood)"
  }

  assert {
    condition     = contains(keys(module.terraform-aws-agentcore.policy_ids), "orders_policy_engine/RefundOnlyAfterLookup")
    error_message = "Should create the RefundOnlyAfterLookup temporal policy"
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.gateway_ids)) == 1
    error_message = "Should create exactly 1 gateway"
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.gateway_target_ids)) == 2
    error_message = "Should create exactly 2 gateway targets (one per tool)"
  }

  assert {
    condition     = alltrue([for arn in values(module.terraform-aws-agentcore.policy_arns) : can(regex("^arn:aws:bedrock-agentcore:[a-z0-9-]+:[0-9]{12}:policy-engine/orders_policy_engine-[a-z0-9_]{10}/policy/", arn))])
    error_message = "Policies should belong to the orders_policy_engine engine"
  }

  assert {
    condition     = module.terraform-aws-agentcore.gateway_target_names["orders-lookup"] == "policy-example-orders-lookup" && module.terraform-aws-agentcore.gateway_target_names["orders-refund"] == "policy-example-orders-refund"
    error_message = "Target names (and therefore Cedar action names) should be prefixed with project_prefix"
  }

  assert {
    condition     = alltrue([for status in values(module.terraform-aws-agentcore.policy_statuses) : status == "ACTIVE"])
    error_message = "Every policy should be ACTIVE after apply"
  }
}
