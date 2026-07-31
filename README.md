# Flox Buildkite Plugin

Run commands inside reproducible [Flox](https://flox.dev) environments in your Buildkite pipelines.

## How it works

The plugin auto-detects `flox` on `PATH`. If missing, it downloads and installs flox from `https://flox.dev/install`.

For remote environments on FloxHub, pass a `floxhub-token` (or set `FLOX_TOKEN` on the agent). Local `.flox/` environments in your repo need no auth.

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

```shell
docker-compose run --rm tests
```

## License

MIT
