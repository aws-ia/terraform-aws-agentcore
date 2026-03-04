# =============================================================================
# LOCALS
# =============================================================================

locals {
  module_version = trimspace(file("${path.module}/VERSION"))
  merged_tags = merge(
    var.tags,
    { ModuleVersion = local.module_version }
  )
  project_prefix_cleaned = var.project_prefix != null ? var.project_prefix : ""
}
