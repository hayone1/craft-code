# Craft workspace on Docker: one container per workspace with VS Code in the browser (code-server),
# Claude Code and the Craft Apps extension. The craft apps and the craft-mcp relay run next to the
# Coder server in the same Docker Compose project, and every workspace joins that project's network.
# The bootstrap script (files/bootstrap.sh in the craft-coder chart) pushes this template and fills in the
# variables; to push it by hand, pass the same variables with `coder templates push --variable`.
terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

# The Coder server talks to the Docker daemon through /var/run/docker.sock.
provider "docker" {}

variable "workspace_image" {
  type        = string
  description = "The workspace image: code-server, Node, Claude Code and the craft CLIs"
  default     = "hayone/craft-code:workspace"
}

variable "docker_network" {
  type        = string
  description = "The Docker network of the Compose project, so a workspace reaches the apps, the relay and Coder by name"
  default     = "craft-coder"
}

variable "coder_internal_url" {
  type        = string
  description = "The Coder server's address inside the Docker network, e.g. http://coder:7080. Empty: the agent uses the public address."
  default     = ""
}

variable "craft_app_url" {
  type        = string
  description = "Where the craft apps are; {app} stands for the app's name"
  default     = "http://{app}:8080/"
}

variable "craft_relay_url" {
  type        = string
  description = "The craft-mcp relay, as the workspace reaches it"
  default     = "http://craft-mcp:8080"
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

data "coder_provisioner" "me" {}
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

locals {
  project_dir = "/home/coder/project"
  # The agent downloads itself from the Coder server and connects back. Inside the Docker network
  # the public address may not work (a home server behind NAT, or localhost), so use the inside one.
  init_script = var.coder_internal_url == "" ? coder_agent.main.init_script : replace(coder_agent.main.init_script, data.coder_workspace.me.access_url, var.coder_internal_url)
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

# The home folder: projects, settings, extensions and the Claude Code sign-in. Deleting the
# workspace deletes the volume; stopping it keeps the volume.
resource "docker_volume" "home" {
  name = "coder-${data.coder_workspace.me.id}-home"
  lifecycle {
    ignore_changes = all
  }
  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
}

# Pulled when missing. A newer image reaches workspaces when the template is pushed again.
resource "docker_image" "workspace" {
  name         = var.workspace_image
  keep_locally = true
}

resource "docker_container" "workspace" {
  count    = data.coder_workspace.me.start_count
  image    = docker_image.workspace.image_id
  name     = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
  hostname = lower(data.coder_workspace.me.name)
  user     = "1000:1000"
  # The image's own entrypoint starts a whole studio; a workspace only runs the Coder agent.
  entrypoint = ["sh", "-c", local.init_script]
  env = [
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
    "HOME=/home/coder",
    # No Docker inside workspaces; otherwise the agent logs docker.sock errors.
    "CODER_AGENT_DEVCONTAINERS_ENABLE=false",
  ]
  networks_advanced {
    name = var.docker_network
  }
  volumes {
    container_path = "/home/coder"
    volume_name    = docker_volume.home.name
    read_only      = false
  }
  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
}
