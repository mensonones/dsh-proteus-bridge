#!/usr/bin/env bash
# Fetch recon tools as static binaries into ./tools/bin — no sudo, no system
# install, fully removable (`--clean`). Verifies sha256 against the release
# checksums file. Works for ProjectDiscovery tools and common non-PD tools
# (ffuf, gobuster, feroxbuster, ...) by auto-selecting the right release asset.
#
# Usage:
#   tools/fetch-recon.sh                 # fetch the default set
#   tools/fetch-recon.sh httpx ffuf      # fetch a subset (any GitHub-released tool below)
#   tools/fetch-recon.sh --clean         # remove ./tools/bin
set -euo pipefail

BINDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/bin"

if [[ "${1:-}" == "--clean" ]]; then
  rm -rf "$BINDIR"; echo "removed $BINDIR"; exit 0
fi

case "$(uname -m)" in
  x86_64|amd64) ARCH_RE='(amd64|x86_64)' ;;
  aarch64|arm64) ARCH_RE='(arm64|aarch64)' ;;
  *) echo "unsupported arch: $(uname -m)" >&2; exit 1 ;;
esac
OS_RE='(linux|Linux)'   # extend for darwin if needed

DEFAULT_TOOLS=(subfinder dnsx naabu httpx nuclei)
TOOLS=("$@"); [[ ${#TOOLS[@]} -eq 0 ]] && TOOLS=("${DEFAULT_TOOLS[@]}")

# tool -> GitHub owner/repo. Anything not listed defaults to projectdiscovery/<tool>.
repo_for() {
  case "$1" in
    ffuf)        echo "ffuf/ffuf" ;;
    gobuster)    echo "OJ/gobuster" ;;
    feroxbuster) echo "epi052/feroxbuster" ;;
    katana|httpx|naabu|nuclei|subfinder|dnsx|tlsx|dnsx|asnmap|mapcidr|notify|interactsh-client)
                 echo "projectdiscovery/$1" ;;
    *)           echo "projectdiscovery/$1" ;;
  esac
}

mkdir -p "$BINDIR"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

fetch_one() {
  local tool="$1"
  if [[ -x "$BINDIR/$tool" ]]; then echo "  $tool already present, skipping"; return; fi
  local repo; repo="$(repo_for "$tool")"
  local json; json="$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest")" \
    || { echo "  !! no release info for $tool ($repo)" >&2; return 1; }

  # all downloadable asset URLs
  local urls; urls="$(printf '%s' "$json" | grep -oE '"browser_download_url":[[:space:]]*"[^"]+"' | sed -E 's/.*"(https[^"]+)"/\1/')"

  # pick the linux + arch archive (.zip or .tar.gz), and the checksums .txt (not .sig)
  local arch_url sums_url
  arch_url="$(printf '%s\n' "$urls" | grep -iE "$OS_RE" | grep -iE "$ARCH_RE" | grep -iE '\.(zip|tar\.gz|tgz)$' | head -1)"
  sums_url="$(printf '%s\n' "$urls" | grep -iE 'checksums?.*\.txt$' | grep -viE '\.sig$' | head -1)"
  [[ -n "$arch_url" ]] || { echo "  !! no linux archive asset for $tool ($repo)" >&2; return 1; }

  local arc="$TMP/$(basename "$arch_url")"
  echo "  $tool <- $repo ($(basename "$arch_url")) ..."
  curl -fsSL "$arch_url" -o "$arc"

  if [[ -n "$sums_url" ]]; then
    curl -fsSL "$sums_url" -o "$TMP/${tool}_sums.txt"
    ( cd "$TMP" && grep -E "[[:space:]]$(basename "$arc")\$" "${tool}_sums.txt" | sha256sum -c - >/dev/null ) \
      || { echo "  !! checksum FAILED for $(basename "$arc") — aborting $tool" >&2; return 1; }
  else
    echo "  (no checksums file published for $tool — skipping integrity check)" >&2
  fi

  local x="$TMP/x_$tool"; mkdir -p "$x"
  case "$arc" in
    *.zip)              unzip -o -q "$arc" -d "$x" ;;
    *.tar.gz|*.tgz)     tar -xzf "$arc" -C "$x" ;;
  esac

  # locate the binary: prefer an exact-name match, else the first executable regular file
  local bin
  bin="$(find "$x" -type f -name "$tool" 2>/dev/null | head -1)"
  [[ -n "$bin" ]] || bin="$(find "$x" -type f -perm -u+x ! -iname '*.txt' ! -iname '*.md' ! -iname 'LICENSE*' 2>/dev/null | head -1)"
  [[ -n "$bin" ]] || { echo "  !! could not find $tool binary in archive" >&2; return 1; }
  install -m 0755 "$bin" "$BINDIR/$tool"
  echo "    -> $BINDIR/$tool"
}

echo "Fetching into $BINDIR:"
rc=0
for t in "${TOOLS[@]}"; do fetch_one "$t" || rc=1; done
echo
echo "Installed:"; ls -1 "$BINDIR" 2>/dev/null | sed 's/^/  /' || true
echo
echo "Add to PATH for this shell:  export PATH=\"$BINDIR:\$PATH\""
echo "(The launcher dsh-cybersec.sh already does this.)"
exit $rc
