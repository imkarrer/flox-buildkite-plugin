#!/usr/bin/env bash
# Prove the two agent stories the README advertises.
#
#   cold  — stock buildkite/agent:3-ubuntu, flox not on PATH, plugin installs it
#   image — docker build the pre-baked Dockerfile, then activate with flox already there
#
# The ac-box CI agent already has flox, so `plugins: imkarrer/flox` never hits
# the install branch. These steps run a disposable container instead.
set -euo pipefail

mode="${1:?usage: $0 cold|image}"

# Usage: docker_run IMAGE [docker options...] -- [command args...]
# Docker options (--entrypoint, -e) must come before IMAGE. Command args
# (bash's -ec SCRIPT) must come after. Putting -ec in the options position
# makes Docker parse it as `--env c`.
#
# Do not --volumes-from the agent. That also attaches buildkite-nix:/nix.
# The flox .deb preinst then sees /nix/var/nix/db/db.sqlite, cannot find a
# nix binary, and aborts; `rm /nix` fails because the path is a mount.
# Mount only the volume that covers $PWD (the checkout).
docker_run() {
  local image=$1
  shift
  local cid docker_opts=() cmd=() mount_args=() seen_dd=false arg
  cid="$(cat /etc/hostname 2>/dev/null || true)"
  for arg in "$@"; do
    if [[ "$seen_dd" == false && "$arg" == "--" ]]; then
      seen_dd=true
      continue
    fi
    if [[ "$seen_dd" == true ]]; then
      cmd+=("$arg")
    else
      docker_opts+=("$arg")
    fi
  done
  if [[ -n "$cid" ]] && docker inspect "$cid" >/dev/null 2>&1; then
    local pwd_p dest name source best_dest="" best_src=""
    pwd_p="$(pwd -P)"
    while IFS=$'\t' read -r dest name source; do
      [[ -n "$dest" ]] || continue
      if [[ "$pwd_p" == "$dest" || "$pwd_p" == "$dest"/* ]]; then
        if [[ ${#dest} -ge ${#best_dest} ]]; then
          best_dest=$dest
          if [[ -n "$name" ]]; then
            best_src=$name
          else
            best_src=$source
          fi
        fi
      fi
    done < <(docker inspect -f '{{range .Mounts}}{{printf "%s\t%s\t%s\n" .Destination .Name .Source}}{{end}}' "$cid")
    if [[ -z "$best_src" ]]; then
      echo "+++ :flox: no volume covers ${pwd_p}; cannot share the checkout" >&2
      exit 1
    fi
    echo "--- :flox: mounting checkout ${best_src}:${best_dest} (not /nix)"
    mount_args=(-v "${best_src}:${best_dest}" -w "$PWD")
  else
    mount_args=(-v "$PWD:$PWD" -w "$PWD")
  fi
  docker run --rm "${mount_args[@]}" "${docker_opts[@]}" "$image" "${cmd[@]}"
}

case "$mode" in
  cold)
    echo "--- :flox: cold start on stock Ubuntu agent (no flox on PATH)"
    docker_run buildkite/agent:3-ubuntu \
      --entrypoint bash \
      -e BUILDKITE_PLUGIN_FLOX_COMMAND=hello \
      -e BUILDKITE_PLUGIN_FLOX_DIR=examples/hello \
      -e BUILDKITE_PLUGIN_FLOX_VERSION=1.14.0 \
      -e FLOX_DISABLE_METRICS=true \
      -e DEBIAN_FRONTEND=noninteractive \
      -- -ec "$(cat <<'EOF'
set -euo pipefail
if command -v flox >/dev/null 2>&1; then
  echo "+++ flox already on PATH — this image is not a cold agent"
  exit 1
fi
source ./hooks/environment
command -v flox >/dev/null
./hooks/command
EOF
)"
    ;;
  image)
    echo "--- :docker: build pre-baked agent image"
    docker build -t flox-buildkite-plugin:ci \
      --build-arg FLOX_VERSION=1.14.0 \
      --build-arg SEED_PACKAGES=hello \
      .
    echo "--- :docker: image has flox, nix seed, daemon entrypoint"
    docker run --rm --entrypoint bash flox-buildkite-plugin:ci -ec '
      set -euo pipefail
      command -v flox
      flox --version
      test -d /opt/nix-seed
      test -x /docker-entrypoint.d/10-nix-daemon
    '
    echo "--- :flox: activate examples/hello with pre-installed flox in that image"
    docker_run flox-buildkite-plugin:ci \
      --entrypoint bash \
      -e BUILDKITE_PLUGIN_FLOX_COMMAND=hello \
      -e BUILDKITE_PLUGIN_FLOX_DIR=examples/hello \
      -e FLOX_DISABLE_METRICS=true \
      -- -ec "$(cat <<'EOF'
set -euo pipefail
command -v flox >/dev/null
source ./hooks/environment
./hooks/command
EOF
)"
    ;;
  *)
    echo "usage: $0 cold|image" >&2
    exit 2
    ;;
esac
