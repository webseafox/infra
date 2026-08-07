#!/usr/bin/env bash
#
# Instalador interativo de ferramentas de dev para WSL Ubuntu:
#   Docker, Claude Code CLI, GitHub Copilot CLI, Azure CLI, AWS CLI, oc CLI,
#   Kimi Code CLI, Zsh + Oh My Zsh + Powerlevel10k
#
# Suporta modo DRY-RUN: mostra o que seria feito, sem alterar nada, com opção
# de rodar a instalação de verdade logo em seguida.
#
# Uso:
#   chmod +x install-dev-cli-tools.sh
#   ./install-dev-cli-tools.sh
#
set -uo pipefail

# ========================= cores / logging =========================
C_RESET=$'\e[0m'; C_BOLD=$'\e[1m'
C_RED=$'\e[31m'; C_GREEN=$'\e[32m'; C_YELLOW=$'\e[33m'; C_BLUE=$'\e[34m'

log()  { printf '%s[*]%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
ok()   { printf '%s[OK]%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf '%s[!!]%s %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
err()  { printf '%s[ERRO]%s %s\n' "$C_RED" "$C_RESET" "$*"; }
dry()  { printf '%s[DRY-RUN]%s %s\n' "$C_YELLOW" "$C_RESET" "$*"; }

need_cmd() { command -v "$1" >/dev/null 2>&1; }

DRY_RUN=0

# ========================= usuário real (mesmo sob sudo) =========================
# Quando o script é rodado com "sudo ./install-dev-cli-tools.sh", $HOME e $USER
# passam a apontar para root. Instaladores por-usuário (Claude, Kimi, zsh/omz)
# precisam rodar como o usuário real, senão instalam em /root e "somem" depois.
if [[ "$EUID" -eq 0 && -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
  REAL_USER="$SUDO_USER"
  REAL_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
  warn "Script rodando com sudo — instalações por-usuário (Claude, Kimi, zsh) serão feitas para '$REAL_USER' ($REAL_HOME), não para root."
else
  REAL_USER="$USER"
  REAL_HOME="$HOME"
fi

# roda um comando como o usuário real (via sudo -u se o script estiver como root)
run_as_real_user() {
  if [[ "$EUID" -eq 0 && "$REAL_USER" != "root" ]]; then
    sudo -u "$REAL_USER" -H bash -c "$1"
  else
    bash -c "$1"
  fi
}

# ========================= pré-checagens =========================
if ! need_cmd apt-get; then
  err "Este script é para Ubuntu/Debian (apt-get não encontrado). Abortando."
  exit 1
fi

if grep -qi microsoft /proc/version 2>/dev/null; then
  log "Ambiente WSL detectado."
else
  warn "Não parece WSL — o script deve funcionar em Ubuntu nativo também."
fi

ARCH_DPKG="$(dpkg --print-architecture)"      # amd64 / arm64
ARCH_UNAME="$(uname -m)"                      # x86_64 / aarch64
log "Arquitetura detectada: dpkg=$ARCH_DPKG uname=$ARCH_UNAME"

APT_UPDATED=0
apt_update_once() {
  if [[ "$APT_UPDATED" -eq 0 ]]; then
    sudo apt-get update -y
    APT_UPDATED=1
  fi
}

confirm() {
  local prompt="$1" default="${2:-Y}" ans
  if [[ "$default" == "Y" ]]; then
    read -r -p "$prompt [Y/n]: " ans; ans="${ans:-Y}"
  else
    read -r -p "$prompt [y/N]: " ans; ans="${ans:-N}"
  fi
  [[ "${ans,,}" == "y" || "${ans,,}" == "yes" || "${ans,,}" == "s" || "${ans,,}" == "sim" ]]
}

clone_if_missing() {
  local repo="$1" dest="$2"
  if [[ -d "$dest" ]]; then
    ok "Já existe: $dest"
  else
    git clone --depth=1 "$repo" "$dest"
  fi
}

# mantém o sudo "quente" durante todo o script
sudo -v
( while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT

ensure_base_packages() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    dry "Instalaria pacotes base: ca-certificates curl wget gnupg lsb-release unzip tar jq git"
    return 0
  fi
  apt_update_once
  sudo apt-get install -y ca-certificates curl wget gnupg lsb-release unzip tar jq git
}

# ========================= Node.js (necessário só p/ Copilot CLI) =========================
ensure_nodejs_22() {
  if need_cmd node; then
    local major; major="$(node -v | sed 's/^v//' | cut -d. -f1)"
    if [[ "$major" -ge 22 ]]; then
      ok "Node.js já atende ao requisito (>=22): $(node -v)"
      return 0
    fi
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    dry "Instalaria/atualizaria Node.js para a versão 22.x via NodeSource (necessário para o Copilot CLI)."
    return 0
  fi
  log "Instalando Node.js 22.x via NodeSource..."
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
  APT_UPDATED=0; apt_update_once
  sudo apt-get install -y nodejs
}

# ========================= Docker =========================
install_docker() {
  if need_cmd docker; then
    ok "Docker já instalado: $(docker --version)"
    return 0
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    dry "Instalaria Docker Engine: repo apt oficial download.docker.com, pacotes docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin, adicionaria $REAL_USER ao grupo docker, habilitaria o serviço."
    return 0
  fi

  log "Instalando Docker Engine (repositório oficial)..."
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  . /etc/os-release
  echo "deb [arch=${ARCH_DPKG} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  APT_UPDATED=0; apt_update_once
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  sudo usermod -aG docker "$REAL_USER" || true

  if [[ -d /run/systemd/system ]]; then
    sudo systemctl enable --now docker
    ok "Docker instalado e iniciado via systemd."
  else
    sudo service docker start || true
    warn "Sem systemd (comum em WSL). Docker precisa ser iniciado a cada sessão com: sudo service docker start"
    warn "Para persistir: adicione '[boot]\\nsystemd=true' em /etc/wsl.conf e rode 'wsl --shutdown' no Windows."
  fi
  warn "Faça logout/login (ou 'newgrp docker') para usar docker sem sudo."
}

# ========================= Claude Code CLI =========================
install_claude_code() {
  if run_as_real_user "command -v claude" >/dev/null 2>&1; then
    ok "Claude Code CLI já instalado: $(run_as_real_user "claude --version" 2>/dev/null || echo 'versão desconhecida')"
    return 0
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    dry "Instalaria Claude Code CLI via instalador nativo (curl -fsSL https://claude.ai/install.sh | bash)."
    return 0
  fi
  log "Instalando Claude Code CLI (instalador nativo) para '$REAL_USER'..."
  run_as_real_user "curl -fsSL https://claude.ai/install.sh | bash"
  warn "Reinicie o shell (ou 'source ~/.bashrc') para o comando 'claude' entrar no PATH."
}

# ========================= GitHub Copilot CLI =========================
install_copilot_cli() {
  if need_cmd copilot; then
    ok "GitHub Copilot CLI já instalado: $(copilot --version 2>/dev/null || echo 'versão desconhecida')"
    return 0
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    dry "Instalaria Node.js 22+ (se necessário) e o GitHub Copilot CLI via 'npm install -g @github/copilot'."
    return 0
  fi
  ensure_nodejs_22
  log "Instalando GitHub Copilot CLI (@github/copilot via npm)..."
  sudo npm install -g @github/copilot
  ok "Instalado. Rode 'copilot' e autentique com sua conta GitHub."
}

# ========================= Azure CLI =========================
install_azure_cli() {
  if need_cmd az; then
    ok "Azure CLI já instalado: $(az version 2>/dev/null | jq -r '."azure-cli"' 2>/dev/null || az --version | head -n1)"
    return 0
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    dry "Instalaria Azure CLI via curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
    return 0
  fi
  log "Instalando Azure CLI..."
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
}

# ========================= AWS CLI v2 =========================
install_aws_cli() {
  if need_cmd aws; then
    ok "AWS CLI já instalado: $(aws --version)"
    return 0
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    dry "Baixaria e instalaria AWS CLI v2 para arch ${ARCH_UNAME} (awscli.amazonaws.com/awscli-exe-linux-${ARCH_UNAME}.zip)."
    return 0
  fi
  log "Instalando AWS CLI v2 (arch: ${ARCH_UNAME})..."
  local tmp_dir; tmp_dir="$(mktemp -d)"
  if curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH_UNAME}.zip" -o "$tmp_dir/awscliv2.zip"; then
    unzip -q "$tmp_dir/awscliv2.zip" -d "$tmp_dir"
    sudo "$tmp_dir/aws/install" --update
    ok "AWS CLI instalado."
  else
    err "Falha ao baixar AWS CLI para arquitetura ${ARCH_UNAME}."
  fi
  rm -rf "$tmp_dir"
}

# ========================= OpenShift oc CLI =========================
install_oc_cli() {
  if need_cmd oc; then
    ok "oc já instalado: $(oc version --client 2>/dev/null | head -n1)"
    return 0
  fi
  local url="https://mirror.openshift.com/pub/openshift-v4/${ARCH_UNAME}/clients/ocp/stable/openshift-client-linux.tar.gz"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    dry "Baixaria e instalaria oc CLI (e kubectl) de $url em /usr/local/bin."
    return 0
  fi
  log "Instalando OpenShift oc CLI (arch: ${ARCH_UNAME})..."
  local tmp_dir; tmp_dir="$(mktemp -d)"
  if curl -fsSL "$url" -o "$tmp_dir/oc.tar.gz"; then
    tar -xzf "$tmp_dir/oc.tar.gz" -C "$tmp_dir"
    sudo install -m 0755 "$tmp_dir/oc" /usr/local/bin/oc
    [[ -f "$tmp_dir/kubectl" ]] && sudo install -m 0755 "$tmp_dir/kubectl" /usr/local/bin/kubectl
    ok "oc CLI instalado."
  else
    err "Falha ao baixar oc CLI de $url"
  fi
  rm -rf "$tmp_dir"
}

# ========================= Kimi Code CLI =========================
install_kimi_cli() {
  if run_as_real_user "command -v kimi" >/dev/null 2>&1; then
    ok "Kimi Code CLI já instalado: $(run_as_real_user "kimi --version" 2>/dev/null || echo 'versão desconhecida')"
    return 0
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    dry "Instalaria Kimi Code CLI via curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash"
    return 0
  fi
  log "Instalando Kimi Code CLI para '$REAL_USER'..."
  run_as_real_user "curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash"
  warn "Reinicie o shell (ou 'source ~/.zshrc'/'source ~/.bashrc') para o comando 'kimi' entrar no PATH."
}

# ========================= Zsh + Oh My Zsh + Powerlevel10k =========================
install_zsh_omz() {
  local zsh_custom="${ZSH_CUSTOM:-$REAL_HOME/.oh-my-zsh/custom}"

  if need_cmd zsh && [[ -d "$REAL_HOME/.oh-my-zsh" && -d "$zsh_custom/themes/powerlevel10k" ]]; then
    ok "Zsh + Oh My Zsh + Powerlevel10k já parecem instalados."
    return 0
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    dry "Instalaria zsh, definiria como shell padrão, instalaria Oh My Zsh (modo não-interativo), tema Powerlevel10k e plugins zsh-autosuggestions/zsh-syntax-highlighting, e ajustaria ~/.zshrc (ZSH_THEME e plugins=) para '$REAL_USER'."
    return 0
  fi

  log "Instalando zsh..."
  sudo apt-get install -y zsh

  local user_shell; user_shell="$(getent passwd "$REAL_USER" | cut -d: -f7)"
  if [[ "$(basename "${user_shell:-}")" != "zsh" ]]; then
    sudo chsh -s "$(command -v zsh)" "$REAL_USER"
    ok "Shell padrão alterado para zsh (efetivo no próximo login)."
  else
    ok "zsh já é o shell padrão."
  fi

  if [[ ! -d "$REAL_HOME/.oh-my-zsh" ]]; then
    log "Instalando Oh My Zsh (modo não-interativo) para '$REAL_USER'..."
    run_as_real_user "RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" '' --unattended"
  else
    ok "Oh My Zsh já instalado."
  fi

  local repo dest
  for repo_dest in \
    "https://github.com/romkatv/powerlevel10k.git|$zsh_custom/themes/powerlevel10k" \
    "https://github.com/zsh-users/zsh-autosuggestions|$zsh_custom/plugins/zsh-autosuggestions" \
    "https://github.com/zsh-users/zsh-syntax-highlighting|$zsh_custom/plugins/zsh-syntax-highlighting"
  do
    repo="${repo_dest%%|*}"; dest="${repo_dest#*|}"
    if [[ -d "$dest" ]]; then
      ok "Já existe: $dest"
    else
      run_as_real_user "mkdir -p '$(dirname "$dest")' && git clone --depth=1 '$repo' '$dest'"
    fi
  done

  if [[ -f "$REAL_HOME/.zshrc" ]]; then
    sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$REAL_HOME/.zshrc"
    sed -i 's|^plugins=.*|plugins=(git zsh-autosuggestions zsh-syntax-highlighting)|' "$REAL_HOME/.zshrc"
    [[ "$EUID" -eq 0 && "$REAL_USER" != "root" ]] && chown "$REAL_USER" "$REAL_HOME/.zshrc"
    ok "~/.zshrc atualizado (tema e plugins)."
  else
    warn "~/.zshrc não encontrado — ajuste ZSH_THEME e plugins manualmente depois de abrir o zsh."
  fi

  warn "Abra um novo terminal (zsh) e rode 'p10k configure' para personalizar o prompt (ícones, espaçamento, etc)."
}

# ========================= seleção interativa =========================
declare -A TOOL_LABEL=(
  [docker]="Docker Engine"
  [claude]="Claude Code CLI"
  [copilot]="GitHub Copilot CLI"
  [az]="Azure CLI"
  [aws]="AWS CLI v2"
  [oc]="OpenShift CLI (oc)"
  [kimi]="Kimi Code CLI"
  [zsh]="Zsh + Oh My Zsh + Powerlevel10k"
)
TOOL_ORDER=(docker claude copilot az aws oc kimi zsh)
declare -A SELECTED

select_tools() {
  if need_cmd whiptail; then
    local checklist_args=()
    for t in "${TOOL_ORDER[@]}"; do
      checklist_args+=("$t" "${TOOL_LABEL[$t]}" "ON")
    done
    local result
    result=$(whiptail --title "Instalador de CLIs" \
      --checklist "Selecione as ferramentas a instalar (espaço = marcar, enter = confirmar):" \
      20 74 8 "${checklist_args[@]}" 3>&1 1>&2 2>&3) || { warn "Cancelado pelo usuário."; exit 0; }

    for t in "${TOOL_ORDER[@]}"; do SELECTED[$t]=0; done
    eval "chosen=($result)"
    for t in "${chosen[@]}"; do SELECTED[$t]=1; done
  else
    warn "whiptail não encontrado — usando prompts de texto simples."
    for t in "${TOOL_ORDER[@]}"; do
      if confirm "Instalar ${TOOL_LABEL[$t]}?" Y; then SELECTED[$t]=1; else SELECTED[$t]=0; fi
    done
  fi
}

run_selected_installs() {
  ensure_base_packages
  [[ "${SELECTED[docker]:-0}"  -eq 1 ]] && install_docker
  [[ "${SELECTED[claude]:-0}"  -eq 1 ]] && install_claude_code
  [[ "${SELECTED[copilot]:-0}" -eq 1 ]] && install_copilot_cli
  [[ "${SELECTED[az]:-0}"      -eq 1 ]] && install_azure_cli
  [[ "${SELECTED[aws]:-0}"     -eq 1 ]] && install_aws_cli
  [[ "${SELECTED[oc]:-0}"      -eq 1 ]] && install_oc_cli
  [[ "${SELECTED[kimi]:-0}"    -eq 1 ]] && install_kimi_cli
  [[ "${SELECTED[zsh]:-0}"     -eq 1 ]] && install_zsh_omz
}

print_summary() {
  echo
  echo "${C_BOLD}=== Resumo ===${C_RESET}"
  for t in "${TOOL_ORDER[@]}"; do
    [[ "${SELECTED[$t]:-0}" -eq 1 ]] || continue
    case "$t" in
      docker)  need_cmd docker  && echo "  Docker:  $(docker --version)"            || echo "  Docker:  não encontrado" ;;
      claude)  run_as_real_user "command -v claude" >/dev/null 2>&1 && echo "  Claude:  $(run_as_real_user "claude --version" 2>/dev/null)" || echo "  Claude:  não encontrado (reinicie o shell)" ;;
      copilot) need_cmd copilot && echo "  Copilot: $(copilot --version 2>/dev/null)" || echo "  Copilot: não encontrado" ;;
      az)      need_cmd az      && echo "  Azure:   $(az --version 2>/dev/null | head -n1)" || echo "  Azure:   não encontrado" ;;
      aws)     need_cmd aws     && echo "  AWS:     $(aws --version 2>/dev/null)"    || echo "  AWS:     não encontrado" ;;
      oc)      need_cmd oc      && echo "  oc:      $(oc version --client 2>/dev/null | head -n1)" || echo "  oc:      não encontrado" ;;
      kimi)    run_as_real_user "command -v kimi" >/dev/null 2>&1 && echo "  Kimi:    $(run_as_real_user "kimi --version" 2>/dev/null)" || echo "  Kimi:    não encontrado (reinicie o shell)" ;;
      zsh)     need_cmd zsh     && echo "  Zsh:     $(zsh --version)"               || echo "  Zsh:     não encontrado" ;;
    esac
  done
  echo
  echo "Próximos passos de login/config sugeridos:"
  echo "  claude          (depois /login dentro do CLI)"
  echo "  copilot         (autenticação via conta GitHub)"
  echo "  az login"
  echo "  aws configure"
  echo "  oc login <URL_DO_CLUSTER>"
  echo "  kimi            (depois /login dentro do CLI)"
  echo "  p10k configure  (dentro de um novo terminal zsh)"
}

# ========================= main =========================
echo "${C_BOLD}=== Instalador de ferramentas de dev (WSL Ubuntu) ===${C_RESET}"
select_tools

if confirm "Rodar primeiro em modo DRY-RUN (simulação, nada será instalado)?" Y; then
  DRY_RUN=1
  echo
  log "===== MODO DRY-RUN — nenhuma alteração será feita no sistema ====="
  run_selected_installs
  echo

  if confirm "Deseja executar as instalações de verdade agora?" N; then
    DRY_RUN=0
    echo
    log "===== EXECUTANDO DE VERDADE ====="
    run_selected_installs
    print_summary
  else
    log "Nada foi alterado (apenas simulação). Rode o script novamente quando quiser instalar de verdade."
  fi
else
  DRY_RUN=0
  run_selected_installs
  print_summary
fi

echo
echo "Concluído."
