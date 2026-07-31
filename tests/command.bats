#!/usr/bin/env bats

load "$BATS_PLUGIN_PATH/load.bash"

setup() {
  export BUILDKITE_PLUGIN_FLOX_COMMAND="echo hello"
}

@test "runs command inside flox activate" {
  stub flox 'activate -c echo hello : echo "Activated"'

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Activated"

  unstub flox
}

@test "uses remote environment when specified" {
  export BUILDKITE_PLUGIN_FLOX_ENVIRONMENT="my-org/my-env"

  stub flox 'activate --remote my-org/my-env -c echo hello : echo "Remote activated"'

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Remote activated"

  unstub flox
}

@test "uses --dir when specified" {
  export BUILDKITE_PLUGIN_FLOX_DIR="/app"

  stub flox 'activate --dir /app -c echo hello : echo "Dir activated"'

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Dir activated"

  unstub flox
}

@test "fails when flox activate fails" {
  stub flox 'activate -c echo hello : exit 1'

  run "$PWD/hooks/command"

  assert_failure

  unstub flox
}
