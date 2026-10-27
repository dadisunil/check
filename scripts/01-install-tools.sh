#!/usr/bin/env bash
# Installs lab tools into ~/bin (no admin needed). Run in Git Bash:  bash scripts/01-install-tools.sh
set -euo pipefail
BIN="$HOME/bin"; TMP="$(mktemp -d)"; mkdir -p "$BIN"
trap 'rm -rf "$TMP"' EXIT

# Unzip via Windows PowerShell (Git Bash has no unzip)
unzip_to() { powershell -NoProfile -Command "Expand-Archive -Force -LiteralPath '$(cygpath -w "$1")' -DestinationPath '$(cygpath -w "$2")'"; }
fetch() { echo ">> $1"; curl -fsSL "$2" -o "$3"; }
zip_tool() { # name url path-to-exe-inside-zip
  fetch "$1" "$2" "$TMP/$1.zip"; mkdir -p "$TMP/$1"; unzip_to "$TMP/$1.zip" "$TMP/$1"
  cp "$TMP/$1/$3" "$BIN/$(basename "$3")"
}

fetch kind      https://kind.sigs.k8s.io/dl/v0.24.0/kind-windows-amd64 "$BIN/kind.exe"
fetch yq        https://github.com/mikefarah/yq/releases/download/v4.44.3/yq_windows_amd64.exe "$BIN/yq.exe"
zip_tool helm      https://get.helm.sh/helm-v3.16.2-windows-amd64.zip windows-amd64/helm.exe
zip_tool flux      https://github.com/fluxcd/flux2/releases/download/v2.9.6/flux_2.9.6_windows_amd64.zip flux.exe
zip_tool k9s       https://github.com/derailed/k9s/releases/download/v0.32.5/k9s_Windows_amd64.zip k9s.exe
zip_tool terraform https://releases.hashicorp.com/terraform/1.9.8/terraform_1.9.8_windows_amd64.zip terraform.exe
zip_tool gh        https://github.com/cli/cli/releases/download/v2.60.1/gh_2.60.1_windows_amd64.zip bin/gh.exe

# Garden pinned to 0.13.62 like Uniphore (0.14 has breaking changes). Ships as a folder with garden.exe + deps.
fetch garden https://github.com/garden-io/garden/releases/download/0.13.62/garden-0.13.62-windows-amd64.zip "$TMP/garden.zip"
rm -rf "$HOME/garden"; mkdir -p "$HOME/garden"; unzip_to "$TMP/garden.zip" "$HOME/garden"
GARDEN_EXE="$(find "$HOME/garden" -name garden.exe | head -1)"
printf '#!/usr/bin/env bash\nexec "%s" "$@"\n' "$GARDEN_EXE" > "$BIN/garden"; chmod +x "$BIN/garden"

# Put ~/bin on PATH for future Git Bash sessions
grep -q 'HOME/bin' "$HOME/.bashrc" 2>/dev/null || echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
export PATH="$BIN:$PATH"
echo; for t in kind helm flux k9s terraform yq gh garden; do printf '%-10s' "$t"; command -v "$t" >/dev/null && echo ok || echo MISSING; done
echo "Open a NEW Git Bash (or: source ~/.bashrc), then run gh auth login."
