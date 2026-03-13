#!/usr/bin/env bash

COMMON_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${COMMON_DIR}/.." && pwd)"
DEFAULT_CONFIG_FILE="${REPO_ROOT}/config/lab.env"

log_info() {
  printf '[INFO] %s\n' "$*"
}

log_warn() {
  printf '[WARN] %s\n' "$*" >&2
}

log_error() {
  printf '[ERROR] %s\n' "$*" >&2
}

die() {
  log_error "$*"
  exit 1
}

require_command() {
  local command_name="$1"
  command -v "$command_name" >/dev/null 2>&1 || die "Required command not found: ${command_name}"
}

require_var() {
  local var_name="$1"
  [[ -n "${!var_name:-}" ]] || die "Required variable is not set: ${var_name}"
}

load_lab_config() {
  local config_file="${MYAWS_CONFIG_FILE:-$DEFAULT_CONFIG_FILE}"

  if [[ -f "$config_file" ]]; then
    # shellcheck disable=SC1090
    source "$config_file"
  else
    log_warn "Config file not found: ${config_file}"
    log_warn "Copy config/lab.env.example to config/lab.env or export the needed variables."
  fi
}

aws_profile_args() {
  if [[ -n "${AWS_PROFILE:-}" ]]; then
    printf -- '--profile\0%s\0' "$AWS_PROFILE"
  fi
}

aws_security_group_args() {
  if [[ -n "${AWS_SECURITY_GROUP_ID:-}" ]]; then
    printf -- '--security-group-ids\0%s\0' "$AWS_SECURITY_GROUP_ID"
    return
  fi

  if [[ -n "${AWS_SECURITY_GROUP:-}" ]]; then
    printf -- '--security-groups\0%s\0' "$AWS_SECURITY_GROUP"
    return
  fi

  die "Set AWS_SECURITY_GROUP or AWS_SECURITY_GROUP_ID in config/lab.env"
}

default_scratch_paths() {
  : "${SCRATCH_MOUNT:=${HOME}/scratch}"
  : "${SHARED_BASHRC_PATH:=${SCRATCH_MOUNT}/dotfiles/bashrc_shared}"
}

ensure_bashrc_sources_shared() {
  default_scratch_paths

  if grep -q 'myaws shared shell' "${HOME}/.bashrc"; then
    return
  fi

  cat >> "${HOME}/.bashrc" <<EOF

# >>> myaws shared shell >>>
if [ -f "${SHARED_BASHRC_PATH}" ]; then
  source "${SHARED_BASHRC_PATH}"
fi
# <<< myaws shared shell <<<
EOF
}

append_managed_block() {
  local file_path="$1"
  local block_name="$2"
  local block_contents="$3"
  local start_marker="# >>> ${block_name} >>>"
  local end_marker="# <<< ${block_name} <<<"

  mkdir -p "$(dirname "$file_path")"
  touch "$file_path"

  if grep -qF "$start_marker" "$file_path"; then
    return
  fi

  {
    printf '\n%s\n' "$start_marker"
    printf '%s\n' "$block_contents"
    printf '%s\n' "$end_marker"
  } >> "$file_path"
}
