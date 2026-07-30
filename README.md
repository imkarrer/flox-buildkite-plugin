# Flox Buildkite Plugin

Run commands inside reproducible Flox environments in your Buildkite pipelines.

## Example

```yml
steps:
  - command: npm run build
    plugins:
      - flox/flox#v1.0.0:
          command: npm run build
```

## Configuration

### `command` (Required, string)

The command to run inside the Flox environment.

### `install` (Optional, boolean)

Install flox if not already present on the agent. Default: `true`.

### `channel` (Optional, string)

Flox release channel. One of: `stable`, `qa`, `nightly`, or a commit hash. Default: `stable`.

### `version` (Optional, string)

Pin a specific flox version. Default: latest from channel.

### `environment` (Optional, string)

Remote FloxHub environment to activate, in `owner/name` format.

### `dir` (Optional, string)

Path to a directory containing a `.flox/` environment.

### `disable-metrics` (Optional, boolean)

Disable anonymous usage telemetry. Default: `true`.

## Advanced examples

### Use a remote environment from FloxHub

```yml
steps:
  - command: npm run build
    plugins:
      - flox/flox#v1.0.0:
          command: npm run build
          environment: my-org/my-node-env
```

### Pin a specific flox version

```yml
steps:
  - command: make test
    plugins:
      - flox/flox#v1.0.0:
          command: make test
          version: "1.3.2"
          channel: stable
```

### Use an environment from a subdirectory

```yml
steps:
  - command: cargo build
    plugins:
      - flox/flox#v1.0.0:
          command: cargo build
          dir: backend
```

### Skip installation on a pre-configured runner

```yml
steps:
  - command: flox activate -c "pytest"
    plugins:
      - flox/flox#v1.0.0:
          command: pytest
          install: false
```

## Developing

Run tests with BATS:

```shell
docker-compose run --rm tests
```

## License

MIT
