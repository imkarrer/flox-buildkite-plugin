# Flox Buildkite Plugin

Run commands inside reproducible [Flox](https://flox.dev) environments in your Buildkite pipelines.

## Requirements

### Auto-install path (`install: true`, default)

The plugin installs flox on first use via `https://flox.dev/install`. The runner needs:

- `curl` — downloads the installer
- `sudo` — the installer writes to `/nix` and `/usr/bin`
- `xz-utils` — used by the installer for decompression

The install step runs once; subsequent pipeline steps reuse the installed binary.

### Pre-installed path (`install: false`)

Use a pre-baked agent image with flox already installed. Only `bash` is required.

## Usage

```yml
steps:
  - command: npm run build
    plugins:
      - imkarrer/flox-buildkite-plugin#v1.0.0:
          command: npm run build
```

### Minimal pipeline

```yml
steps:
  - label: ":flox: Build"
    command: npm run build
    plugins:
      - imkarrer/flox-buildkite-plugin#v1.0.0:
          command: npm run build
```

### Multi-step

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

### Environment from a subdirectory

```yml
steps:
  - label: ":rust: Build backend"
    plugins:
      - imkarrer/flox-buildkite-plugin#v1.0.0:
          dir: backend
          command: cargo build --release
```

### Pre-baked agent (no install step)

```yml
steps:
  - label: ":flox: Fast path"
    plugins:
      - imkarrer/flox-buildkite-plugin#v1.0.0:
          command: pytest
          install: false
```

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `command` | string | — | Command to run inside the Flox environment |
| `install` | boolean | `true` | Install flox if not present on the agent |
| `channel` | string | `stable` | Flox release channel (`stable`, `qa`, `nightly`, or commit hash) |
| `version` | string | latest | Pin a specific flox version |
| `environment` | string | — | Remote FloxHub environment in `owner/name` format |
| `dir` | string | — | Path to directory containing a `.flox/` environment |
| `disable-metrics` | boolean | `true` | Disable anonymous usage telemetry |

## Docker

Use a pre-baked agent image to skip the install step entirely. This is recommended for production — no download, no network dependency at job time, pinned flox version.

```dockerfile
FROM buildkite/agent:3

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    sudo \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN bash <(curl -fsSL https://flox.dev/install) --channel stable --yes \
    && chmod a+rx /usr/local/bin/flox

USER buildkite
```

Build and push:

```bash
docker build -t your-registry/buildkite-agent-flox:latest .
docker push your-registry/buildkite-agent-flox:latest
```

Then configure your Buildkite agents to use this image and set `install: false`:

```yml
steps:
  - label: ":flox: Deploy"
    plugins:
      - imkarrer/flox-buildkite-plugin#v1.0.0:
          command: deploy.sh
          install: false
```

You can also extend the image further by adding your team's CA certs, SSH keys, or other tooling.

## Developing

```shell
docker-compose run --rm tests
```

## License

MIT
