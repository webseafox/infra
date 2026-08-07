#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=0

# ========= helpers =========
print_help() {
  cat <<'EOF'
Uso: ./setup-wsl-cli.sh [opções]

Opções:
  -n, --dry-run   Mostra os comandos que seriam executados, sem instalar nada
  -h, --help      Exibe esta ajuda
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--dry-run)
        DRY_RUN=1
        shift
        ;;
      -h|--help)
        print_help
        exit 0
        ;;
      *)
        echo "Opção inválida: $1"
        print_help
        exit 1
        ;;
    esac
  done
}

run_cmd() {
  local cmd="$1"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] $cmd"
  else
    eval "$cmd"
  fi
}

ask_yes_no() {
  local prompt="$1"
  local default="${2:-Y}" # Y ou N
  local answer

  while true; do
    if [[ "$default" == "Y" ]]; then
      read -r -p "$prompt [Y/n]: " answer
      answer="${answer:-Y}"
    else
      read -r -p "$prompt [y/N]: " answer
      answer="${answer:-N}"
    fi

    case "${answer,,}" in
      y|yes|s|sim) return 0 ;;
      n|no|nao|não) return 1 ;;
      *) echo "Resposta inválida. Digite y/n." ;;
    esac
  done
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

run_apt_update_once() {
  if [[ "${APT_UPDATED:-0}" -eq 0 ]]; then
    run_cmd "sudo apt-get update -y"
    APT_UPDATED=1
  fi
}

ensure_base_packages() {
  run_apt_update_once
  run_cmd "sudo apt-get install -y ca-certificates curl wget gnupg lsb-release unzip jq software-properties-common git"
}

ensure_nodejs() {
  if need_cmd node && need_cmd npm; then
    echo "Node.js/npm já instalados: $(node -v), $(npm -v)"
    return
  fi

  echo "Instalando Node.js 20.x..."
  run_cmd "curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -"
  APT_UPDATED=0
  run_apt_update_once
  run_cmd "sudo apt-get install -y nodejs"
}

ensure_github_cli() {
  if need_cmd gh; then
    echo "GitHub CLI já instalado: $(gh --version | head -n1)"
    return
  fi

  echo "Instalando GitHub CLI..."
  run_cmd "curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg >/dev/null"
  run_cmd "sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg"

  run_cmd "echo 'deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main' | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null"

  APT_UPDATED=0
  run_apt_update_once
  run_cmd "sudo apt-get install -y gh"
}

install_docker() {
  if need_cmd docker; then
    echo "Docker já instalado: $(docker --version)"
    return
  fi

  echo "Instalando Docker..."
  run_cmd "sudo install -m 0755 -d /etc/apt/keyrings"
  run_cmd "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg"
  run_cmd "sudo chmod a+r /etc/apt/keyrings/docker.gpg"

  . /etc/os-release
  run_cmd "echo 'deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable' | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null"

  APT_UPDATED=0
  run_apt_update_once
  run_cmd "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"

  run_cmd "sudo usermod -aG docker '${SUDO_USER:-$USER}' || true"

  if command -v systemctl >/dev/null 2>&1 && [[ "$(ps -p 1 -o comm=)" == "systemd" ]]; then
    run_cmd "sudo systemctl enable --now docker"
  else
    echo "Aviso: systemd não detectado. No WSL, habilite systemd ou use Docker Desktop."
  fi
}

install_claude_code_cli() {
  ensure_nodejs
  if need_cmd claude; then
    echo "Claude CLI já instalado: $(claude --version || true)"
    return
  fi

  echo "Instalando Claude Code CLI..."
  run_cmd "npm install -g @anthropic-ai/claude-code"
}

install_copilot_cli() {
  ensure_github_cli
  echo "Instalando/atualizando gh-copilot..."
  run_cmd "gh extension install github/gh-copilot 2>/dev/null || gh extension upgrade github/gh-copilot"
}

install_azure_cli() {
  if need_cmd az; then
    echo "Azure CLI já instalado: $(az version --output json | jq -r '.\"azure-cli\"' 2>/dev/null || az --version | head -n1)"
    return
  fi

  echo "Instalando Azure CLI..."
  run_cmd "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
}

install_aws_cli() {
  if need_cmd aws; then
    echo "AWS CLI já instalado: $(aws --version)"
    return
  fi

  echo "Instalando AWS CLI v2..."
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o <tmp>/awscliv2.zip"
    echo "[DRY-RUN] unzip -q <tmp>/awscliv2.zip -d <tmp>"
    echo "[DRY-RUN] sudo <tmp>/aws/install --update"
    return
  fi

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN
  run_cmd "curl -fsSL 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o '$tmp_dir/awscliv2.zip'"
  run_cmd "unzip -q '$tmp_dir/awscliv2.zip' -d '$tmp_dir'"
  run_cmd "sudo '$tmp_dir/aws/install' --update"
}

install_oc_cli() {
  if need_cmd oc; then
    echo "oc já instalado: $(oc version --client | head -n1)"
    return
  fi

  echo "Instalando OpenShift oc CLI..."
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] curl -fsSL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz -o <tmp>/openshift-client-linux.tar.gz"
    echo "[DRY-RUN] tar -xzf <tmp>/openshift-client-linux.tar.gz -C <tmp>"
    echo "[DRY-RUN] sudo install -m 0755 <tmp>/oc /usr/local/bin/oc"
    echo "[DRY-RUN] sudo install -m 0755 <tmp>/kubectl /usr/local/bin/kubectl (se existir)"
    return
  fi

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN
  run_cmd "curl -fsSL 'https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz' -o '$tmp_dir/openshift-client-linux.tar.gz'"
  run_cmd "tar -xzf '$tmp_dir/openshift-client-linux.tar.gz' -C '$tmp_dir'"
  run_cmd "sudo install -m 0755 '$tmp_dir/oc' /usr/local/bin/oc"
  if [[ -f "$tmp_dir/kubectl" ]]; then
    run_cmd "sudo install -m 0755 '$tmp_dir/kubectl' /usr/local/bin/kubectl"
  fi
}

install_kimi_cli() {
  ensure_nodejs
  local pkg
  read -r -p "Pacote npm do Kimi CLI [kimi-cli]: " pkg
  pkg="${pkg:-kimi-cli}"

  echo "Instalando Kimi CLI via npm ($pkg)..."
  run_cmd "npm install -g '$pkg'"
}

# Nunca deixa este helper propagar falha para o "set -e" do script: se a API do
# GitHub estiver indisponível/rate-limited, deve degradar para string vazia, não
# derrubar o instalador inteiro.
github_latest_asset_url() {
  local repo="$1" pattern="$2" out
  out="$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null \
    | jq -r --arg pat "$pattern" '[.assets[] | select(.name | test($pat))][0].browser_download_url // empty' 2>/dev/null)" || out=""
  printf '%s' "$out"
}

# Instala a config zero-plugin nvim_native (https://github.com/smnatale/nvim_native).
# Manual de uso e checklist pós-instalação: NEOVIM.md neste repositório.
install_neovim() {
  local arch; arch="$(uname -m)"

  local nvim_ok=0
  if need_cmd nvim; then
    local ver vmajor vminor
    ver="$(nvim --version | head -n1 | sed -E 's/^NVIM v//')"
    vmajor="$(echo "$ver" | cut -d. -f1)"; vminor="$(echo "$ver" | cut -d. -f2)"
    if [[ "$vmajor" -gt 0 || ( "$vmajor" -eq 0 && "$vminor" -ge 11 ) ]]; then
      nvim_ok=1
    fi
  fi

  if [[ "$nvim_ok" -eq 1 ]]; then
    echo "Neovim já atende ao requisito (>=0.11): $(nvim --version | head -n1)"
  else
    echo "Instalando Neovim (binário oficial, >=0.11 — necessário para vim.lsp.enable())..."
    local asset_pattern=""
    case "$arch" in
      x86_64)  asset_pattern='^nvim-linux-x86_64\.tar\.gz$|^nvim-linux64\.tar\.gz$' ;;
      aarch64) asset_pattern='^nvim-linux-arm64\.tar\.gz$' ;;
      *) echo "Arquitetura $arch não suportada para download automático do Neovim." ;;
    esac
    if [[ -n "$asset_pattern" ]]; then
      local url; url="$(github_latest_asset_url "neovim/neovim" "$asset_pattern")"
      if [[ -z "$url" ]]; then
        echo "Não encontrei asset do Neovim para $arch (API do GitHub indisponível ou rate-limited). Instale manualmente: https://github.com/neovim/neovim/releases"
      elif [[ "$DRY_RUN" -eq 1 ]]; then
        echo "[DRY-RUN] baixaria $url e instalaria em /opt/nvim (symlink /usr/local/bin/nvim)"
      else
        local tmp_dir; tmp_dir="$(mktemp -d)"
        if curl -fsSL "$url" -o "$tmp_dir/nvim.tar.gz" && tar -xzf "$tmp_dir/nvim.tar.gz" -C "$tmp_dir"; then
          local extracted_dir; extracted_dir="$(find "$tmp_dir" -maxdepth 1 -mindepth 1 -type d -name 'nvim-linux*' | head -n1)"
          if [[ -n "$extracted_dir" ]]; then
            sudo rm -rf /opt/nvim
            sudo mv "$extracted_dir" /opt/nvim
            sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
          else
            echo "Falha ao extrair o pacote do Neovim."
          fi
        else
          echo "Falha ao baixar/extrair Neovim de $url"
        fi
        rm -rf "$tmp_dir"
      fi
    fi
  fi

  if need_cmd rg; then
    echo "ripgrep já instalado: $(rg --version | head -n1)"
  else
    echo "Instalando ripgrep..."
    run_cmd "sudo apt-get install -y ripgrep" || echo "Falha ao instalar ripgrep."
  fi

  if need_cmd lua-language-server; then
    echo "lua-language-server já instalado."
  elif [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] sudo apt-get install -y lua-language-server (fallback: binário do GitHub em /opt/lua-language-server)"
  else
    if ! sudo apt-get install -y lua-language-server 2>/dev/null; then
      local lls_pattern="" lls_url=""
      case "$arch" in
        x86_64)  lls_pattern='linux-x64\.tar\.gz$' ;;
        aarch64) lls_pattern='linux-arm64\.tar\.gz$|linux-aarch64\.tar\.gz$' ;;
      esac
      if [[ -n "$lls_pattern" ]]; then
        lls_url="$(github_latest_asset_url "LuaLS/lua-language-server" "$lls_pattern")"
      fi
      if [[ -n "$lls_url" ]]; then
        local tmp_dir; tmp_dir="$(mktemp -d)"
        if curl -fsSL "$lls_url" -o "$tmp_dir/lls.tar.gz"; then
          sudo mkdir -p /opt/lua-language-server
          sudo tar -xzf "$tmp_dir/lls.tar.gz" -C /opt/lua-language-server
          sudo ln -sf /opt/lua-language-server/bin/lua-language-server /usr/local/bin/lua-language-server
        else
          echo "Falha ao baixar lua-language-server de $lls_url"
        fi
        rm -rf "$tmp_dir"
      else
        echo "Não consegui instalar lua-language-server automaticamente. LSP de Lua não vai funcionar até instalar manualmente."
      fi
    fi
  fi

  if need_cmd stylua; then
    echo "stylua já instalado: $(stylua --version)"
  elif [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] baixaria stylua do GitHub para /usr/local/bin/stylua"
  else
    local st_pattern="" st_url=""
    case "$arch" in
      x86_64)  st_pattern='linux-x86_64\.zip$' ;;
      aarch64) st_pattern='linux-aarch64\.zip$' ;;
    esac
    if [[ -n "$st_pattern" ]]; then
      st_url="$(github_latest_asset_url "JohnnyMorganz/StyLua" "$st_pattern")"
    fi
    if [[ -n "$st_url" ]]; then
      local tmp_dir; tmp_dir="$(mktemp -d)"
      if curl -fsSL "$st_url" -o "$tmp_dir/stylua.zip"; then
        unzip -q "$tmp_dir/stylua.zip" -d "$tmp_dir"
        sudo install -m 0755 "$tmp_dir/stylua" /usr/local/bin/stylua
      else
        echo "Falha ao baixar stylua de $st_url"
      fi
      rm -rf "$tmp_dir"
    else
      echo "Não consegui instalar stylua automaticamente. Formatação de .lua cairá no fallback do LSP."
    fi
  fi

  ensure_nodejs
  if need_cmd tsgo; then
    echo "tsgo já instalado."
  else
    echo "Instalando tsgo (@typescript/native-preview)..."
    run_cmd "sudo npm install -g @typescript/native-preview" || echo "Falha ao instalar tsgo."
  fi
  if need_cmd prettier; then
    echo "prettier já instalado."
  else
    echo "Instalando prettier..."
    run_cmd "sudo npm install -g prettier" || echo "Falha ao instalar prettier."
  fi

  local cfg_dir="$HOME/.config/nvim"
  local cfg_is_nvim_native=0
  if [[ -d "$cfg_dir/.git" ]]; then
    if git -C "$cfg_dir" remote get-url origin 2>/dev/null | grep -q "smnatale/nvim_native"; then
      cfg_is_nvim_native=1
    fi
  fi

  if [[ "$cfg_is_nvim_native" -eq 1 ]]; then
    echo "Config do Neovim (nvim_native) já está em $cfg_dir."
  elif [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] clonaria https://github.com/smnatale/nvim_native para $cfg_dir (com backup de config existente, se houver)"
  else
    if [[ -d "$cfg_dir" ]]; then
      local backup="$cfg_dir.bak-$(date +%Y%m%d%H%M%S)"
      echo "Config existente encontrada em $cfg_dir — movendo para $backup antes de instalar."
      mv "$cfg_dir" "$backup"
    fi
    mkdir -p "$(dirname "$cfg_dir")"
    git clone --depth=1 https://github.com/smnatale/nvim_native.git "$cfg_dir" || echo "Falha ao clonar a config do Neovim."
  fi

  # a config referencia o colorscheme "catppuccin", que não é nativo nem incluído no
  # repo — instalado como pacote nativo do Vim (sem plugin manager). Ver NEOVIM.md.
  local pack_dir="$cfg_dir/pack/colors/start/catppuccin.nvim"
  if [[ -d "$pack_dir" ]]; then
    echo "Colorscheme catppuccin já instalado (pacote nativo)."
  elif [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] clonaria catppuccin/nvim como pacote nativo em $pack_dir"
  elif [[ -d "$cfg_dir" ]]; then
    mkdir -p "$(dirname "$pack_dir")"
    git clone --depth=1 https://github.com/catppuccin/nvim.git "$pack_dir" || echo "Falha ao clonar o colorscheme catppuccin."
  fi

  echo "Manual de uso e checklist pós-instalação: NEOVIM.md neste repositório."
}

install_zsh_oh_my_zsh() {
  if need_cmd zsh; then
    echo "zsh já instalado: $(zsh --version)"
  else
    echo "Instalando zsh..."
    run_cmd "sudo apt-get install -y zsh"
  fi

  local zsh_path
  zsh_path="$(command -v zsh || true)"
  if [[ -z "$zsh_path" ]]; then
    zsh_path="/usr/bin/zsh"
  fi

  echo "Definindo zsh como shell padrão..."
  run_cmd "chsh -s '$zsh_path'"

  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    echo "Oh My Zsh já instalado em $HOME/.oh-my-zsh"
    return
  fi

  echo "Instalando Oh My Zsh..."
  run_cmd "sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
}

install_powerlevel10k() {
  local custom_dir theme_dir zshrc
  custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  theme_dir="$custom_dir/themes/powerlevel10k"
  zshrc="$HOME/.zshrc"

  if [[ -d "$theme_dir/.git" ]]; then
    echo "powerlevel10k já instalado em $theme_dir"
  else
    echo "Instalando powerlevel10k..."
    run_cmd "mkdir -p '$custom_dir/themes'"
    run_cmd "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git '$theme_dir'"
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] atualizar $zshrc para: ZSH_THEME=\"powerlevel10k/powerlevel10k\""
  else
    if [[ -f "$zshrc" ]]; then
      if grep -q '^ZSH_THEME=' "$zshrc"; then
        sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$zshrc"
      else
        echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$zshrc"
      fi
    else
      echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' > "$zshrc"
    fi
  fi

  echo "Tema do zsh configurado para powerlevel10k."
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] p10k configure"
  else
    run_cmd "zsh -ic 'p10k configure'"
  fi
}

# ========= main =========
parse_args "$@"

if ! grep -qi microsoft /proc/version; then
  echo "Aviso: não parece WSL. O script funciona em Ubuntu normal também."
fi

echo "=== Setup interativo (WSL Ubuntu) ==="
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Modo DRY-RUN ativado: nenhum comando será executado."
else
  sudo -v
fi
ensure_base_packages

ask_yes_no "Instalar zsh + Oh My Zsh?" Y && install_zsh_oh_my_zsh
ask_yes_no "Instalar e configurar powerlevel10k?" Y && install_powerlevel10k
ask_yes_no "Instalar Docker?" Y && install_docker
ask_yes_no "Instalar Claude Code CLI?" Y && install_claude_code_cli
ask_yes_no "Instalar Copilot CLI (gh copilot)?" Y && install_copilot_cli
ask_yes_no "Instalar Azure CLI (az)?" Y && install_azure_cli
ask_yes_no "Instalar AWS CLI (aws)?" Y && install_aws_cli
ask_yes_no "Instalar OpenShift CLI (oc)?" Y && install_oc_cli
ask_yes_no "Instalar Kimi CLI?" Y && install_kimi_cli
ask_yes_no "Instalar Neovim (config zero-plugin nvim_native)?" Y && install_neovim

echo
echo "Concluído."
echo "Próximos logins sugeridos:"
echo "  gh auth login"
echo "  az login"
echo "  aws configure"
echo "  oc login <URL_DO_CLUSTER>"
echo "  claude login"
echo "  nvim            (manual e checklist pós-instalação em NEOVIM.md)"
echo
echo "Se Docker acabou de ser instalado, reinicie o terminal (ou rode: newgrp docker)."
