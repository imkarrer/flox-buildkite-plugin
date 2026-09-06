#!/usr/bin/env bash
# Run plugin-tester / plugin-linter against this checkout.
#
# A host agent can bind-mount $PWD. An agent that is itself a container
# (docker.sock + a builds volume) cannot: the host path is empty. In that
# case remount this container's volumes and run from $PWD.
set -euo pipefail

mode="${1:?usage: $0 tests|lint}"

cid="$(cat /etc/hostname 2>/dev/null || true)"
in_container=false
if [[ -n "$cid" ]] && docker inspect "$cid" >/dev/null 2>&1; then
  in_container=true
fi

case "$mode" in
  tests)
    if $in_container; then
      docker run --rm --volumes-from "$cid" -w "$PWD" --entrypoint bats \
        buildkite/plugin-tester:v4.1.1 tests/
    else
      docker compose run --rm tests
    fi
    ;;
  lint)
    if $in_container; then
      docker run --rm --volumes-from "$cid" -e PLUGIN_DIR="$PWD" --entrypoint sh \
        buildkite/plugin-linter:latest -ec \
        'ln -sfn "$PLUGIN_DIR" /plugin && lint --id imkarrer/flox'
    else
      docker compose run --rm lint
    fi
    ;;
  *)
    echo "usage: $0 tests|lint" >&2
    exit 2
    ;;
esac
