# Mandatory test file required by AWS-IA framework
# Actual tests are in numbered test files (01_*, 02_*, 03_*)

run "dummy" {
  command = plan
  module {
    source = "./examples/basic-code-runtime"
  }
}
