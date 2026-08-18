#!/usr/bin/env bash
#
# Fails if any slide's content runs past the 720px canvas, or is silently
# clipped inside a scroll container.
#
# This is the one deck bug you cannot see while writing: the markdown looks
# fine, the editor preview looks fine, and the bottom two lines of a code block
# are simply gone on the projector. Worth a headless browser to catch.
#
# Usage: ./check-overflow.sh [deck.md]

set -euo pipefail

DECK="${1:-slides.md}"
cd "$(dirname "$0")"

if [ ! -f "$DECK" ]; then
  echo "check-overflow: no such deck: $DECK" >&2
  exit 2
fi

if ! command -v marp >/dev/null 2>&1; then
  echo "check-overflow: marp not found — run inside 'flox activate'" >&2
  exit 2
fi

BROWSER="${CHROME_PATH:-}"
if [ -z "$BROWSER" ] || [ ! -x "$BROWSER" ]; then
  echo "check-overflow: no browser — set CHROME_PATH (the flox hook does this)" >&2
  exit 2
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# The bare template lays every slide out at full size with none hidden, which
# is what makes them measurable in one pass.
marp "$DECK" --template bare -o "$TMP/bare.html" >/dev/null 2>&1

cat >>"$TMP/bare.html" <<'PROBE'
<script>
  // Geist's metrics differ enough from the fallback to change how text wraps,
  // so measuring before it is active invents overflow that isn't there.
  var REQUIRED_FACES = [
    '400 25px "Geist"',
    '700 54px "Geist"',
    '800 74px "Geist"',
    '400 21px "Geist Mono"',
  ];

  // Ground truth is whether the font actually renders, not whether the font
  // bookkeeping says it loaded: document.fonts.check() reports false while an
  // @import'd face is still in flight, even when a locally installed copy of
  // the same family would render fine. So draw with it and compare widths.
  function familyRenders(family) {
    function widthOf(spec) {
      var el = document.createElement("span");
      el.textContent = "Handgloves 0123456789";
      el.style.cssText =
        "position:absolute;left:-9999px;top:0;white-space:nowrap;" +
        "font-size:100px;font-family:" + spec;
      document.body.appendChild(el);
      var w = el.getBoundingClientRect().width;
      el.remove();
      return w;
    }
    // A family that cannot exist, to get the generic fallback's width.
    return widthOf('"' + family + '"') !== widthOf('"__flox_no_such_family__"');
  }

  function fontsReady() {
    var attempts = document.fonts
      ? document.fonts.ready
          .then(function () {
            return Promise.all(REQUIRED_FACES.map(function (face) {
              return document.fonts.load(face).catch(function () {});
            }));
          })
          .catch(function () {})
      : Promise.resolve();

    return attempts
      .then(afterLayout)
      .then(function () {
        return familyRenders("Geist") && familyRenders("Geist Mono");
      })
      .catch(function () { return false; });
  }

  // Let the font swap relayout settle. A timer rather than requestAnimationFrame
  // because rAF does not reliably fire under --virtual-time-budget.
  function afterLayout() {
    return new Promise(function (resolve) {
      setTimeout(resolve, 250);
    });
  }

  // Report into the DOM so `--dump-dom` can carry the result back out.
  function measure() {
    var problems = [];

    // Each slide is its own <svg><foreignObject><section>. If a section ever
    // contains another, the document was parsed wrong and every measurement
    // below is garbage — bail rather than emit invented overflow.
    var nested = document.querySelector("section section");
    if (nested) return null;
    document.querySelectorAll("section").forEach(function (section, index) {
      var slide = index + 1;
      var slack = 2; // sub-pixel layout noise

      if (section.scrollHeight > section.clientHeight + slack) {
        problems.push(
          "slide " + slide + ": content overflows canvas by " +
          (section.scrollHeight - section.clientHeight) + "px"
        );
      }

      // Anything with a non-visible overflow silently eats its own content.
      section.querySelectorAll("*").forEach(function (el) {
        // KaTeX emits a clipped, visually-hidden MathML copy of every formula
        // for screen readers. It is meant to be clipped; ignore it.
        if (el.closest(".katex-mathml")) return;

        var overflow = getComputedStyle(el).overflow;
        if (overflow === "visible") return;
        if (el.scrollHeight > el.clientHeight + slack) {
          problems.push(
            "slide " + slide + ": ." +
            (el.className || el.tagName.toLowerCase()) +
            " clips " + (el.scrollHeight - el.clientHeight) + "px of its content"
          );
        }
      });
    });

    return problems;
  }

  function publish(text) {
    var out = document.createElement("div");
    out.id = "overflow-report";
    out.textContent = text;
    document.body.appendChild(out);
  }

  fontsReady()
    .then(function (ok) {
      if (!ok) return "NOFONTS";
      return afterLayout().then(function () {
        var problems = measure();
        if (problems === null) return "BADPARSE";
        return problems.length ? "FAIL\n" + problems.join("\n") : "OK";
      });
    })
    .then(publish)
    .catch(function (err) { publish("ERROR\n" + err); });
</script>
PROBE

# A throwaway profile: sharing the default user-data-dir between runs lets a
# lingering instance return a half-parsed DOM, which looks like a layout bug.
"$BROWSER" \
  --headless \
  --disable-gpu \
  --no-sandbox \
  --hide-scrollbars \
  --no-first-run \
  --no-default-browser-check \
  --disable-extensions \
  --user-data-dir="$TMP/profile" \
  --virtual-time-budget=15000 \
  --dump-dom \
  "file://$TMP/bare.html" \
  >"$TMP/dom.html" 2>/dev/null

# Pull the report element's text back out of the dumped DOM.
REPORT="$(
  python3 - "$TMP/dom.html" <<'EOF'
import re, sys, html
dom = open(sys.argv[1], encoding="utf-8", errors="replace").read()
m = re.search(r'<div id="overflow-report">(.*?)</div>', dom, re.S)
print(html.unescape(m.group(1)).strip() if m else "NOREPORT")
EOF
)"

case "$REPORT" in
  OK)
    echo "check-overflow: all slides fit."
    ;;
  NOREPORT)
    echo "check-overflow: probe did not run; could not measure slides." >&2
    exit 2
    ;;
  NOFONTS)
    # Not a layout failure. Reporting it as one would train you to ignore this
    # check the first time your network is slow.
    echo "check-overflow: Geist did not load, so slide metrics are unreliable." >&2
    echo "  Check network access to fonts.googleapis.com and re-run." >&2
    exit 2
    ;;
  BADPARSE)
    echo "check-overflow: rendered document was malformed; slides not measured." >&2
    echo "  Re-run; if it persists, inspect 'marp $DECK --template bare'." >&2
    exit 2
    ;;
  ERROR*)
    echo "check-overflow: probe failed:" >&2
    echo "$REPORT" | tail -n +2 | sed 's/^/  /' >&2
    exit 2
    ;;
  *)
    echo "check-overflow: slides overflow the canvas:" >&2
    echo "$REPORT" | tail -n +2 | sed 's/^/  /' >&2
    exit 1
    ;;
esac
