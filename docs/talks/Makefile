# Renders the talk deck. Run inside the Flox environment in this directory:
#
#   flox activate -- make
#   flox activate -- make serve
#
# marp-cli, gnumake, and chromium are pinned in .flox/env/manifest.toml,
# and the activation hook points CHROME_PATH at the real browser path (not
# a /mnt/c wrapper — Marp CLI would otherwise treat it as Windows Chrome).
#
# `make` without that environment is supposed to fail. That's the opening
# of the talk: the toolchain is a file in the repo, not a thing you apt-get.

MARP  := marp
DECK  := slides.md
BUILD := build

# Marp CLI treats a browser under /mnt/<drive>/ as Windows Chrome and rewrites
# file:// URLs to \\wsl.localhost\…, which 404s. A WSL checkout on /mnt/c puts
# the Flox chromium wrapper on that prefix. Resolve to the store path when we
# can; no-op on macOS, where readlink -f is absent and the heuristic does not
# apply. The activation hook does the same; this covers `make` in a shell that
# was activated before the hook changed.
ifneq ($(CHROME_PATH),)
  _chrome_real := $(shell readlink -f "$(CHROME_PATH)" 2>/dev/null)
  ifneq ($(_chrome_real),)
    export CHROME_PATH := $(_chrome_real)
  endif
endif

.PHONY: all html pdf pptx png watch serve clean check check-marp

all: check-marp html pdf

html: check-marp $(BUILD)/slides.html
pdf: check-marp $(BUILD)/slides.pdf
pptx: check-marp $(BUILD)/slides.pptx
png: check-marp $(BUILD)/png

DEPS := $(DECK) theme/flox.css .marprc.yml

# Pedagogical failure for the opening demo. check-marp is a phony aggregator
# prerequisite, not a file prerequisite, so a leftover build/ does not hide
# the miss — `make` still fails if marp isn't on PATH.
check-marp:
	@command -v $(MARP) >/dev/null 2>&1 || { \
	  printf '%s\n' \
	    '' \
	    '  marp is not on PATH.' \
	    '' \
	    '  The toolchain for this deck lives in .flox/ — a file in this repo.' \
	    '  Activate it, then retry:' \
	    '' \
	    '    flox activate -- make serve' \
	    '' \
	    '  No Flox yet? https://flox.dev/docs/install-flox/install' \
	    '' >&2; \
	  exit 1; \
	}

$(BUILD)/slides.html: $(DEPS)
	$(MARP) $(DECK) -o $@

# --pdf-notes puts the speaker notes in the PDF as annotations, so the
# presenter copy carries the script with it.
$(BUILD)/slides.pdf: $(DEPS)
	$(MARP) $(DECK) --pdf --pdf-notes -o $@

$(BUILD)/slides.pptx: $(DEPS)
	$(MARP) $(DECK) --pptx -o $@

$(BUILD)/png: $(DEPS)
	$(MARP) $(DECK) --images png -o $(BUILD)/png/slide.png

# Live preview at http://localhost:8080 with reload on save.
serve: check-marp
	$(MARP) --server --watch .

watch: check-marp
	$(MARP) $(DECK) --watch -o $(BUILD)/slides.html

# Fails if any slide overflows its 720px canvas — the failure mode that is
# invisible in the editor and obvious on a projector. Renders its own copy, so
# it takes the deck source rather than a build artifact.
check:
	@./check-overflow.sh $(DECK)

clean:
	rm -rf $(BUILD)
