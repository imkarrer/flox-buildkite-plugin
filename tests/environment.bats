#!/usr/bin/env bats

load "$BATS_PLUGIN_PATH/load.bash"

setup() {
  export BUILDKITE_PLUGIN_FLOX_COMMAND="hello"
  # Point the hook's nix.conf at a per-test temp file (FLOX_NIX_CONF is honored
  # by configure_s3_cache) so the suite runs rootless, with no sudo.
  export FLOX_NIX_CONF="${BATS_TEST_TMPDIR}/nix/nix.conf"
}

teardown() {
  rm -f "${FLOX_NIX_CONF}"
}

@test "environment hook skips S3 cache setup when no cache is configured" {
  # The hook probes `flox --version` twice: once in ensure_nix_seeded(), once
  # in the "Using pre-installed flox" branch — one plan line per invocation.
  stub flox '--version : echo "flox 1.14.0"' '--version : echo "flox 1.14.0"'

  run "$PWD/hooks/environment"

  assert_success
  refute_output --partial "S3 cache substituter"
  refute test -e "${FLOX_NIX_CONF}"

  unstub flox
}

@test "environment hook fails loudly when s3-cache-bucket is set but endpoint is missing" {
  export BUILDKITE_PLUGIN_FLOX_S3_CACHE_BUCKET="my-cache"
  stub flox '--version : echo "flox 1.14.0"' '--version : echo "flox 1.14.0"'

  run "$PWD/hooks/environment"

  assert_failure
  assert_output --partial "s3-cache-endpoint is missing"

  unstub flox
}

@test "environment hook configures the S3 cache substituter when configured" {
  export BUILDKITE_PLUGIN_FLOX_S3_CACHE_BUCKET="my-cache"
  export BUILDKITE_PLUGIN_FLOX_S3_CACHE_ENDPOINT="https://example.com"
  export BUILDKITE_PLUGIN_FLOX_S3_CACHE_REGION="auto"
  export BUILDKITE_PLUGIN_FLOX_S3_CACHE_PUBLIC_KEY="my-cache-1:abc"
  stub flox '--version : echo "flox 1.14.0"' '--version : echo "flox 1.14.0"'

  run "$PWD/hooks/environment"

  assert_success
  assert_output --partial "adding S3 cache substituter"
  grep -q "extra-substituters = s3://my-cache?endpoint=https://example.com&region=auto" "${FLOX_NIX_CONF}"
  grep -q "extra-trusted-public-keys = my-cache-1:abc" "${FLOX_NIX_CONF}"

  unstub flox
}
