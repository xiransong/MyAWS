# Troubleshooting

## Config File Not Found

If a script says `config/lab.env` is missing:
- copy [config/lab.env.example](../config/lab.env.example) to `config/lab.env`
- fill in the required values
- or set `MYAWS_CONFIG_FILE` to an alternate config path

## Volume Does Not Resolve Under `/dev/disk/by-id`

If the mount or format script cannot find the EBS volume:
- confirm the volume is attached to the current instance
- confirm the volume ID is correct
- wait a few seconds and retry after attachment completes

## Shared Shell Does Not Load

If `source ~/.bashrc` does not expose the shared environment:
- confirm [scripts/instance/setup-shared-shell.sh](../scripts/instance/setup-shared-shell.sh) has created `${HOME}/scratch/dotfiles/bashrc_shared` or the configured equivalent
- confirm [scripts/instance/bootstrap-user-shell.sh](../scripts/instance/bootstrap-user-shell.sh) has updated `~/.bashrc`
- inspect `~/.bashrc` for the `myaws shared shell` block

## GitHub Access

This repo intentionally avoids storing private SSH keys on the shared EBS by default.

Preferred options:
- `gh auth login`
- user-managed SSH keys created directly on the instance

Reference: [scripts/instance/setup-github-auth.sh](../scripts/instance/setup-github-auth.sh)
