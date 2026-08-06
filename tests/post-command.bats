#!/usr/bin/env bats

load "$BATS_PLUGIN_PATH/load.bash"

setup() {
  export BUILDKITE_PLUGIN_FLOX_COMMAND="hello"
}

@test "post-command is a no-op without s3-cache-bucket" {
  run "$PWD/hooks/post-command"

  assert_success
  assert_output --partial "no S3 cache configured"
}

@test "post-command is read-only when s3-cache-push is disabled" {
  export BUILDKITE_PLUGIN_FLOX_S3_CACHE_BUCKET="my-cache"
  export BUILDKITE_PLUGIN_FLOX_S3_CACHE_ENDPOINT="https://example.com"

  run "$PWD/hooks/post-command"

  assert_success
  assert_output --partial "opt-in"
}

@test "post-command pushes the env closure when s3-cache-push is enabled" {
  export BUILDKITE_PLUGIN_FLOX_S3_CACHE_BUCKET="my-cache"
  export BUILDKITE_PLUGIN_FLOX_S3_CACHE_ENDPOINT="https://example.com"
  export BUILDKITE_PLUGIN_FLOX_S3_CACHE_REGION="auto"
  export BUILDKITE_PLUGIN_FLOX_S3_CACHE_PUSH="true"
  export AWS_ACCESS_KEY_ID="AKID"
  export AWS_SECRET_ACCESS_KEY="SAK"
  export S3_CACHE_SIGNING_KEY="my-cache-1:secret"

  stub flox ':: echo /nix/store/abc123-env'
  stub nix ':: echo "pushed"'

  run "$PWD/hooks/post-command"

  assert_success
  assert_output --partial "pushed"
  assert_output --partial "push complete"

  unstub flox
  unstub nix
}
