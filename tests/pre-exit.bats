#!/usr/bin/env bats

load "$BATS_PLUGIN_PATH/load.bash"

@test "pre-exit is a no-op" {
  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output ""
}
