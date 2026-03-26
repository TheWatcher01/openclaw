# Security Checklist — Pre-Commit Audit

Comprehensive security audit to run before every commit. The smart-commit skill references this checklist during Phase 1.

## Critical — Block Commit

These findings MUST block the commit. Secrets in git history persist even after deletion.

### 1. Credential Detection

Scan all staged files for:

```regex
# API keys and tokens
(api[_-]?key|apikey|api[_-]?secret)\s*[:=]\s*['"]?[A-Za-z0-9_\-]{16,}
(token|auth[_-]?token|access[_-]?token)\s*[:=]\s*['"]?[A-Za-z0-9_\-]{16,}

# AWS
AKIA[0-9A-Z]{16}
aws[_-]?secret[_-]?access[_-]?key\s*[:=]

# OpenAI / Anthropic / AI providers
sk-[a-zA-Z0-9]{20,}
sk-ant-[a-zA-Z0-9]{20,}

# Private keys
-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----

# Passwords in config
password\s*[:=]\s*['"][^'"]{4,}['"]
passwd\s*[:=]\s*['"][^'"]{4,}['"]

# Database URLs with credentials
(mysql|postgresql|postgres|mongodb|redis):\/\/[^:]+:[^@]+@

# Generic high-entropy secrets (base64 blocks > 40 chars)
['"][A-Za-z0-9+/=]{40,}['"]
```

### 2. Sensitive File Extensions

Block staging of these file types:

| Extension                      | Type                  |
| ------------------------------ | --------------------- |
| `.env`, `.env.*`               | Environment variables |
| `.pem`, `.key`, `.p12`, `.pfx` | Certificates / keys   |
| `.jks`, `.keystore`            | Java keystores        |
| `.htpasswd`, `.htaccess`       | Server auth           |
| `.credentials`, `.secret`      | Generic secrets       |
| `id_rsa`, `id_ed25519`         | SSH keys              |
| `.npmrc` (with token)          | Package registry auth |
| `.pypirc` (with password)      | PyPI auth             |

### 3. Database Dumps

Block `.sql` files larger than 1KB (likely contain data, not just schema).

```bash
find . -name "*.sql" -size +1k -newer .git/HEAD 2>/dev/null
```

## Warning — Require Confirmation

### 4. Large Files

| Size   | Action                                |
| ------ | ------------------------------------- |
| >100MB | Block — suggest Git LFS               |
| >50MB  | Strong warning — suggest `.gitignore` |
| >10MB  | Warn — ask for confirmation           |

```bash
# Find large files about to be committed
git diff --cached --name-only | while read f; do
  [ -f "$f" ] && size=$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f" 2>/dev/null)
  [ "$size" -gt 10485760 ] && echo "LARGE: $f ($(( size / 1048576 ))MB)"
done
```

### 5. Binary Files

Warn on unexpected binary files:

```bash
git diff --cached --name-only | while read f; do
  [ -f "$f" ] && file "$f" | grep -qv text && echo "BINARY: $f"
done
```

Acceptable binaries: images (`.png`, `.jpg`, `.svg`, `.ico`), fonts (`.woff`, `.woff2`, `.ttf`).

### 6. Suspicious Patterns

```bash
# TODO/FIXME/HACK with security implications
grep -rnE '(TODO|FIXME|HACK).*(password|secret|auth|token|credential)' --include='*.{js,ts,py,go,rs,java,rb,php}' .

# Disabled security features
grep -rnE '(verify\s*=\s*False|SSL_VERIFY.*false|insecure.*true|disable.*auth)' --include='*.{js,ts,py,go,rs,java,rb,php}' .

# Hardcoded localhost with ports (potential debug leftovers)
grep -rnE 'https?://localhost:[0-9]+' --include='*.{js,ts,py,go,rs,java,rb,php}' .
```

## Auto-Fix — Silent Corrections

### 7. `.gitignore` Validation

Minimum required patterns. If missing, add them and include in the first commit:

```gitignore
# === Secrets ===
.env
.env.*
!.env.example
*.pem
*.key
*.p12
*.pfx
*.jks
*.keystore

# === Dependencies ===
node_modules/
.venv/
venv/
vendor/
__pycache__/
*.pyc
.bundle/
Pods/

# === Build outputs ===
dist/
build/
out/
.next/
target/
*.class

# === IDE ===
.idea/
.vscode/settings.json
*.swp
*.swo
*~

# === OS ===
.DS_Store
Thumbs.db
desktop.ini

# === Logs ===
*.log
logs/
npm-debug.log*
yarn-debug.log*
```

### 8. Pre-Commit Hook Check

If the project uses pre-commit hooks (`.pre-commit-config.yaml`, `.husky/`), respect them:

```bash
# Check for pre-commit framework
[ -f .pre-commit-config.yaml ] && echo "pre-commit framework detected"
[ -d .husky ] && echo "husky hooks detected"
[ -f .git/hooks/pre-commit ] && echo "git pre-commit hook detected"
```

Do NOT bypass hooks. If hooks fail, report the error to the user.

## Post-Commit Verification

After committing, verify no secrets slipped through:

```bash
# Quick check last commit
git diff-tree --no-commit-id -r HEAD --name-only | \
  xargs grep -lE '(password|secret|api_key|token)\s*[:=]' 2>/dev/null
```

If found: immediately run `git reset HEAD~1` and alert the user.
