# Flox Buildkite Plugin

Run commands inside reproducible [Flox](https://flox.dev) environments in your Buildkite pipelines.

## How it works

If `flox` is already on the agent's `PATH`, the plugin uses it directly. If not, it downloads and installs flox from `https://flox.dev/install` — zero agent setup required.

The auto-install path needs `curl` and `sudo` on the runner. Use the [pre-baked Docker image](#docker) to skip install entirely.

## Usage

```yml
steps:
  - command: npm run build
    plugins:
      - imkarrer/flox-buildkite-plugin#v1.0.0:
          command: npm run build
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

### Remote environment from FloxHub

```yml
steps:
  - label: ":netlify: Deploy"
    plugins:
      - imkarrer/flox-buildkite-plugin#v1.0.0:
          environment: my-org/netlify-deploy
          command: netlify deploy --prod
```

### Environment from a monorepo subdirectory

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

### Matrix build across environments

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
| `disable-metrics` | boolean | `true` | Disable anonymous usage telemetry |

## Docker

Use a pre-baked agent image with flox pre-installed. No downloads at job time, pinned flox version, no dependency on external installers.

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

Build and push:

```bash
docker build -t your-registry/buildkite-agent-flox:latest .
docker push your-registry/buildkite-agent-flox:latest
```

Configure your agents to use this image. The plugin auto-detects flox on `PATH` and skips the install step.

## Developing

```shell
docker-compose run --rm tests
```

## License

MIT
