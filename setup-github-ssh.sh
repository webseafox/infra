#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=0

print_help() {
  cat <<'EOF'
Uso: ./setup-github-ssh.sh [opções]

Opções:
  -n, --dry-run   Mostra os comandos sem executar
  -h, --help      Exibe ajuda
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
  local default="${2:-Y}"
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

ensure_requirements() {
  if need_cmd ssh-keygen && need_cmd ssh-add && need_cmd ssh-agent; then
    return
  fi

  echo "Instalando cliente SSH..."
  run_cmd "sudo apt-get update -y"
  run_cmd "sudo apt-get install -y openssh-client"
}

generate_key_if_needed() {
  local email="$1"
  local key_path="$2"

  mkdir -p "$(dirname "$key_path")"
  chmod 700 "$(dirname "$key_path")" || true

  if [[ -f "$key_path" ]]; then
    if ask_yes_no "A chave $key_path já existe. Sobrescrever?" N; then
      run_cmd "ssh-keygen -t ed25519 -C '$email' -f '$key_path'"
    else
      echo "Usando chave existente: $key_path"
    fi
  else
    run_cmd "ssh-keygen -t ed25519 -C '$email' -f '$key_path'"
  fi
}

start_agent_and_add_key() {
  local key_path="$1"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] eval \"\$(ssh-agent -s)\""
    echo "[DRY-RUN] ssh-add '$key_path'"
    return
  fi

  eval "$(ssh-agent -s)"
  ssh-add "$key_path"
}

show_and_copy_pubkey() {
  local pub_key="$1"

  echo
  echo "===== SUA CHAVE PÚBLICA ====="
  cat "$pub_key"
  echo "============================="
  echo

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] copiar chave pública para clipboard (se disponível)"
    return
  fi

  if need_cmd clip.exe; then
    cat "$pub_key" | clip.exe
    echo "Chave copiada para clipboard do Windows (clip.exe)."
  elif need_cmd xclip; then
    xclip -selection clipboard < "$pub_key"
    echo "Chave copiada para clipboard (xclip)."
  else
    echo "Clipboard não detectado. Copie manualmente a chave acima."
  fi
}

test_github_ssh() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] ssh -T git@github.com"
    return
  fi

  set +e
  local output
  output="$(ssh -T git@github.com 2>&1)"
  local rc=$?
  set -e

  echo
  echo "$output"
  echo

  if [[ "$output" == *"successfully authenticated"* ]]; then
    echo "Conexão SSH com GitHub está funcionando."
  else
    echo "Não foi possível confirmar autenticação agora (código: $rc)."
  fi
}

configure_git_remote_ssh() {
  local repo_dir owner repo remote_url

  read -r -p "Diretório do repositório local [$(pwd)]: " repo_dir
  repo_dir="${repo_dir:-$(pwd)}"

  if [[ ! -d "$repo_dir/.git" ]]; then
    echo "Diretório não é um repositório git: $repo_dir"
    return
  fi

  read -r -p "Usuário/Org no GitHub (ex.: webseafox): " owner
  read -r -p "Nome do repositório (ex.: infra): " repo

  if [[ -z "$owner" || -z "$repo" ]]; then
    echo "Owner e repo são obrigatórios para configurar remote."
    return
  fi

  remote_url="git@github.com:${owner}/${repo}.git"
  run_cmd "git -C '$repo_dir' remote set-url origin '$remote_url'"
  echo "origin atualizado para: $remote_url"

  if ask_yes_no "Quer fazer push da branch atual agora?" N; then
    run_cmd "git -C '$repo_dir' push -u origin \$(git -C '$repo_dir' rev-parse --abbrev-ref HEAD)"
  fi
}

main() {
  parse_args "$@"

  echo "=== Setup SSH para GitHub (WSL/Ubuntu) ==="
  [[ "$DRY_RUN" -eq 1 ]] && echo "Modo DRY-RUN ativado."

  ensure_requirements

  local email key_path pub_key
  read -r -p "E-mail para comentar a chave SSH: " email
  email="${email:-no-reply@example.com}"

  read -r -p "Caminho da chave privada [~/.ssh/id_ed25519]: " key_path
  key_path="${key_path:-~/.ssh/id_ed25519}"
  key_path="${key_path/#\~/$HOME}"
  pub_key="${key_path}.pub"

  generate_key_if_needed "$email" "$key_path"
  start_agent_and_add_key "$key_path"

  if [[ "$DRY_RUN" -eq 0 && ! -f "$pub_key" ]]; then
    echo "Erro: chave pública não encontrada em $pub_key"
    exit 1
  fi

  show_and_copy_pubkey "$pub_key"

  echo "Adicione a chave em: https://github.com/settings/keys"
  if ask_yes_no "Já adicionou a chave no GitHub e quer testar agora?" Y; then
    test_github_ssh
  fi

  if ask_yes_no "Configurar remote origin para SSH em um repositório?" Y; then
    configure_git_remote_ssh
  fi

  echo "Concluído."
}

main "$@"
