#!/usr/bin/env bash
# smart-commit pre-commit security audit
# Usage: bash pre-commit-audit.sh [--strict]
# Exit codes: 0 = clean, 1 = warnings, 2 = critical (must block)

set -euo pipefail

STRICT="${1:-}"
EXIT_CODE=0
WARNINGS=()
CRITICALS=()

# Colors (disable if not a terminal)
if [ -t 1 ]; then
  RED='\033[0;31m'
  YELLOW='\033[0;33m'
  GREEN='\033[0;32m'
  NC='\033[0m'
else
  RED='' YELLOW='' GREEN='' NC=''
fi

log_critical() { CRITICALS+=("$1"); echo -e "${RED}🚫 CRITICAL: $1${NC}"; }
log_warning()  { WARNINGS+=("$1");  echo -e "${YELLOW}⚠️  WARNING: $1${NC}"; }
log_ok()       { echo -e "${GREEN}✅ $1${NC}"; }

echo "═══════════════════════════════════════════"
echo "  Smart Commit — Pre-Commit Security Audit"
echo "═══════════════════════════════════════════"
echo ""

# --- 1. Check for staged secrets ---
echo "🔍 Scanning for secrets..."

STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true)

if [ -n "$STAGED_FILES" ]; then
  # Check for sensitive file extensions
  SENSITIVE_EXTS=$(echo "$STAGED_FILES" | grep -iE '\.(env|pem|key|p12|pfx|jks|keystore|secret|credentials|htpasswd)$' || true)
  if [ -n "$SENSITIVE_EXTS" ]; then
    while IFS= read -r f; do
      log_critical "Sensitive file staged: $f"
    done <<< "$SENSITIVE_EXTS"
  fi

  # Check for credential patterns in staged content
  for f in $STAGED_FILES; do
    [ -f "$f" ] || continue
    # Skip binary files
    file "$f" 2>/dev/null | grep -q text || continue

    if grep -qE '(PRIVATE KEY|password\s*=\s*['\''"][^'\''"]{4,}|api[_-]?key\s*=\s*['\''"][A-Za-z0-9]{16,}|sk-[a-zA-Z0-9]{20,}|AKIA[0-9A-Z]{16})' "$f" 2>/dev/null; then
      log_critical "Potential secret found in: $f"
    fi
  done
else
  echo "  No staged files to scan."
fi

if [ ${#CRITICALS[@]} -eq 0 ]; then
  log_ok "No secrets detected"
fi

echo ""

# --- 2. Check for large files ---
echo "🔍 Checking file sizes..."

if [ -n "$STAGED_FILES" ]; then
  for f in $STAGED_FILES; do
    [ -f "$f" ] || continue
    SIZE=$(stat -c%s "$f" 2>/dev/null || stat -f%z "$f" 2>/dev/null || echo 0)
    SIZE_MB=$(( SIZE / 1048576 ))

    if [ "$SIZE" -gt 104857600 ]; then
      log_critical "File >100MB (${SIZE_MB}MB): $f — use Git LFS"
    elif [ "$SIZE" -gt 52428800 ]; then
      log_warning "File >50MB (${SIZE_MB}MB): $f — consider .gitignore or Git LFS"
    elif [ "$SIZE" -gt 10485760 ]; then
      log_warning "File >10MB (${SIZE_MB}MB): $f"
    fi
  done
fi

if [ ${#WARNINGS[@]} -eq 0 ] && [ ${#CRITICALS[@]} -eq 0 ]; then
  log_ok "All files within size limits"
fi

echo ""

# --- 3. Check .gitignore ---
echo "🔍 Checking .gitignore..."

MISSING_PATTERNS=()
ESSENTIAL_PATTERNS=(".env" "node_modules/" ".DS_Store" "*.pem" "*.key" "__pycache__/")

if [ -f .gitignore ]; then
  for pattern in "${ESSENTIAL_PATTERNS[@]}"; do
    if ! grep -qF "$pattern" .gitignore 2>/dev/null; then
      MISSING_PATTERNS+=("$pattern")
    fi
  done

  if [ ${#MISSING_PATTERNS[@]} -gt 0 ]; then
    log_warning "Missing .gitignore patterns: ${MISSING_PATTERNS[*]}"
  else
    log_ok ".gitignore covers essentials"
  fi
else
  log_warning "No .gitignore file found"
fi

echo ""

# --- 4. Summary ---
echo "═══════════════════════════════════════════"

if [ ${#CRITICALS[@]} -gt 0 ]; then
  echo -e "${RED}❌ BLOCKED: ${#CRITICALS[@]} critical issue(s) found${NC}"
  echo "   Resolve before committing."
  EXIT_CODE=2
elif [ ${#WARNINGS[@]} -gt 0 ]; then
  echo -e "${YELLOW}⚠️  ${#WARNINGS[@]} warning(s) — review before committing${NC}"
  EXIT_CODE=1
else
  echo -e "${GREEN}✅ All clear — safe to commit${NC}"
fi

echo "═══════════════════════════════════════════"

# In strict mode, warnings also block
if [ "$STRICT" = "--strict" ] && [ ${#WARNINGS[@]} -gt 0 ]; then
  EXIT_CODE=2
fi

exit $EXIT_CODE
