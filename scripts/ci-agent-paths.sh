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

docker_run() {
  local image=$1
  shift
  local cid
  cid="$(cat /etc/hostname 2>/dev/null || true)"
  if [[ -n "$cid" ]] && docker inspect "$cid" >/dev/null 2>&1; then
    docker run --rm --volumes-from "$cid" -w "$PWD" "$@" "$image"
  else
    docker run --rm -v "$PWD:$PWD" -w "$PWD" "$@" "$image"
  fi
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
      -ec "$(cat <<'EOF'
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
      -ec "$(cat <<'EOF'
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
