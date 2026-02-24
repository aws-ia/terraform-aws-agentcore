# Developer Guide

Internal documentation for module developers on how this module works.

## Terraform Actions for ARM64 Builds

### What Are Terraform Actions?

[Terraform Actions](https://www.hashicorp.com/en/blog/day-2-infrastructure-management-with-terraform-actions) are a **built-in Terraform 1.14+ feature** that enables Day 2 operations - running external processes during infrastructure lifecycle events.

**Key Concept**: Actions let you run operations AFTER infrastructure exists, bridging the gap between infrastructure provisioning and post-provisioning configuration (builds, deployments, data migrations, etc.).

### The Problem Terraform Actions Solve

**Common Pain Points Before Actions:**

1. **Dependency Hell**: Need to run something after infrastructure exists
   - Create S3 bucket → Upload files → Process files → Create resource using output
   - Create ECS cluster → Build Docker image → Push to ECR → Deploy service
   - Create database → Run migrations → Deploy app

2. **Workarounds Were Messy**:
   - `null_resource` + `local-exec` (hacky, hard to maintain, no progress tracking)
   - External shell scripts (breaks Terraform workflow)
   - Manual CLI commands after `terraform apply` (not automated)
   - Separate CI/CD pipelines (two-step process, coordination nightmare)

3. **Specific to This Module**: AgentCore requires ARM64 binaries/images
   - Most developers use x86_64 machines
   - Local Docker builds produce wrong architecture
   - Can't use native Terraform resources to "build code"
   - Need AWS-managed ARM64 environment (CodeBuild) to build during apply

**How Terraform Actions Help**:
- Native `action` resource type for external operations
- Clean lifecycle integration via `action_trigger`
- Better error handling than `local-exec`
- **Some actions wait for completion** (like `aws_codebuild_start_build`), others are fire-and-forget

### How We Implement Actions in This Module

We use the **`action` resource** (new in Terraform 1.14) to trigger CodeBuild, combined with `terraform_data` + `action_trigger` lifecycle block to control when it runs.

**The Pattern:**

```hcl
# 1. Define the ACTION - what to run
action "aws_codebuild_start_build" "code" {
  config {
    project_name = aws_codebuild_project.runtime_code.name
    timeout      = 900  # 15 minutes
  }
}

# 2. Define the TRIGGER - when to run it
resource "terraform_data" "build_trigger" {
  input = filemd5("./agent.py")  # Re-trigger when source changes
  
  lifecycle {
    action_trigger {
      events  = [after_create, after_update]  # Run after resource created/updated
      actions = [action.aws_codebuild_start_build.code]  # Which action to run
    }
  }
  
  depends_on = [aws_codebuild_project.runtime_code]  # Ensure infra exists first
}
```

**Key Differences from Old Pattern:**
- ✅ `action` resource (not `local-exec` provisioner)
- ✅ `action_trigger` lifecycle block (not `triggers_replace`)
- ✅ **This specific action waits for completion** (shows build status, blocks until done)
- ✅ Better error handling (action failures properly propagate)

### The Flow - CODE Runtime (Python)

```
1. User runs: terraform apply
   └─> Terraform creates resources in dependency order

2. S3 bucket created
   └─> aws_s3_bucket.runtime["my_agent"]

3. Source code zipped locally
   └─> data.archive_file.runtime_source (local operation)

4. Source uploaded to S3 as "source-input.zip"
   └─> aws_s3_object.runtime_source_input

5. CodeBuild project created
   └─> aws_codebuild_project.runtime_code
   └─> Has IAM role with S3 read/write permissions

6. IAM role propagation delay
   └─> time_sleep.iam_role_propagation (15 seconds)

7. Action defined (THIS IS THE KEY PART)
   └─> action "aws_codebuild_start_build" "code"
   └─> config { project_name = ... }
   └─> This is the WHAT (what operation to run)

8. Action trigger created
   └─> terraform_data.build_trigger_code
   └─> input = source file hash (re-triggers when code changes)
   └─> lifecycle { action_trigger { events = [after_create, after_update] } }
   └─> This is the WHEN (when to run the action)
   └─> depends_on ensures infrastructure exists first

9. Terraform automatically:
   └─> Starts CodeBuild via action
   └─> Shows progress updates in terminal
   └─> Waits for build to complete
   └─> Fails terraform apply if build fails

10. CodeBuild runs (in AWS, ARM64 environment)
    └─> Downloads source-input.zip from S3
    └─> Runs: pip install --platform manylinux2014_aarch64 -r requirements.txt -t .
    └─> Zips everything as source.zip (ARM64 binaries)
    └─> Uploads source.zip back to S3

11. Runtime created (AFTER build completes)
    └─> awscc_bedrockagentcore_runtime.runtime_code
    └─> depends_on: [terraform_data.build_trigger_code]
    └─> Points to S3: source.zip (ARM64 version)
```

### Why We Need action + terraform_data (Not Just CodeBuild Resource)

**The Core Issue**: Terraform resources manage **state**, not **actions**.

```hcl
# This creates the CodeBuild PROJECT definition
resource "aws_codebuild_project" "runtime_code" {
  name = "my-build-project"
}
# ❌ This does NOT run a build - it just ensures the project exists
```

**What We Actually Need**:
1. Create CodeBuild project (infrastructure) → `resource`
2. **RUN a build** (action) → `action`
3. **WAIT for build to complete** (blocking) → automatic with actions
4. Use build output in subsequent resources → `depends_on`

There's no Terraform **resource** for steps 2-3. That's where **Actions** come in:

```hcl
# Step 1: Define WHAT to run
action "aws_codebuild_start_build" "build" {
  config {
    project_name = aws_codebuild_project.runtime_code.name
    timeout      = 900
  }
}

# Step 2: Define WHEN to run it
resource "terraform_data" "trigger" {
  input = filemd5("./code.py")  # Re-run when code changes
  
  lifecycle {
    action_trigger {
      events  = [after_create, after_update]
      actions = [action.aws_codebuild_start_build.build]
    }
  }
  
  depends_on = [aws_codebuild_project.runtime_code]
}

# Step 3: Terraform automatically waits for action to complete
# Step 4: Use the output
resource "awscc_bedrockagentcore_runtime" "runtime" {
  # ...
  depends_on = [terraform_data.trigger]  # Waits for build
}
```

### Breaking Down the Components

**1. action Resource (Terraform 1.14+)**
- New resource type specifically for external operations
- Defines WHAT operation to run (e.g., start CodeBuild)
- Includes configuration (project name, timeout, env vars)
- Provider-native (not shell scripts) with type-safe inputs
- **Behavior varies by action**: Some wait for completion (like `aws_codebuild_start_build`), others are fire-and-forget (like some Step Functions actions)

**Synchronous vs Asynchronous Actions:**

**When you need waiting (synchronous) - operations Terraform CANNOT do natively:**
- **Build artifacts** that subsequent resources depend on (our use case - CodeBuild produces ARM64 binaries)
- **Invoke Lambda** for custom logic and use the response
- Any external process where Terraform needs the output to continue, or where you want `terraform apply` to fail if the operation fails

**When fire-and-forget works (asynchronous) - operations Terraform doesn't need to wait for:**
- **Send notifications** (Slack, SNS, email) after deployment
- **Kick off long-running processes** (database migrations, data imports, batch jobs)
- **Trigger external systems** (CI/CD pipelines, monitoring alerts)
- **Start background workflows** (Step Functions that run independently)
- **Deploy applications** as final step (e.g., Helm charts to EKS) when nothing depends on them
- Final cleanup or logging tasks
- Any operation where you want Terraform to succeed even if the action fails (useful for supporting multiple deployment workflows - e.g., Terraform action OR manual Helm deployment OR existing CI/CD pipeline)

**Our use case requires synchronous**: We must wait for CodeBuild to finish producing ARM64 binaries before creating the AgentCore runtime that references them.

**2. action_trigger (Lifecycle Argument)**
- Goes inside a `lifecycle` block on ANY resource that supports lifecycle
- Defines WHEN to run the action
- `events`: Which lifecycle events trigger it (`after_create`, `after_update`, `before_destroy`)
- `actions`: Which action resources to run

**Can be used on any resource:**
```hcl
resource "aws_s3_bucket" "example" {
  bucket = "my-bucket"
  
  lifecycle {
    action_trigger {
      events  = [`after_create`]
      actions = [action.some_action.example]
    }
  }
}
```

**Why we use terraform_data:**
- Designed specifically for orchestration (no actual infrastructure)
- `input` attribute triggers re-runs when value changes (perfect for source code hashes)
- Cleaner than attaching actions to infrastructure resources
- Explicit separation: infrastructure resources vs orchestration logic
- Can be used purely as an action trigger without managing any real resources

**Understanding Terraform Lifecycle Blocks:**

Lifecycle blocks control resource behavior during Terraform operations. Common uses:

```hcl
resource "aws_instance" "example" {
  # ...
  
  lifecycle {
    # Prevent accidental deletion
    prevent_destroy = true
    
    # Ignore changes to specific attributes
    ignore_changes = [tags]
    
    # Create new before destroying old
    create_before_destroy = true
  }
}
```

**action_trigger is a NEW lifecycle block (Terraform 1.14+):**

```hcl
resource "terraform_data" "trigger" {
  input = "..."
  
  lifecycle {
    action_trigger {
      events  = [after_create, after_update, before_destroy]
      actions = [action.aws_codebuild_start_build.build]
    }
  }
}
```

**Available lifecycle events:**

Terraform provides 5 lifecycle event phases for actions:

| Event | When It Runs | Use Case |
|-------|--------------|----------|
| `before_create` | Before resource is created | Pre-creation setup (e.g., validate prerequisites) |
| `after_create` | After resource is created | Post-creation tasks (e.g., initial build, deployment) |
| `before_update` | Before resource is updated | Pre-update tasks (e.g., backup, validation) |
| `after_update` | After resource is updated | Post-update tasks (e.g., rebuild when code changes) |
| `before_destroy` | Before resource is destroyed | Cleanup tasks (e.g., backup data, notify systems) |

**Note**: There is no `after_destroy` event (resource no longer exists).

### CRITICAL: before_create vs after_create and Dependency Chains

**⚠️ This is the most common pitfall when using Terraform Actions with dependencies.**

The choice between `before_create` and `after_create` fundamentally affects how Terraform's dependency graph works:

**With `after_create` (BREAKS DEPENDENCIES):**
```hcl
resource "terraform_data" "build_trigger" {
  lifecycle {
    action_trigger {
      events  = [after_create]  # ❌ Resource completes FIRST
      actions = [action.aws_codebuild_start_build.code]
    }
  }
}

resource "awscc_bedrockagentcore_runtime" "runtime" {
  depends_on = [terraform_data.build_trigger]  # ❌ Doesn't wait for action!
}
```

**Execution order:**
1. `terraform_data.build_trigger` is created and marked **COMPLETE**
2. `awscc_bedrockagentcore_runtime` starts creating (depends_on satisfied)
3. Action runs asynchronously (too late!)
4. Runtime fails: "S3 object not found" (artifact doesn't exist yet)

**With `before_create` (PRESERVES DEPENDENCIES):**
```hcl
resource "terraform_data" "build_trigger" {
  lifecycle {
    action_trigger {
      events  = [before_create]  # ✅ Action runs FIRST
      actions = [action.aws_codebuild_start_build.code]
    }
  }
}

resource "awscc_bedrockagentcore_runtime" "runtime" {
  depends_on = [terraform_data.build_trigger]  # ✅ Waits for action!
}
```

**Execution order:**
1. Action runs and waits for completion (synchronous)
2. `terraform_data.build_trigger` is created and marked **COMPLETE**
3. `awscc_bedrockagentcore_runtime` starts creating (artifact exists)
4. Runtime succeeds

### The Key Insight

Even though the action itself is **synchronous** (it waits for CodeBuild to complete), using `after_create` means:
- The trigger resource completes **before** the action runs
- Dependent resources see the trigger as "done" and start immediately
- The action runs in parallel with dependent resources
- **`depends_on` doesn't wait for the action**

Using `before_create` means:
- The action runs **before** the trigger resource is marked complete
- Dependent resources wait for the trigger to complete
- The trigger only completes after the action finishes
- **`depends_on` correctly waits for the action**

### When to Use Each

**Use `before_create` when:**
- ✅ Dependent resources need artifacts produced by the action (our use case)
- ✅ You want `depends_on` to wait for the action to complete
- ✅ The action must complete before infrastructure can be used
- ✅ Failures should block dependent resource creation

**Use `after_create` when:**
- ✅ Action is fire-and-forget (notifications, logging)
- ✅ No resources depend on the action's output
- ✅ Action can run in parallel with other resources
- ✅ Action failures shouldn't block infrastructure creation

### Real-World Example: The Bug We Hit

Initial implementation used `after_create`:
```hcl
lifecycle {
  action_trigger {
    events  = [after_create, after_update]  # ❌ WRONG
    actions = [action.aws_codebuild_start_build.code]
  }
}
```

**Symptoms:**
- CodeBuild action completed successfully
- Terraform logs showed "Action complete"
- Runtime resource failed: "S3 object not found"
- Despite explicit `depends_on`, resources created in parallel

**Root cause:**
- `terraform_data` completed before action ran
- Runtime started creating while CodeBuild was still running
- By the time CodeBuild finished, runtime had already failed

**Fix:**
```hcl
lifecycle {
  action_trigger {
    events  = [before_create, before_update]  # ✅ CORRECT
    actions = [action.aws_codebuild_start_build.code]
  }
}
```

**Result:**
- Action runs and waits for CodeBuild completion
- `terraform_data` completes after action finishes
- Runtime waits for `terraform_data` via `depends_on`
- Artifact exists when runtime is created
- Everything works!

### Debugging Tips

If you see "artifact not found" errors despite using actions:

1. **Check your action_trigger events:**
   ```bash
   grep -r "action_trigger" *.tf
   # Look for after_create - should be before_create for build actions
   ```

2. **Verify execution order in logs:**
   ```
   # WRONG order (after_create):
   terraform_data.trigger: Creating...
   terraform_data.trigger: Creation complete
   Action started: ...
   dependent_resource: Creating...  # ❌ Too early!
   Action complete: ...
   
   # CORRECT order (before_create):
   Action started: ...
   Action complete: ...
   terraform_data.trigger: Creating...
   terraform_data.trigger: Creation complete
   dependent_resource: Creating...  # ✅ After action!
   ```

3. **Check depends_on chains:**
   ```hcl
   # Ensure dependent resources reference the trigger
   resource "awscc_bedrockagentcore_runtime" "runtime" {
     depends_on = [terraform_data.build_trigger]  # Must be present
   }
   ```

### Documentation Gap

The official Terraform documentation explains *when* actions run relative to resource lifecycle, but doesn't explicitly call out how this affects the dependency graph and `depends_on` behavior. This is a common source of confusion for users implementing actions with build pipelines.

**How we use it:****
**How we use it:**
```hcl
lifecycle {
  action_trigger {
    events  = [before_create, before_update]  # Run BEFORE resource completes
    actions = [action.aws_codebuild_start_build.code]
  }
}
```

**Why `before_create` and `before_update`?**
- `before_create`: Build ARM64 binaries BEFORE terraform_data completes (preserves dependency chain)
- `before_update`: Rebuild when source code changes (detected via `input` hash change)
- NOT `after_create`: Would break dependency chain - runtime would start before build completes
- NOT `before_destroy`: No need to rebuild when destroying

**Example flow:**
1. First `terraform apply` → Action runs → `terraform_data` created → `after_create` would be too late, `before_create` ensures action completes first
2. Change `agent.py` → `input` hash changes → `terraform apply` → Action runs → `terraform_data` updated → `before_update` ensures rebuild completes before dependent resources update
3. `terraform destroy` → `before_destroy` event (if configured) → cleanup action runs

**3. terraform_data Resource (Terraform 1.4+)**
- Built-in replacement for `null_resource` (no provider needed)
- Container for the action trigger
- `input`: Value that causes re-trigger when changed (like source code hash)
- When `input` changes, Terraform re-runs the action
- Better semantics than `null_resource` (uses `input`/`output` vs `triggers`)

**terraform_data vs null_resource:**

`null_resource` (legacy, still works):
```hcl
resource "null_resource" "example" {
  triggers = { hash = filemd5("file.txt") }
  provisioner "local-exec" { command = "..." }
}
```
- ❌ Requires external provider (`hashicorp/null`)
- ❌ Uses `triggers` (less clear intent)
- ❌ No built-in input/output attributes
- ⚠️ Still works but deprecated

`terraform_data` (modern, recommended):
```hcl
resource "terraform_data" "example" {
  input = filemd5("file.txt")
  lifecycle {
    action_trigger { ... }
  }
}
```
- ✅ Built into Terraform (no provider needed)
- ✅ Uses `input`/`output` (clearer semantics)
- ✅ Designed for orchestration and actions
- ✅ Official HashiCorp recommendation

**Why we use terraform_data:**
- Modern, built-in solution (Terraform 1.4+)
- Cleaner syntax for action triggers
- No external dependencies
- Better state management with `input`/`output`

**4. depends_on**
- Ensures infrastructure exists before action runs
- Critical for correct execution order
- Action won't run until all dependencies are ready

### Ways to Trigger Actions

**1. Automatic Triggering (What We Use)**

Actions run automatically during `terraform apply` when lifecycle events occur:

```hcl
resource "terraform_data" "build_trigger" {
  input = filemd5("./agent.py")  # Change this value = trigger action
  
  lifecycle {
    action_trigger {
      events  = [after_create, after_update]
      actions = [action.aws_codebuild_start_build.code]
    }
  }
}
```

**When it runs:**
- `terraform apply` (first time) → `after_create` event → action runs
- Change `agent.py` → `input` hash changes → `terraform apply` → `after_update` event → action runs
- `terraform destroy` → `before_destroy` event → action runs (if configured)

**2. Manual Invocation**

You can manually invoke actions using the `-invoke` flag with `terraform plan` or `terraform apply`:

```bash
# Plan an action invocation (preview what will happen)
terraform plan -invoke=action.aws_codebuild_start_build.code

# Execute an action immediately
terraform apply -invoke=action.aws_codebuild_start_build.code
```

**Important**: The `-invoke` flag is **NOT supported** with `terraform destroy`. For cleanup actions during destroy, use lifecycle `action_trigger` with `before_destroy` events instead.

**Key characteristics of manual invocation:**
- **Isolated execution**: Runs only the specified action, excludes all other configurations
- **No state changes**: Action executes without affecting Terraform state
- **Immediate execution**: Runs directly without normal plan/apply workflow for resources
- **Only for plan/apply**: Not available for `terraform destroy`

**Use cases for manual invocation:**
- Testing actions before integrating them into lifecycle triggers
- Re-running a build without changing source code
- Debugging action behavior in isolation
- One-off administrative tasks (e.g., manual deployment to production)
- Running actions on-demand outside of infrastructure changes

**Comparison:**

| Method | When | Use Case |
|--------|------|----------|
| Automatic (lifecycle) | During `terraform apply/destroy` | Normal workflow, triggered by changes |
| Manual (`terraform invoke`) | On-demand, anytime | Testing, debugging, manual operations |

**Why we use automatic triggering:**
- Integrated into normal Terraform workflow
- Runs when source code changes (via `input` hash)
- No manual intervention needed
- Ensures builds happen before dependent resources are created

### Why action Instead of local-exec?

**Old Way (null_resource + local-exec):**
```hcl
resource "null_resource" "build" {
  triggers = { hash = "..." }
  provisioner "local-exec" {
    command = "aws codebuild start-build ... && poll-until-done"
  }
}
```
- ❌ Manual polling loop required
- ❌ No progress updates during build
- ❌ Error handling is manual (parsing shell output)
- ❌ Platform-dependent (shell scripts)
- ❌ Requires external provider (`hashicorp/null`)

**New Way (terraform_data + action):**
```hcl
action "aws_codebuild_start_build" "build" {
  config { project_name = "..." }
}

resource "terraform_data" "trigger" {
  input = "..."
  lifecycle {
    action_trigger {
      events  = [after_create, after_update]
      actions = [action.aws_codebuild_start_build.build]
    }
  }
}
```
- ✅ **This action waits for completion** (no polling loop needed)
- ✅ Progress updates in Terraform output
- ✅ Built-in error handling (structured responses)
- ✅ Platform-independent (provider-native)
- ✅ Type-safe configuration
- ✅ Idempotent by design (provider handles retries)

**Note**: Not all actions wait for completion. `aws_codebuild_start_build` is synchronous (waits), but some actions (like certain Step Functions actions) are fire-and-forget. Check provider documentation for specific action behavior.

### The Complete Dependency Chain

```
User Code (./src/agent.py)
  ↓
archive_file (zip locally)
  ↓
S3 bucket + S3 object (upload source-input.zip)
  ↓
CodeBuild project + IAM role + IAM policy
  ↓
time_sleep (IAM propagation)
  ↓
action "aws_codebuild_start_build" (WHAT to run)
  ↓
terraform_data + action_trigger (WHEN to run, START BUILD, WAIT)
  ↓ (CodeBuild runs in AWS, produces source.zip with ARM64 binaries)
  ↓
Runtime resource (reads source.zip from S3)
  ↓
Runtime Endpoint
```

### CONTAINER Runtime Flow (Similar but Different)

```
User Code (./src/Dockerfile, ./src/app.py)
  ↓
archive_file (zip locally)
  ↓
S3 bucket + S3 object (upload source.zip)
  ↓
ECR repository + CodeBuild project + IAM role
  ↓
time_sleep (IAM propagation)
  ↓
action "aws_codebuild_start_build" (WHAT to run)
  ↓
terraform_data + action_trigger (WHEN to run, START BUILD, WAIT)
  ↓ (CodeBuild runs: docker build --platform linux/arm64, docker push to ECR)
  ↓
Runtime resource (pulls ARM64 image from ECR)
  ↓
Runtime Endpoint
```

### Why This Approach?

**The Challenge**: Terraform manages infrastructure state, but we need to orchestrate a build process:
1. Create infrastructure (S3, CodeBuild, IAM)
2. Upload source code
3. **Trigger build** (action)
4. **Wait for async build to complete** (blocking)
5. Use build output (ARM64 binaries/images)

**Why Not Alternatives?**

Terraform Actions with CodeBuild is the cleanest solution:
- ✅ Single `terraform apply` command
- ✅ No Docker required locally
- ✅ ARM64 builds guaranteed (AWS Graviton)
- ✅ Works in any environment with AWS CLI
- ✅ Integrated into Terraform lifecycle
- ⚠️ Complex implementation (but hidden from users)

### Alternative Approaches We Rejected

**Option 1: Pre-build locally with Docker**
```bash
# User would need to run before terraform apply
docker buildx build --platform linux/arm64 ...
```
- ❌ Requires Docker installed
- ❌ Requires ARM64 emulation (slow, error-prone)
- ❌ Breaks in CI/CD without Docker
- ❌ Manual step before Terraform

**Option 2: Separate CI/CD pipeline**
```bash
# Step 1: Build in CI/CD
./build.sh
# Step 2: Run Terraform
terraform apply
```
- ❌ Two-step process (coordination required)
- ❌ External build system needed
- ❌ Not "terraform apply and done"
- ❌ Build artifacts must be managed separately

**Option 3: Lambda to trigger CodeBuild**
- ❌ More resources to manage (Lambda, EventBridge, etc.)
- ❌ Still need to wait for build (how?)
- ❌ Adds complexity without solving core problem
- ❌ Terraform still needs to know when build completes

**Option 4: null_resource (old pattern)**
```hcl
resource "null_resource" "build" {
  provisioner "local-exec" { ... }
}
```
- ⚠️ Works but deprecated
- ⚠️ Requires null provider
- ⚠️ Not designed for Actions pattern

### Key Takeaways for Module Developers

1. **Terraform Actions = Built-in Feature (1.14+)**
   - New `action` resource type for external operations
   - `action_trigger` lifecycle block for triggering
   - Replaces hacky `null_resource` + `local-exec` patterns
   - Still maturing (GA in 1.14, but newer than core features)

2. **Why We Use Actions Here**
   - Bridge infrastructure creation → build process → deployment
   - Trigger CodeBuild (external process) during `terraform apply`
   - Automatic waiting for async builds (no manual polling)
   - Ensure ARM64 compatibility without local Docker

3. **Implementation Pattern**
   - `action "aws_codebuild_start_build"` = Define WHAT to run
   - `terraform_data` + `action_trigger` = Define WHEN to run
   - `input` = Re-trigger when value changes (source code hash)
   - `depends_on` = Ensure correct execution order
   - `terraform_data` provides explicit orchestration layer

4. **The Magic**
   - User runs `terraform apply` once
   - Module orchestrates: upload → trigger action → wait → deploy
   - Terraform shows build progress in real-time
   - ARM64 builds happen automatically in AWS
   - No Docker, no manual steps, no external CI/CD

5. **Production Readiness**
   - ✅ Actions are GA and stable in Terraform 1.14+
   - ✅ AWS provider has good action coverage
   - ⚠️ Newer than core features - test thoroughly
   - ✅ More robust than `local-exec` (provider-native, type-safe)
   - Best practice: Test in non-prod, monitor logs, use explicit `depends_on`

6. **Common Pitfalls**
   - Forgetting `depends_on` (action runs before infrastructure ready)
   - Not waiting for IAM propagation (15-30s delays needed)
   - Wrong `input` value (rebuilds too often or not at all)
   - Missing `after_update` event (action won't re-run on changes)

### Critical: Artifact Availability After CodeBuild Completion

**The Core Issue: CodeBuild SUCCESS ≠ Artifact Availability**

Terraform Actions correctly wait for CodeBuild to complete, but there's an asynchronous gap between build completion and artifact availability:

```
CodeBuild marks build SUCCESS
  ↓ (asynchronous upload phase)
Artifacts uploaded to S3/ECR
  ↓ (eventual consistency delay)
Artifacts readable via S3/ECR API
```

**Why This Happens:**

1. **CodeBuild reports SUCCESS** when the build process completes
2. **Artifact upload is asynchronous** - happens after SUCCESS status
3. **S3/ECR have eventual consistency** - objects may not be immediately readable
4. **Terraform Actions only wait for build completion** - not artifact availability

**This is NOT a Terraform Actions bug** - it's expected AWS behavior. Actions correctly wait for CodeBuild, but cannot know when downstream storage (S3/ECR) is ready.

### Our Solution: Verification in BuildSpec

We add verification steps to the CodeBuild buildspec to ensure artifacts are available before CodeBuild reports SUCCESS:

**For CODE runtimes (S3):**
```yaml
post_build:
  commands:
    - aws s3 cp /tmp/runtime.zip s3://$S3_BUCKET/source.zip
    - echo Verifying artifact availability in S3...
    - aws s3api head-object --bucket $S3_BUCKET --key source.zip
    - echo Artifact confirmed available in S3
```

**For CONTAINER runtimes (ECR):**
```yaml
post_build:
  commands:
    - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
    - echo Verifying image availability in ECR...
    - aws ecr describe-images --repository-name $IMAGE_REPO_NAME --image-ids imageTag=$IMAGE_TAG
    - echo Image confirmed available in ECR
```

**How This Works:**

1. CodeBuild uploads artifact (S3 object or ECR image)
2. CodeBuild **verifies artifact is readable** via AWS API
3. Only then does CodeBuild report SUCCESS
4. Terraform Action completes
5. Subsequent resources can safely reference the artifact

**Benefits:**

- ✅ No race conditions - artifacts verified before Terraform proceeds
- ✅ Minimal delays - only waits as long as necessary
- ✅ Clear error messages - verification failures show in CodeBuild logs
- ✅ Reliable - verification is part of the build process

### Why We Still Use time_sleep (Minimal)

Even with verification, we keep small delays (5s) as a safety buffer:

```hcl
resource "time_sleep" "s3_object_availability" {
  create_duration = "5s"
  depends_on = [terraform_data.build_trigger_code]
}
```

This handles edge cases where:
- S3/ECR API might be eventually consistent across regions
- AgentCore API might be in a different region than S3/ECR
- Brief propagation delays between AWS services

**5 seconds is sufficient** because the buildspec already verified availability - this is just a conservative buffer.

### Data Source for S3 Objects

For CODE runtimes, we also use a data source to get the version_id:

```hcl
data "aws_s3_object" "runtime_source_output" {
  bucket = aws_s3_bucket.runtime[each.key].id
  key    = "source.zip"
  depends_on = [time_sleep.s3_object_availability]
}
```

This serves two purposes:
1. **Explicit versioning** - provides `version_id` for the runtime resource
2. **Additional verification** - Terraform actively polls S3 until readable

### Alternative Approaches Considered

**Option 1: Longer static waits (30-60s)**
- ❌ Unreliable - may work sometimes but not guaranteed
- ❌ Slow - wastes time even when artifacts are ready quickly
- ❌ Doesn't scale - large artifacts might need even longer

**Option 2: Retry logic in data sources**
- ⚠️ Terraform has some built-in retries, but not configurable
- ⚠️ Doesn't prevent the initial failure
- ⚠️ Still requires verification that artifact exists

**Option 3: Separate terraform apply stages**
- ❌ Poor UX - requires users to run apply twice
- ❌ Doesn't solve the root problem
- ❌ Breaks single-command deployment

**Option 4: Verification in buildspec (our choice)**
- ✅ Most reliable - CodeBuild doesn't succeed until artifacts are verified
- ✅ Minimal delays - only waits as long as necessary
- ✅ Clear errors - verification failures show in build logs
- ✅ Best practice - recommended by AWS for production workflows

### Key Takeaway

Terraform Actions work correctly - they wait for CodeBuild to complete. The issue is that **CodeBuild completion ≠ artifact availability** due to asynchronous uploads and eventual consistency. By adding verification to the buildspec, we ensure CodeBuild only reports SUCCESS when artifacts are truly available.

## IAM Role Propagation

AWS IAM roles take time to propagate (typically 5-15 seconds). Resources that use IAM roles must wait:

```hcl
resource "time_sleep" "iam_role_propagation" {
  create_duration = "15s"
  depends_on      = [aws_iam_role.runtime]
}

resource "awscc_bedrockagentcore_runtime" "runtime_code" {
  role_arn = aws_iam_role.runtime.arn
  depends_on = [time_sleep.iam_role_propagation]
}
```

Resources that need IAM propagation delays:
- Runtimes (15s)
- Browsers (30s)
- Code Interpreters (30s)
- Gateways (15s for policy)
- Memory (needs depends_on)

## IAM Eventual Consistency - Why time_sleep Is Required

### The Problem

AWS IAM is **eventually consistent** across all AWS regions. When you create an IAM role or attach a policy, it takes several seconds (typically 5-30s) to propagate globally. If a resource tries to assume the role immediately, it fails with:

- "Invalid request provided: Please provide a role with a valid trust policy"
- "Access Denied"
- "Role not found"

This is **AWS's design**, not a Terraform limitation. See [AWS IAM Eventual Consistency Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html#troubleshoot_general_eventual-consistency).

### Why AWSCC Provider Requires time_sleep

This module uses the **AWS Cloud Control API (AWSCC) provider** for AgentCore resources because:

1. AgentCore is a new service only available via Cloud Control API
2. The standard AWS provider doesn't support these resources yet
3. **AWSCC provider lacks built-in retry logic** that the standard AWS provider has
4. **AWSCC resources don't support `timeouts` blocks** for custom wait times

Therefore, `time_sleep` resources are the **only solution** for handling IAM propagation with AWSCC provider resources.

### Implementation Pattern

For every IAM role that's immediately used by an AWSCC resource:

```hcl
# 1. Create IAM role
resource "aws_iam_role" "example" {
  name               = "example-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# 2. Attach policies
resource "aws_iam_role_policy" "example" {
  role   = aws_iam_role.example.name
  policy = data.aws_iam_policy_document.policy.json
}

# 3. Wait for propagation (10-30s depending on resource)
resource "time_sleep" "iam_propagation" {
  create_duration = "10s"
  depends_on = [aws_iam_role_policy.example]
}

# 4. Use role in AWSCC resource
resource "awscc_bedrockagentcore_runtime" "example" {
  role_arn = aws_iam_role.example.arn
  depends_on = [time_sleep.iam_propagation]
}
```

### Resources with IAM Propagation Delays

All AgentCore resources that use IAM roles have propagation delays:

| Resource | Delay | time_sleep Resource |
|----------|-------|--------------------|
| Runtime | 10s | `time_sleep.iam_role_propagation` |
| Memory | 10s | `time_sleep.memory_iam_role_propagation` |
| Gateway | 15s | `time_sleep.gateway_iam_policy_propagation` |
| Browser | 30s | `time_sleep.browser_iam_role_propagation` |
| Code Interpreter | 30s | `time_sleep.code_interpreter_iam_role_propagation` |
| CodeBuild | 10s | `time_sleep.codebuild_iam_propagation` |

### Why Different Delay Times?

- **10s**: Simple role creation (Runtime, Memory, CodeBuild)
- **15s**: Role + policy attachment (Gateway)
- **30s**: Complex resources with additional permissions (Browser, Code Interpreter)

These are conservative values based on AWS documentation and testing. Shorter delays may work but risk intermittent failures.

### Alternative Approaches (Not Viable for AWSCC)

1. **timeouts block**: Not supported by AWSCC provider
2. **Data source trick**: Doesn't help when creating new roles
3. **Decoupled apply**: Requires users to run `terraform apply` twice (poor UX)
4. **Provider retries**: AWSCC provider doesn't have automatic retry logic like standard AWS provider

### Why This Isn't "Hacky"

`time_sleep` is the **documented solution** for IAM eventual consistency with Cloud Control API resources. It's used in production by:

- AWS-maintained Terraform modules
- HashiCorp's official examples
- Major open-source Terraform modules (terraform-aws-modules/*)

It's not a workaround - it's the correct implementation pattern for AWSCC provider resources.

### References

- [AWS IAM Eventual Consistency](https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html#troubleshoot_general_eventual-consistency)
- [Terraform time_sleep Resource](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep)
- [AWS Cloud Control API](https://docs.aws.amazon.com/cloudcontrolapi/latest/userguide/what-is-cloudcontrolapi.html)

## Testing

Tests use `terraform test` (Terraform 1.14+):
- Each test file is isolated
- Resources are automatically torn down after each test
- Tests run from root module, reference examples

Common test failures:
- IAM propagation (add `depends_on` or `time_sleep`)
- CodeBuild failures (check logs with `aws codebuild batch-get-builds`)
- Resource naming mismatches (test expects `my_agent`, code has `my-agent`)
- Artifact availability (ensure buildspec has verification steps)

## Module Structure

```
.
├── main.tf              # Runtime resources
├── memory.tf            # Memory resources
├── gateway.tf           # Gateway + Gateway Target resources
├── browser.tf           # Browser resources
├── code_interpreter.tf  # Code Interpreter resources
├── codebuild.tf         # CodeBuild projects + Terraform Actions
├── iam.tf               # IAM roles and policies
├── debug.tf             # Debug mode (.env generation)
├── outputs.tf           # Module outputs
├── variables.tf         # Input variables
├── versions.tf          # Provider requirements
└── examples/
    ├── basic-code-runtime/
    ├── basic-container-runtime/
    └── complete/
```

## Adding New Resources

1. Create new `.tf` file (e.g., `new_resource.tf`)
2. Add IAM role in `iam.tf`
3. Add time_sleep if needed
4. Add outputs in `outputs.tf`
5. Add variables in `variables.tf`
6. Update examples
7. Add tests
8. Update documentation
