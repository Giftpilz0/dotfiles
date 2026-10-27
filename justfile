set shell := ["bash", "-euo", "pipefail", "-c"]

# List recipes
default:
    @just --list --unsorted

# Repo-local collections for ansible-lint, so linting doesn't touch ~/.ansible
export ANSIBLE_COLLECTIONS_PATH := justfile_directory() / ".ansible/collections"

# Run all linters and formatters (pre-commit); CI runs this too
lint *args:
    uvx --from ansible-core ansible-galaxy collection install -r ansible/requirements.yaml -p .ansible/collections >/dev/null
    pre-commit run --all-files {{args}}

# Definition of done
check: lint

# Apply this checkout with chezmoi (also runs the Ansible playbook)
deploy *args:
    chezmoi --source {{justfile_directory()}} apply {{args}}
