# =============================================================================
# LOCALS
# =============================================================================

locals {
  module_version = trimspace(file("${path.module}/VERSION"))
  merged_tags = merge(
    var.tags,
    { ModuleVersion = local.module_version }
  )
}
