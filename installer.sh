#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

# ==============================================================================
# CLAUDE CODE AUTOMATED DEPLOYMENT ENGINE (FINAL STABLE RELEASE)
# Target: Ubuntu / Debian / Kali Linux
# ==============================================================================

REQUIRED_NODE_MAJOR=22
WORKDIR="$HOME/claude_workspace"
CONFIG_DIR="$HOME/.config/claude"
ENV_FILE="$CONFIG_DIR/env"
NPM_GLOBAL="$HOME/.npm-global"
LOCAL_BIN="$HOME/.local/bin"
LOG_FILE="$HOME/claude_install.log"

log()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $*"  | tee -a "$LOG_FILE"; }
error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "$LOG_FILE" >&2; }

# ------------------------------------------------------------------------------
# 1. SYSTEM VALIDATION
# ------------------------------------------------------------------------------
log "Checking system compatibility..."

if [ ! -f /etc/os-release ]; then
    error "Unsupported system."
    exit 1
fi

. /etc/os-release
case "$ID" in
    ubuntu|debian|kali) ;;
    *)
        error "Unsupported OS: $ID"
        exit 1
    ;;
esac

if [ "$EUID" -eq 0 ]; then
    error "Do not run as root."
    exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
    error "sudo is required but not found."
    exit 1
fi

# ------------------------------------------------------------------------------
# 2. DEPENDENCIES
# ------------------------------------------------------------------------------
log "Installing dependencies..."
sudo apt-get update -y
sudo apt-get install -y curl git build-essential gpg ca-certificates

# ------------------------------------------------------------------------------
# 3. NODE.JS INSTALLATION
# ------------------------------------------------------------------------------
log "Installing Node.js v${REQUIRED_NODE_MAJOR}..."

sudo mkdir -p /etc/apt/keyrings
sudo chmod 0755 /etc/apt/keyrings

curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | gpg --dearmor -o /tmp/nodesource.gpg

sudo mv -f /tmp/nodesource.gpg /etc/apt/keyrings/nodesource.gpg
sudo chmod 0644 /etc/apt/keyrings/nodesource.gpg

echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${REQUIRED_NODE_MAJOR}.x nodistro main" \
| sudo tee /etc/apt/sources.list.d/nodesource.list >/dev/null

sudo apt-get update -y
sudo apt-get install -y nodejs

NODE_MAJOR=$(node -p "process.versions.node.split('.')[0]" 2>/dev/null || echo "0")

if [ "$NODE_MAJOR" -lt "$REQUIRED_NODE_MAJOR" ]; then
    error "Node version too low: $(node -v 2>/dev/null || echo 'not found')"
    exit 1
fi

log "Node OK: $(node -v)"

if ! command -v npm >/dev/null 2>&1; then
    error "npm not found after Node.js installation."
    exit 1
fi

# ------------------------------------------------------------------------------
# 4. NPM USER SPACE (FULL IDEMPOTENT FIX)
# ------------------------------------------------------------------------------
log "Configuring npm environment..."

mkdir -p "$NPM_GLOBAL" "$LOCAL_BIN"
npm config set prefix "$NPM_GLOBAL"

# EXACT LINE MATCH (true idempotency)
PATH_LINE='export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"'

for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [ -f "$rc" ] || continue

    if ! grep -Fxq "$PATH_LINE" "$rc"; then
        echo "$PATH_LINE" >> "$rc"
        log "Updated PATH in $rc"
    else
        log "$rc already configured, skipping"
    fi
done

export PATH="$LOCAL_BIN:$NPM_GLOBAL/bin:$PATH"
hash -r

# ------------------------------------------------------------------------------
# 5. INSTALL CLAUDE CLI
# ------------------------------------------------------------------------------
log "Installing Claude CLI..."

npm install -g @anthropic-ai/claude-code

hash -r

if ! command -v claude >/dev/null 2>&1 && [ ! -x "$NPM_GLOBAL/bin/claude" ]; then
    error "Claude CLI installation failed."
    exit 1
fi

# ------------------------------------------------------------------------------
# 6. CONFIGURATION (SECURE)
# ------------------------------------------------------------------------------
log "Configuring API environment..."

mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

echo -n "[?] Enter DeepSeek API Key: "
read -rs API_KEY
echo ""

if [ ${#API_KEY} -lt 20 ]; then
    error "Invalid API key (too short)."
    exit 1
fi

cat > "$ENV_FILE" <<EOF
export ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
export ANTHROPIC_API_KEY="$API_KEY"
export ANTHROPIC_AUTH_TOKEN="$API_KEY"
export ANTHROPIC_MODEL="deepseek-v4-pro"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-v4-flash"
export CLAUDE_CODE_EFFORT_LEVEL="max"
EOF

chmod 600 "$ENV_FILE"
unset API_KEY

# ------------------------------------------------------------------------------
# 7. WRAPPER (SAFE EXECUTION)
# ------------------------------------------------------------------------------
log "Creating runtime wrapper..."

WRAPPER="$LOCAL_BIN/claude"

# Note: heredoc is unquoted so $ENV_FILE / $NPM_GLOBAL expand NOW (install time),
# producing absolute, fixed paths baked into the wrapper.
cat > "$WRAPPER" <<EOF
#!/usr/bin/env bash
set -Eeuo pipefail

[ -f "$ENV_FILE" ] && source "$ENV_FILE"
exec "$NPM_GLOBAL/bin/claude" "\$@"
EOF

chmod 700 "$WRAPPER"

# ------------------------------------------------------------------------------
# 8. WORKSPACE
# ------------------------------------------------------------------------------
log "Creating workspace..."

mkdir -p "$WORKDIR"
chmod 700 "$WORKDIR"

cat > "$WORKDIR/CLAUDE.md" <<'EOF'
# Workspace
- Deterministic execution environment
- No persistent secrets outside config directory
EOF

# ------------------------------------------------------------------------------
# DONE
# ------------------------------------------------------------------------------
echo ""
echo "=============================================="
echo "   INSTALLATION COMPLETE"
echo "=============================================="
echo "Run:"
echo "  source ~/.bashrc || source ~/.zshrc"
echo "  claude"
echo "=============================================="
