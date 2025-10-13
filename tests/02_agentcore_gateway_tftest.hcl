## NOTE: This is the minimum mandatory test
# run at least one test using the ./examples directory as your module source
# create additional *.tftest.hcl for your own unit / integration tests
# use tests/*.auto.tfvars to add non-default variables

run "plan_gateway" {
  command = plan
  module {
    source = "./examples/gateway-example"
  }
}

run "apply_gateway" {
  command = apply
  module {
    source = "./examples/gateway-example"
  }
}
