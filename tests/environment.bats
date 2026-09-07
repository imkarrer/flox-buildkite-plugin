#!/usr/bin/env bats

load "$BATS_PLUGIN_PATH/load.bash"

setup() {
  export BUILDKITE_PLUGIN_FLOX_COMMAND="hello"
  # Point the hook's nix.conf at a per-test temp file (FLOX_NIX_CONF is honored
  # by configure_s3_cache) so the suite runs rootless, with no sudo.
  export FLOX_NIX_CONF="${BATS_TEST_TMPDIR}/nix/nix.conf"

  # resolve_download_url's Linux branch picks .deb/.rpm via `command -v
  # dpkg`/`rpm`. Fake dpkg onto PATH so that check is deterministic here
  # regardless of the host's real packaging — the plugin-tester CI image is
  # Alpine (musl, no dpkg/rpm at all), unlike most dev machines.
  mkdir -p "${BATS_TEST_TMPDIR}/bin"
  : > "${BATS_TEST_TMPDIR}/bin/dpkg"
  chmod +x "${BATS_TEST_TMPDIR}/bin/dpkg"
  PATH="${BATS_TEST_TMPDIR}/bin:${PATH}"
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

@test "environment hook accepts S3_CACHE_* pipeline env as the cache identity" {
  export S3_CACHE_BUCKET="env-cache"
  export S3_CACHE_ENDPOINT="http://minio:9000"
  export S3_CACHE_REGION="us-east-1"
  export S3_CACHE_PUBLIC_KEY="env-cache-1:abc"
  stub flox '--version : echo "flox 1.14.0"' '--version : echo "flox 1.14.0"'

  run "$PWD/hooks/environment"

  assert_success
  assert_output --partial "adding S3 cache substituter"
  grep -q "extra-substituters = s3://env-cache?endpoint=http://minio:9000&region=us-east-1" "${FLOX_NIX_CONF}"
  grep -q "extra-trusted-public-keys = env-cache-1:abc" "${FLOX_NIX_CONF}"

  unstub flox
}

@test "environment hook prefers plugin s3-cache-* keys over S3_CACHE_* env" {
  export S3_CACHE_BUCKET="env-cache"
  export S3_CACHE_ENDPOINT="http://minio:9000"
  export S3_CACHE_REGION="us-east-1"
  export S3_CACHE_PUBLIC_KEY="env-cache-1:abc"
  export BUILDKITE_PLUGIN_FLOX_S3_CACHE_BUCKET="plugin-cache"
  export BUILDKITE_PLUGIN_FLOX_S3_CACHE_ENDPOINT="https://example.com"
  export BUILDKITE_PLUGIN_FLOX_S3_CACHE_REGION="auto"
  export BUILDKITE_PLUGIN_FLOX_S3_CACHE_PUBLIC_KEY="plugin-cache-1:xyz"
  stub flox '--version : echo "flox 1.14.0"' '--version : echo "flox 1.14.0"'

  run "$PWD/hooks/environment"

  assert_success
  grep -q "extra-substituters = s3://plugin-cache?endpoint=https://example.com&region=auto" "${FLOX_NIX_CONF}"
  grep -q "extra-trusted-public-keys = plugin-cache-1:xyz" "${FLOX_NIX_CONF}"

  unstub flox
}

# --- FloxHub auth (regression coverage for BUILDKITE_PLUGIN_FLOX_FLOXHUB_TOKEN) ---

@test "environment hook skips FloxHub auth when no environment is requested" {
  stub flox '--version : echo "flox 1.14.0"' '--version : echo "flox 1.14.0"'

  run "$PWD/hooks/environment"

  assert_success
  refute_output --partial "Authenticating with FloxHub"

  unstub flox
}

@test "environment hook skips FloxHub auth when an environment is requested but no token is available" {
  export BUILDKITE_PLUGIN_FLOX_ENVIRONMENT="my-org/my-env"
  stub flox '--version : echo "flox 1.14.0"' '--version : echo "flox 1.14.0"'

  run "$PWD/hooks/environment"

  assert_success
  refute_output --partial "Authenticating with FloxHub"

  unstub flox
}

@test "environment hook skips login when flox is already authenticated" {
  export BUILDKITE_PLUGIN_FLOX_ENVIRONMENT="my-org/my-env"
  export BUILDKITE_PLUGIN_FLOX_FLOXHUB_TOKEN="secret-token"
  stub flox \
    '--version : echo "flox 1.14.0"' \
    '--version : echo "flox 1.14.0"' \
    'auth status : echo "already logged in"'

  run "$PWD/hooks/environment"

  assert_success
  refute_output --partial "Authenticating with FloxHub"

  unstub flox
}

@test "environment hook authenticates using the floxhub-token plugin key" {
  export BUILDKITE_PLUGIN_FLOX_ENVIRONMENT="my-org/my-env"
  export BUILDKITE_PLUGIN_FLOX_FLOXHUB_TOKEN="secret-token"
  stub flox \
    '--version : echo "flox 1.14.0"' \
    '--version : echo "flox 1.14.0"' \
    'auth status : exit 1' \
    'auth login --token-file - : echo "Logged in"' \
    'auth status : echo "Logged in as testuser"'

  run "$PWD/hooks/environment"

  assert_success
  assert_output --partial "Authenticating with FloxHub"

  unstub flox
}

@test "environment hook falls back to FLOX_TOKEN when floxhub-token is not set" {
  export BUILDKITE_PLUGIN_FLOX_ENVIRONMENT="my-org/my-env"
  export FLOX_TOKEN="fallback-token"
  stub flox \
    '--version : echo "flox 1.14.0"' \
    '--version : echo "flox 1.14.0"' \
    'auth status : exit 1' \
    'auth login --token-file - : echo "Logged in"' \
    'auth status : echo "Logged in as testuser"'

  run "$PWD/hooks/environment"

  assert_success
  assert_output --partial "Authenticating with FloxHub"

  unstub flox
}

@test "environment hook prefers the floxhub-token plugin key over FLOX_TOKEN" {
  export BUILDKITE_PLUGIN_FLOX_ENVIRONMENT="my-org/my-env"
  export FLOX_TOKEN="fallback-token"
  export BUILDKITE_PLUGIN_FLOX_FLOXHUB_TOKEN="plugin-wins-token"
  local tokenfile="${BATS_TEST_TMPDIR}/token_seen"
  stub flox \
    '--version : echo "flox 1.14.0"' \
    '--version : echo "flox 1.14.0"' \
    'auth status : exit 1' \
    "auth login --token-file - : cat > '${tokenfile}'; echo Logged in" \
    'auth status : echo "Logged in as testuser"'

  run "$PWD/hooks/environment"

  assert_success
  [ "$(cat "${tokenfile}")" = "plugin-wins-token" ]

  unstub flox
}

# --- resolve_download_url (unit tests; sourced so main() does not execute) ---

@test "resolve_download_url builds a versioned deb URL for stable/linux/x86_64" {
  source "$PWD/hooks/environment"
  stub uname '-s : echo Linux' '-m : echo x86_64'

  run resolve_download_url stable 1.14.0

  assert_success
  assert_output "https://downloads.flox.dev/by-env/stable/deb/flox-1.14.0.x86_64-linux.deb"

  unstub uname
}

@test "resolve_download_url builds an unversioned URL when version is empty" {
  source "$PWD/hooks/environment"
  stub uname '-s : echo Linux' '-m : echo aarch64'

  run resolve_download_url stable ""

  assert_success
  assert_output "https://downloads.flox.dev/by-env/stable/deb/flox.aarch64-linux.deb"

  unstub uname
}

@test "resolve_download_url builds a macOS pkg URL without checking dpkg/rpm" {
  source "$PWD/hooks/environment"
  stub uname '-s : echo Darwin' '-m : echo x86_64'

  run resolve_download_url qa 1.14.0

  assert_success
  assert_output "https://downloads.flox.dev/by-env/qa/osx/flox-1.14.0.x86_64-darwin.pkg"

  unstub uname
}

@test "resolve_download_url routes a commit hash channel through by-commit" {
  source "$PWD/hooks/environment"
  stub uname '-s : echo Linux' '-m : echo x86_64'

  run resolve_download_url deadbeef 2.0.0

  assert_success
  assert_output "https://downloads.flox.dev/by-commit/deadbeef/deb/flox-2.0.0.x86_64-linux.deb"

  unstub uname
}

@test "resolve_download_url fails loudly on an unsupported OS" {
  source "$PWD/hooks/environment"
  # `uname -s`/`uname -m` are each captured once upfront, so -m is still
  # called even though the OS check fails first.
  stub uname '-s : echo Windows' '-m : echo x86_64'

  run resolve_download_url stable ""

  assert_failure
  assert_output --partial "Unsupported OS: Windows"

  unstub uname
}

@test "resolve_download_url fails loudly on an unsupported architecture" {
  source "$PWD/hooks/environment"
  stub uname '-s : echo Linux' '-m : echo mips'

  run resolve_download_url stable ""

  assert_failure
  assert_output --partial "Unsupported architecture: mips"

  unstub uname
}
