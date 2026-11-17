# Craft workspace on Kubernetes: one pod per workspace with VS Code in the browser (code-server),
# Claude Code and the Craft Apps extension. The craft apps and the craft-mcp relay run as Services
# next to the Coder server, installed by the craft-coder Helm chart. The chart's bootstrap job
# (files/bootstrap.sh) pushes this template and fills in the variables.
terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

# The Coder server runs in the cluster and uses its own service account.
provider "kubernetes" {}

variable "namespace" {
  type        = string
  description = "The namespace for the workspaces. Coder's service account must manage pods, deployments and PVCs there."
}

variable "storage_class" {
  type        = string
  description = "The StorageClass of the home volumes. Empty: the cluster's default."
  default     = ""
}

variable "workspace_image" {
  type        = string
  description = "The workspace image: code-server, Node, Claude Code and the craft CLIs"
  default     = "hayone/craft-code:workspace"
}

variable "coder_internal_url" {
  type        = string
  description = "The Coder server's address inside the cluster, e.g. http://coder.craft.svc. Empty: the agent uses the public address."
  default     = ""
}

variable "craft_app_url" {
  type        = string
  description = "Where the craft apps are; {app} stands for the app's name, e.g. http://craft-{app}.craft.svc:8080/"
}

variable "craft_apps" {
  type        = string
  description = "The craft apps that run next to Coder, comma separated; the Craft Apps extension lists these"
  default     = "photocraft,vectorcraft,lightcraft,filmcraft,effectcraft,wordcraft,gridcraft,deckcraft"
}

variable "craft_relay_url" {
  type        = string
  description = "The craft-mcp relay, as the workspace reaches it"
}

variable "craft_relay_token" {
  type        = string
  description = "One of the relay's MINT_TOKENS (it can only make relay connections)"
  default     = ""
  sensitive   = true
}

variable "subdomain" {
  type        = bool
  description = "Serve VS Code on its own subdomain. Needs CODER_WILDCARD_ACCESS_URL on the server."
  default     = false
}

data "coder_parameter" "cpu" {
  name         = "cpu"
  display_name = "CPU"
  description  = "CPU cores the workspace may use at most."
  type         = "number"
  default      = "2"
  mutable      = true
  order        = 1
  option {
    name  = "1 core"
    value = "1"
  }
  option {
    name  = "2 cores"
    value = "2"
  }
  option {
    name  = "4 cores"
    value = "4"
  }
}

data "coder_parameter" "memory" {
  name         = "memory"
  display_name = "Memory"
  description  = "Memory the workspace may use at most."
  type         = "number"
  default      = "4"
  mutable      = true
  order        = 2
  option {
    name  = "2 GB"
    value = "2"
  }
  option {
    name  = "4 GB"
    value = "4"
  }
  option {
    name  = "8 GB"
    value = "8"
  }
}

# The home folder's size. A volume can grow but never shrink, so the value can only go up.
data "coder_parameter" "storage" {
  name         = "storage"
  display_name = "Storage"
  description  = "Space for your home folder (/home/coder), where your projects and settings are kept. You can raise it later, but you can't lower it."
  type         = "number"
  default      = "10"
  mutable      = true
  order        = 3
  option {
    name  = "10 GB"
    value = "10"
  }
  option {
    name  = "20 GB"
    value = "20"
  }
  option {
    name  = "50 GB"
    value = "50"
  }
  validation {
    monotonic = "increasing"
  }
}

data "coder_provisioner" "me" {}
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

locals {
  project_dir = "/home/coder/project"
  # The agent downloads itself from the Coder server and connects back, over the inside address.
  init_script = var.coder_internal_url == "" ? coder_agent.main.init_script : replace(coder_agent.main.init_script, data.coder_workspace.me.access_url, var.coder_internal_url)
  labels = {
    "app.kubernetes.io/name"     = "coder-workspace"
    "app.kubernetes.io/instance" = "coder-workspace-${data.coder_workspace.me.id}"
    "app.kubernetes.io/part-of"  = "craft-coder"
    "com.coder.resource"         = "true"
    "com.coder.workspace.id"     = data.coder_workspace.me.id
    "com.coder.user.id"          = data.coder_workspace_owner.me.id
    "com.coder.user.username"    = data.coder_workspace_owner.me.name
  }
}

resource "coder_agent" "main" {
  arch           = data.coder_provisioner.me.arch
  os             = "linux"
  dir            = local.project_dir
  startup_script = <<-EOT
    set -e
    mkdir -p ${local.project_dir}
    # Craft Apps from Open VSX, newest release at every start. The version must be named:
    # --install-extension <id> --force keeps an installed copy, however old.
    v=$(curl -fsS --max-time 20 https://open-vsx.org/api/hayone1/craft-vscode | jq -r '.version // empty' 2>/dev/null || true)
    code-server --install-extension "hayone1.craft-vscode$${v:+@$v}" --force >/dev/null 2>&1 || true
    # The Claude Code command line, in the home volume. It updates itself.
    command -v claude >/dev/null || [ -x ~/.local/bin/claude ] || curl -fsSL https://claude.ai/install.sh | bash || true
  EOT

  env = {
    GIT_AUTHOR_NAME     = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_AUTHOR_EMAIL    = data.coder_workspace_owner.me.email
    GIT_COMMITTER_NAME  = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_COMMITTER_EMAIL = data.coder_workspace_owner.me.email
    # The Craft Apps extension: where the apps and the relay are.
    CRAFT_APP_URL     = var.craft_app_url
    CRAFT_APPS        = var.craft_apps
    CRAFT_RELAY_URL   = var.craft_relay_url
    CRAFT_RELAY_TOKEN = var.craft_relay_token
  }

  metadata {
    display_name = "CPU"
    key          = "cpu"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }
  metadata {
    display_name = "Memory"
    key          = "mem"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }
  metadata {
    display_name = "Home disk"
    key          = "home"
    script       = "coder stat disk --path /home/coder"
    interval     = 60
    timeout      = 5
  }
}

module "code-server" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/code-server/coder"
  version  = "~> 1.0"
  agent_id = coder_agent.main.id
  folder   = local.project_dir
  # code-server is in the image, so a start downloads nothing.
  install_prefix        = "/usr/lib/code-server"
  use_cached            = true
  use_cached_extensions = true
  subdomain             = var.subdomain
  extensions            = ["anthropic.claude-code", "hayone1.craft-vscode"]
  settings = {
    "workbench.colorTheme"             = "Default Dark Modern"
    "workbench.startupEditor"          = "none"
    "files.autoSave"                   = "afterDelay"
    "security.workspace.trust.enabled" = false
    "claudeCode.preferredLocation"     = "panel"
  }
  order = 1
}

# The home folder. Raising the "Storage" value grows the volume in place. Deleting the workspace
# deletes the volume; stopping it keeps the volume.
resource "kubernetes_persistent_volume_claim_v1" "home" {
  metadata {
    name      = "coder-${data.coder_workspace.me.id}-home"
    namespace = var.namespace
    labels    = local.labels
  }
  wait_until_bound = false
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.storage_class == "" ? null : var.storage_class
    resources {
      requests = {
        storage = "${data.coder_parameter.storage.value}Gi"
      }
    }
  }
  # Only the size may change: nothing in a template change may replace the volume.
  lifecycle {
    ignore_changes = [metadata[0].labels, metadata[0].annotations, spec[0].access_modes, spec[0].storage_class_name]
  }
}

resource "kubernetes_deployment_v1" "main" {
  count            = data.coder_workspace.me.start_count
  depends_on       = [kubernetes_persistent_volume_claim_v1.home]
  wait_for_rollout = false
  metadata {
    name      = "coder-${data.coder_workspace.me.id}"
    namespace = var.namespace
    labels    = local.labels
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/instance" = "coder-workspace-${data.coder_workspace.me.id}"
      }
    }
    # The home volume is ReadWriteOnce: the old pod must stop before a new one starts.
    strategy {
      type = "Recreate"
    }
    template {
      metadata {
        labels = local.labels
      }
      spec {
        hostname                         = lower(data.coder_workspace.me.name)
        automount_service_account_token  = false
        enable_service_links             = false
        termination_grace_period_seconds = 30
        security_context {
          run_as_user            = 1000
          run_as_group           = 1000
          fs_group               = 1000
          run_as_non_root        = true
          fs_group_change_policy = "OnRootMismatch"
        }
        container {
          name              = "dev"
          image             = var.workspace_image
          image_pull_policy = "Always"
          command           = ["sh", "-c", local.init_script]
          env {
            name  = "CODER_AGENT_TOKEN"
            value = coder_agent.main.token
          }
          env {
            name  = "HOME"
            value = "/home/coder"
          }
          # No Docker inside workspaces; otherwise the agent logs docker.sock errors.
          env {
            name  = "CODER_AGENT_DEVCONTAINERS_ENABLE"
            value = "false"
          }
          resources {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
            limits = {
              cpu    = data.coder_parameter.cpu.value
              memory = "${data.coder_parameter.memory.value}Gi"
            }
          }
          volume_mount {
            name       = "home"
            mount_path = "/home/coder"
          }
        }
        volume {
          name = "home"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.home.metadata[0].name
          }
        }
      }
    }
  }
}
