# Flox Buildkite Plugin

[![Build status](https://badge.buildkite.com/0931aada34b88f39844aa07d32a9b23d1fc4801c999685394f.svg?branch=main)](https://buildkite.com/isaac-karrer/flox-buildkite-plugin)

Run a Buildkite step inside a [Flox](https://flox.dev) environment from the repo (`.flox/`) or FloxHub. If `flox` is missing, the plugin installs it from `downloads.flox.dev`. Pin a tag in the plugin ref — `imkarrer/flox#v1.0.0` — rather than `#main`, so a pipeline doesn't move when this repo does.

```yml
steps:
  - plugins:
      - imkarrer/flox#v1.0.0:
          command: npm run build
```

## Usage

Local `.flox/` — no auth:

```yml
steps:
  - plugins:
      - imkarrer/flox#v1.0.0:
          command: npm run build
```

Subdirectory (monorepo):

```yml
steps:
  - plugins:
      - imkarrer/flox#v1.0.0:
          dir: backend
          command: cargo test
```

Remote FloxHub env — set `FLOX_TOKEN` (or `floxhub-token`) on the agent or pipeline; pass `trust: true` for an env you don't own (another org's, or a borrowed `dir`):

```yml
steps:
  - plugins:
      - imkarrer/flox#v1.0.0:
          environment: my-org/netlify-deploy
          command: netlify deploy
```

`command` / `dir` / `environment` / `trust` / `activation-mode` are per-step. Do not hoist them to pipeline env.

## Configuration

| Option | Default | What it is |
|--------|---------|------------|
| `command` | required | Command run under `flox activate -c` |
| `dir` | — | Directory that contains `.flox/` |
| `environment` | — | FloxHub env `owner/name` |
| `floxhub-token` | — | Auth for remote envs; else `FLOX_TOKEN` |
| `trust` | `false` | `flox activate --trust` — for `environment` or a borrowed `dir` |
| `activation-mode` | manifest | `dev` or `run` (`flox activate -m`) |
| `channel` | `stable` | `stable` / `qa` / `nightly` / commit hash |
| `version` | channel latest | Pin the flox package (e.g. `1.14.0`) |
| `s3-cache-*` / `s3-cache-push` | off | Step override for cache identity; see below |
| `disable-metrics` | `true` | Sets `FLOX_DISABLE_METRICS` |

## Environment variables

Pipeline `env:`, agent, or cluster. Plugin keys win when both are set.

| Variable | Role |
|----------|------|
| `FLOX_TOKEN` | FloxHub auth if `floxhub-token` is omitted |
| `S3_CACHE_BUCKET` | Enable the Nix binary cache (empty = off) |
| `S3_CACHE_ENDPOINT` | Full S3 URL (R2, AWS, MinIO, …) |
| `S3_CACHE_REGION` | Default `auto` |
| `S3_CACHE_PUBLIC_KEY` | Trusted cache public key (`name-1:base64=`) |
| `S3_CACHE_PUSH` | `true` to sign and push the activated closure |
| `S3_CACHE_SIGNING_KEY` or `_FILE` | Write-back signing secret |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | Private bucket I/O (or cluster secrets `S3_CACHE_ACCESS_KEY_ID` / `S3_CACHE_SECRET_ACCESS_KEY`) |
| `FLOX_SHELL` / `NIX_REMOTE` | Default `bash` / `auto` |

```yml
env:
  S3_CACHE_BUCKET: flox-binary-cache
  S3_CACHE_ENDPOINT: http://minio:9000
  S3_CACHE_REGION: us-east-1
  S3_CACHE_PUBLIC_KEY: "flox-binary-cache-1:base64="
  S3_CACHE_PUSH: "true"

steps:
  - plugins:
      - imkarrer/flox#v1.0.0:
          command: npm test
```

The hook writes `extra-substituters` and `extra-trusted-public-keys` into `/etc/nix/nix.conf`. Anyone with the signing key can plant trusted store paths — keep it in Buildkite secrets, never the image or repo.

```bash
nix --extra-experimental-features nix-command key generate-secret --key-name flox-binary-cache-1
nix --extra-experimental-features nix-command key convert-secret-to-public < secret.key
```

A `/nix` volume on a pre-baked agent image is a warm cache only. If it mounts empty, the hook restores `/opt/nix-seed`. Do not attach that volume to a stock image and then auto-install: the flox `.deb` refuses a leftover `/nix` with no `nix` binary.

## Auto-install

Used when `flox` is not on `PATH`. Alpine/musl is not supported (`buildkite/agent:3` is Alpine — use `3-ubuntu`).

| Platform | Package |
|----------|---------|
| Debian/Ubuntu | `.deb` via `apt-get` (updates lists first) |
| RHEL/Fedora | `.rpm` |
| macOS | `.pkg` |

## Agent image

[`Dockerfile`](Dockerfile) is `buildkite/agent:3-ubuntu` plus flox (`FLOX_VERSION`), a nix-daemon entrypoint, optional baked substituter (`S3_CACHE_*` build args), optional `SEED_PACKAGES`, and `/opt/nix-seed` for a cold `/nix` volume.

Pull the published image instead of building your own:

```bash
docker pull ferahgo/flox-buildkite-agent:v1.0.0   # or :latest
```

Or build it yourself, e.g. to change `SEED_PACKAGES` or bake your own S3 cache substituter:

```bash
docker build -t your-registry/flox-buildkite-agent:latest .
```

`ferahgo/flox-buildkite-agent` is published from `.buildkite/pipeline.yml`'s `publish` step, which runs only on tag builds (`if: build.tag != null`) and needs a `DOCKERHUB_TOKEN` Buildkite secret on the `self` queue.

## Developing

Root `.flox/` provides `docker-compose`. Tests stub `flox` — no account needed.

```bash
scripts/test-local.sh                          # bats, no Docker
flox activate -c "docker compose run --rm tests"
flox activate -c "docker compose run --rm lint"
```

On a containerized agent use `scripts/bk-docker-run.sh` (tests/lint) and `scripts/ci-agent-paths.sh` (cold install / image smoke). Those scripts mount the checkout only — not the agent's `/nix`.

CI is [Buildkite](https://buildkite.com/isaac-karrer/flox-buildkite-plugin) (`.buildkite/pipeline.yml`, queue `self`):

- Blocking: unit tests, lint, cold-start install on stock `buildkite/agent:3-ubuntu`, `examples/hello` activate, pre-baked image build
- Soft-fail: FloxHub `imkarrer/hello` (needs `FLOX_TOKEN` on the agent)
- Tag builds only: publish `ferahgo/flox-buildkite-agent` to Docker Hub

Cache identity for that queue comes from the agent. Example env: `examples/hello/.flox/`.

## License

MIT. S3 cache and `/nix` seeding follow [jbayer/flox-buildkite](https://github.com/jbayer/flox-buildkite).
