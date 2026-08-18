# Demo cheatsheet

**The pattern, every time:** teach on the slides → switch to the terminal
once to prove it → switch back to land. You are not recapping after.
You are not bouncing every beat.

Beat 1 / Beat 3 / Beat 4 slides are **backup**. If the live demo worked,
advance past them without talking. If wifi dies, stay on slides and
narrate those instead — never debug in front of them.

Keep this file on the **laptop**. Projector is slides, except during
the terminal blocks below.

```console
# Set this ONCE in both demo terminals, before you cd to /tmp.
TALK=/home/you/flox-buildkite-plugin/docs/talks
```

Font ≥18pt. Warm the store the morning of, then reset:

```console
# left
rm -rf /tmp/hardway && mkdir -p /tmp/hardway && cd /tmp/hardway && git init

# right
rm -rf /tmp/easyway && mkdir -p /tmp/easyway && cd /tmp/easyway
export FLOX_DISABLE_METRICS=true
```

---

## Act 0

Clean terminal, no `flox activate`. Projector shows the PDF, then:

```console
cd "$TALK"
make                          # let it fail, read the error
flox activate -- make serve
```

Browser takes the projector for the rest of the talk. Press <kbd>P</kbd>.

---

## Act 4 — hard way

Stay on **slides** through the files. Terminal only for the commands.

| # | Projector | What you do |
|---|---|---|
| 1 | **The hard way** | One sentence. Don't type. Advance. |
| 2 | **Beat 1** | Talk at the slide. First cut if behind. Advance. |
| 3 | **Beat 2** | Point at the ceremony. This is the premise. *Then* switch. |
| 4 | **Terminal** | Paste + run the block below. Don't come back mid-block. |
| 5 | **Beat 3, Beat 4** | Advance past both. They already saw it live. |
| 6 | **Scoring** | Talk. Stay here. |

Terminal block (one paste of the file, then type the short commands):

```console
cp "$TALK/demo/flake.nix" .
nix develop --command node --version          # git-tracking error
git add flake.nix
nix develop --command node --version          # dirty-tree warning
time nix develop --command bash -c 'node --version; pnpm --version'
time nix develop --command node --version     # warm
```

Switch back. Skip Beat 3 and Beat 4. Land on **Scoring the hard way**.

---

## Act 5 — easy way

Same shape: a little terminal, a slide that is the argument, a little
more terminal, a landing slide.

| # | Projector | What you do |
|---|---|---|
| 1 | **The easy way** | One sentence. Switch. |
| 2 | **Terminal** | The three commands + grep. Don't come back mid-block. |
| 3 | **Same engine** | Money moment. Let the columns sit. *Then* switch. |
| 4 | **Terminal** | Paste services, run. |
| 5 | **And then it does more** | Advance past it — they just saw it live. |
| 6 | **Landing line** | "Flox isn't hiding Nix from you." Stay in slides forever. |

First terminal block:

```console
flox init
flox install nodejs_22 pnpm
flox activate -- bash -c 'node --version; pnpm --version'
grep -v '^\s*#' .flox/env/manifest.toml | grep -v '^$'
```

Switch back to **Same engine**. Let it sit. Then second terminal block:

```console
cat "$TALK/demo/services.toml" >> .flox/env/manifest.toml
flox activate --start-services -- bash -c 'sleep 3; curl -s localhost:$API_PORT; flox services status'
```

Switch back. Skip **And then it does more**. Land on the line, then Act 6
is slides-only.
