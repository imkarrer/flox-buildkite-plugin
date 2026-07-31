# Flox Buildkite Plugin

Run your Buildkite steps inside a reproducible [Flox](https://flox.dev) environment that lives in your repo. No Dockerfile, no container registry, no image tags to keep in sync — the environment travels with your code, so a dependency change and the code that needs it land in a single commit.

The plugin wraps each step in `flox activate`, materializing the environment on any Linux/macOS runner: if `flox` is on `PATH` it uses it, otherwise it auto-installs. The lockfile pins every dependency to a content hash, so builds are reproducible without pre-baked runner images or a Docker supply chain to maintain.

Flox ships first-class CI integrations for GitHub Actions, CircleCI, and GitLab — Buildkite is the gap this plugin fills. You *floxify* a repo once (`flox init` writes `.flox/manifest.toml`, committed alongside your code); this plugin is the Buildkite-native way to run against that environment — the counterpart to [`install-flox-action`](https://github.com/flox/install-flox-action) for GitHub Actions and the [Flox orb](https://github.com/flox/flox-orb) for CircleCI. It turns the bare `flox activate -c` you'd otherwise hand-roll in every command step into declarative plugin config: flox auto-install on ephemeral agents, FloxHub token and `trust` handling, per-directory environments for monorepos, and matrix builds.

## Why not just bake a Docker image?

You can, and plenty of teams do. The usual path to a reproducible CI environment is a Dockerfile: install your toolchain, build the image, push it to a registry, and point your agents at the tag. It works — but it leaves you owning a second artifact that lives outside your repo, versions on its own schedule, and has to be rebuilt and re-pushed every time a dependency moves.

Flox collapses that. The environment is a single file in your repo (`.flox/manifest.toml`) with a lockfile pinning every package to a content hash. Nothing to build, nothing to publish — the plugin realizes the environment on the runner at job time, and changing a dependency lands in the same commit as the code that needs it.

Here's the same Node build environment defined both ways.

**Docker** — write a Dockerfile:

```dockerfile
FROM buildkite/agent:3

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl ca-certificates git \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g pnpm@9 \
    && rm -rf /var/lib/apt/lists/*
USER buildkite
```

Build it, push it, then reference the tag in your pipeline:

```bash
docker build -t your-registry/ci-node:22 .
docker push your-registry/ci-node:22
```

```yml
steps:
  - command: pnpm install && pnpm build
    agents:
      queue: docker
    plugins:
      - docker#v5.11.0:
          image: your-registry/ci-node:22
```

**Flox** — declare the same tools and commit the result:

```bash
flox init
flox install nodejs_22 pnpm
```

That writes `.flox/manifest.toml`:

```toml
version = 1

[install]
nodejs_22.pkg-path = "nodejs_22"
pnpm.pkg-path = "pnpm"
```

Commit `.flox/`, then run against it — no registry, no image tag to track:

```yml
steps:
  - command: pnpm install && pnpm build
    plugins:
      - imkarrer/flox-buildkite-plugin#v1.0.0:
          command: pnpm install && pnpm build
```

The gap shows up on day two. Bumping Node from 22 to 24 with Docker means editing the Dockerfile, rebuilding, pushing, and usually bumping a tag in a separate PR before CI ever sees the change. With Flox it's `flox install nodejs_24` on the same branch as the code that needs it — one commit, and the identical environment activates on your laptop with `flox activate`. No more "green in CI, broken locally."

Reach for Flox when you already use it locally, run a monorepo with many environments, or just want to stop maintaining a separate CI image pipeline. Docker still earns its keep when you need kernel-level isolation for untrusted build steps, or when the image *is* the thing you ship — and the two aren't mutually exclusive: bake `flox` into a slim agent image to skip cold-start install time and let the plugin realize each repo's `.flox/` on top (see [Docker](#docker) below). But for the everyday case — "make CI use the same tools as my project" — a committed Flox environment is a file and a commit, not a pipeline you have to babysit.

## Usage

### Local environment

```yml
steps:
  - command: npm run build
    plugins:
      - imkarrer/flox-buildkite-plugin#v1.0.0:
          command: npm run build
```

The `.flox/` directory lives in your repo — no auth needed.

### Remote environment from FloxHub

```yml
steps:
  - command: netlify deploy
    plugins:
      - imkarrer/flox-buildkite-plugin#v1.0.0:
          command: netlify deploy
          environment: my-org/netlify-deploy
          floxhub-token: BKvR...
```

Better: set the token once on the agent as an environment variable.

```yml
steps:
  - command: netlify deploy
    plugins:
      - imkarrer/flox-buildkite-plugin#v1.0.0:
          command: netlify deploy
          environment: my-org/netlify-deploy
```

```bash
# Agent environment or Buildkite pipeline env:
FLOX_TOKEN=BKvR...
```

### Remote environment from another org (requires trust)

```yml
steps:
  - command: deploy
    plugins:
      - imkarrer/flox-buildkite-plugin#v1.0.0:
          command: deploy
          environment: another-org/tools
          floxhub-token: BKvR...
          trust: true
```

### Multi-step pipeline

```yml
steps:
  - label: ":flox: Lint"
    command: eslint .
    plugins:
      - imkarrer/flox-buildkite-plugin#v1.0.0:
          command: eslint .
  - label: ":flox: Test"
    command: vitest run
    plugins:
      - imkarrer/flox-buildkite-plugin#v1.0.0:
          command: vitest run
```

### Monorepo subdirectory

```yml
steps:
  - label: ":rust: Build backend"
    plugins:
      - imkarrer/flox-buildkite-plugin#v1.0.0:
          dir: backend
          command: cargo build --release
  - label: ":react: Build frontend"
    plugins:
      - imkarrer/flox-buildkite-plugin#v1.0.0:
          dir: frontend
          command: vite build
```

### Matrix build

```yml
steps:
  - label: ":flox: Test python {{ matrix.env }}"
    plugins:
      - imkarrer/flox-buildkite-plugin#v1.0.0:
          environment: my-org/python-{{ matrix.env }}
          command: pytest
    matrix:
      - env: "3.11"
      - env: "3.12"
      - env: "3.13"
```

### Containerize and push

```yml
steps:
  - label: ":docker: Build image"
    plugins:
      - imkarrer/flox-buildkite-plugin#v1.0.0:
          command: flox containerize --runtime docker
  - label: ":docker: Push"
    commands:
      - docker tag myapp-container:latest registry.example.com/myapp:${BUILDKITE_COMMIT}
      - docker push registry.example.com/myapp:${BUILDKITE_COMMIT}
```

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `command` | string | — | Command to run inside the Flox environment |
| `channel` | string | `stable` | Flox release channel (`stable`, `qa`, `nightly`, or commit hash) |
| `version` | string | latest | Pin a specific flox version |
| `environment` | string | — | Remote FloxHub environment in `owner/name` format |
| `dir` | string | — | Path to directory containing a `.flox/` environment |
| `floxhub-token` | string | — | FloxHub token for remote environment auth (falls back to `FLOX_TOKEN` env var) |
| `trust` | boolean | `false` | Trust remote environment hook (equivalent to `flox activate --trust`) |
| `disable-metrics` | boolean | `true` | Disable anonymous usage telemetry |

### Auth precedence

1. `floxhub-token` plugin config
2. `FLOX_TOKEN` environment variable (set on the agent or pipeline)
3. If neither is set and a remote environment is requested, activation fails

Local environments (`.flox/` in the repo via `dir`) need no auth.

## Docker

Use a pre-baked agent image to skip the install step. No downloads at job time, pinned flox version.

```dockerfile
FROM buildkite/agent:3

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    sudo \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN bash <(curl -fsSL https://flox.dev/install) --channel stable --yes

USER buildkite
```

Build, push, and configure your agents:

```bash
docker build -t your-registry/buildkite-agent-flox:latest .
docker push your-registry/buildkite-agent-flox:latest
```

## Developing

Run the bats unit tests (they stub `flox`, so no account or network needed):

```shell
docker-compose run --rm tests
```

Lint the plugin definition:

```shell
docker-compose run --rm lint
```

### End-to-end

The plugin dogfoods itself via [`.buildkite/pipeline.yml`](.buildkite/pipeline.yml) against the environment in `examples/hello` — no separate consumer repo required. Point a Buildkite pipeline at this repo to run it. Generate the example environment once with:

```shell
flox init -d examples/hello
flox install -d examples/hello hello
```

Commit the resulting `examples/hello/.flox/` so the lockfile is pinned. For the remote-environment step, `flox push -d examples/hello` and set `FLOX_TOKEN` on the agent.

## License

MIT
