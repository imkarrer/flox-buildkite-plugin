#!/usr/bin/env bash
set -euo pipefail

# Run the plugin's bats suite locally with the SAME stack the CI image
# buildkite/plugin-tester:v4.1.1 provisions:
#   - bats-core v1.10.0  (the bats/bats:v1.10.0 base image CI starts from)
#   - buildkite-plugins/bats-mock v2.1.1  (the fork CI installs on top)
#   - bats-assert v0.3.0 / bats-file v0.2.0 / bats-support v0.3.0
#   (the bundled libraries in the bats/bats image; loaded via load.bash)
#
# The stack is downloaded once into the gitignored .bats-libs/ directory, so
# every run is reproducible and needs only `curl` + `tar`. No root, no docker.
#
# Usage: scripts/test-local.sh [bats args...]

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
lib_dir="${repo_root}/.bats-libs"

bats_ver="v1.10.0"
mock_ver="v2.1.1"
assert_ver="v0.3.0"
file_ver="v0.2.0"
support_ver="v0.3.0"

fetch() { # $1=dest dir  $2=tar.gz URL — downloads and strips the top-level dir
  local dest="$1" url="$2"
  mkdir -p "$dest"
  curl -fsSL "$url" | tar -xz --strip-components=1 -C "$dest"
}

mkdir -p "$lib_dir"

[[ -x "$lib_dir/bats-core/bin/bats" ]] \
  || fetch "$lib_dir/bats-core" "https://github.com/bats-core/bats-core/archive/${bats_ver}.tar.gz"
[[ -f "$lib_dir/bats-support/load.bash" ]] \
  || fetch "$lib_dir/bats-support" "https://github.com/bats-core/bats-support/archive/${support_ver}.tar.gz"
[[ -f "$lib_dir/bats-assert/load.bash" ]] \
  || fetch "$lib_dir/bats-assert" "https://github.com/bats-core/bats-assert/archive/${assert_ver}.tar.gz"
[[ -f "$lib_dir/bats-file/load.bash" ]] \
  || fetch "$lib_dir/bats-file" "https://github.com/bats-core/bats-file/archive/${file_ver}.tar.gz"
[[ -f "$lib_dir/bats-mock/stub.bash" ]] \
  || fetch "$lib_dir/bats-mock" "https://github.com/buildkite-plugins/bats-mock/archive/${mock_ver}.tar.gz"

# Mirrors the plugin-tester image's load.bash (assert, mock, file, support).
cat >"$lib_dir/load.bash" <<EOF
source "$lib_dir/bats-assert/load.bash"
source "$lib_dir/bats-mock/stub.bash"
source "$lib_dir/bats-file/load.bash"
source "$lib_dir/bats-support/load.bash"
EOF

export BATS_PLUGIN_PATH="$lib_dir"

exec "$lib_dir/bats-core/bin/bats" "$@" "${repo_root}/tests/"
