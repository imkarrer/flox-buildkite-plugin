# Flox Buildkite Plugin — Agent Context

This repo uses [flox-buildkite-plugin](https://github.com/imkarrer/flox-buildkite-plugin). CI environments come from `.flox/` in the repo, not from Dockerfiles or pre-baked runner images.

## What this means for you

- A `.flox/` directory checked into the repo defines the build environment.
- The `manifest.toml` inside it lists packages, vars, hooks, and services.
- `manifest.lock` pins exact versions for reproducibility.
- The Buildkite plugin activates this environment in CI — no Docker build, no push, no tag.
- You own the environment definition the same way you own the code.

## How to work with this repo

### Create or update the environment

```bash
# Initialize if .flox/ doesn't exist
flox init

# Install dependencies
flox install nodejs python3 postgresql_16

# Check what's installed
flox list

# Edit config (services, vars, hooks)
flox edit
```

### Pin dependencies

Add version constraints or the agent can resolve them:

```toml
[install]
nodejs.pkg-path = "nodejs"
nodejs.version = "20.18.1"
```

Or use the lockfile directly — pin the lock and CI will use exactly those versions:

```bash
flox update
```

### Testing locally before CI

```bash
# Run your build command exactly as CI will
flox activate -c "npm run build"

# Or enter the environment interactively
flox activate
```

### Commit the environment

```bash
git add .flox/
git commit -m "feat: add flox dev environment"
```

Only `manifest.toml` and `manifest.lock` need tracking. The `env/` and `cache/` subdirectories are generated.

## What not to do

- Don't write a Dockerfile for the build environment — that's what `.flox/` is for.
- Don't push build images to a registry for CI — the plugin activates the environment on the runner.
- Don't version-bump image tags when deps change — commit the updated `manifest.lock`.
