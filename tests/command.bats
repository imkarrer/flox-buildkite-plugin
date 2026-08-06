#!/usr/bin/env bats

load "$BATS_PLUGIN_PATH/load.bash"

setup() {
  export BUILDKITE_PLUGIN_FLOX_COMMAND="hello"
}

@test "runs command inside flox activate" {
  stub flox 'activate -c hello : echo "Activated"'

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Activated"

  unstub flox
}

@test "uses remote environment" {
  export BUILDKITE_PLUGIN_FLOX_ENVIRONMENT="my-org/my-env"

  stub flox 'activate -r my-org/my-env -c hello : echo "Remote activated"'

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Remote activated"

  unstub flox
}

@test "uses --dir" {
  export BUILDKITE_PLUGIN_FLOX_DIR="/app"

  stub flox 'activate -d /app -c hello : echo "Dir activated"'

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Dir activated"

  unstub flox
}

@test "passes --trust for remote environments" {
  export BUILDKITE_PLUGIN_FLOX_ENVIRONMENT="other-org/env"
  export BUILDKITE_PLUGIN_FLOX_TRUST="true"

  stub flox 'activate -r other-org/env -t -c hello : echo "Trusted"'

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Trusted"

  unstub flox
}

@test "passes activation mode" {
  export BUILDKITE_PLUGIN_FLOX_ACTIVATION_MODE="run"

  stub flox 'activate -m run -c hello : echo "Run mode activated"'

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Run mode activated"

  unstub flox
}

@test "fails when flox activate fails" {
  stub flox 'activate -c hello : exit 1'

  run "$PWD/hooks/command"

  assert_failure

  unstub flox
}
