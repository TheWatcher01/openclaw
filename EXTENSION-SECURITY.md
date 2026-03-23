# Extension Security Model

## Current State (2026-03-21)

Extensions run in the **same Node.js process** as the gateway and have unrestricted access to:

- **Full `process.env`** — all secrets, tokens, API keys, internal flags
- **Filesystem** — limited only by workspace boundary checks in `src/infra/fs-safe.ts`
- **Network** — unrestricted `fetch()` and raw TCP/UDP calls
- **Child processes** — ability to `spawn`/`exec` arbitrary commands

---

## Known Extensions and Their `process.env` Access

| Extension          | Env vars accessed                                                                                             | Notes                                                                            |
| ------------------ | ------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| `matrix`           | `MATRIX_ACCESS_TOKEN`, `MATRIX_HOMESERVER`, `MATRIX_PASSWORD`, `MATRIX_USER_ID`, `OPENCLAW_GATEWAY_PORT`      | Reads credentials directly from env                                              |
| `telegram`         | `TELEGRAM_BOT_TOKEN`, `OPENCLAW_STATE_DIR`, `OPENCLAW_DEBUG_TELEGRAM_ACCOUNTS`, `NODE_ENV`, `TZ`              | Token + state dir                                                                |
| `slack`            | `SLACK_BOT_TOKEN`, `SLACK_APP_TOKEN`, `SLACK_USER_TOKEN`, `OPENCLAW_SLACK_PAIRING_ALLOWFROM_CACHE_TTL_MS`     | Up to 3 tokens visible                                                           |
| `discord`          | `DISCORD_BOT_TOKEN`, `OPENCLAW_GATEWAY_URL`, `OPENCLAW_STATE_DIR`, `NODE_ENV`                                 | Token + internal gateway URL                                                     |
| `irc`              | `IRC_PASSWORD`, `IRC_NICKSERV_PASSWORD`, `IRC_NICKSERV_REGISTER_EMAIL`, `IRC_TLS`, `IRC_PORT`, `IRC_CHANNELS` | Broad IRC config access                                                          |
| `mattermost`       | `MATTERMOST_BOT_TOKEN`, `MATTERMOST_URL`, `OPENCLAW_GATEWAY_PORT`                                             | Token + gateway port                                                             |
| `acpx`             | `process.env` (full object) passed to child spawn via `omitEnvKeysCaseInsensitive`                            | Spawns child processes; strips known provider-auth vars but passes remaining env |
| `diagnostics-otel` | `OTEL_EXPORTER_OTLP_PROTOCOL`, `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_SERVICE_NAME`                             | Telemetry config only                                                            |
| `memory-lancedb`   | Dynamic lookup via `process.env[envVar]`                                                                      | May read arbitrary env keys                                                      |

> Extensions with access count ≥ 8 (`matrix` 20, `irc` 15, `telegram` 13, `voice-call` 12, `slack` 12)
> represent the highest surface area and should be prioritised in any isolation rollout.

---

## Risk Summary

| Risk                                        | Severity       | Affected extensions               |
| ------------------------------------------- | -------------- | --------------------------------- |
| Token/secret exfiltration via `process.env` | **High**       | All extensions listed above       |
| Full env pass-through to child processes    | **High**       | `acpx`                            |
| Dynamic env key lookup (arbitrary read)     | **Medium**     | `memory-lancedb`                  |
| Gateway port/URL exposure to extensions     | **Low-Medium** | `mattermost`, `discord`, `matrix` |

---

## Recommended Isolation Strategy (P3 Roadmap)

### Option A: `worker_threads` with scoped env

Run each extension in a `Worker` with a restricted `env` option:

```javascript
import { Worker } from "node:worker_threads";

new Worker("./extension-runner.js", {
  env: {
    // Only the variables the extension actually needs
    TELEGRAM_BOT_TOKEN: process.env.TELEGRAM_BOT_TOKEN,
    OPENCLAW_STATE_DIR: process.env.OPENCLAW_STATE_DIR,
    // Do NOT pass the full process.env
  },
  resourceLimits: {
    maxOldGenerationSizeMb: 256,
    maxYoungGenerationSizeMb: 64,
  },
});
```

**Pros:** Low overhead, built-in to Node.js, shared memory via `SharedArrayBuffer` if needed.  
**Cons:** Extensions that use native add-ons (`*.node` files) cannot run in workers.

### Option B: Separate process with explicit env allowlist

Fork a child process with only explicitly-permitted variables:

```javascript
import { fork } from "node:child_process";

const allowedEnv = resolveExtensionEnvAllowlist(extensionId); // returns {}
const child = fork("./extension-entry.js", [], {
  env: { ...allowedEnv, NODE_ENV: process.env.NODE_ENV },
});
```

**Pros:** Stronger isolation (separate address space), can set resource limits via `ulimit`/cgroups.  
**Cons:** Higher IPC overhead; extensions lose ability to share in-process caches.

### Option C: Explicit env allowlist declaration in extension manifest

Require each extension to declare which env vars it needs in its `package.json` or a
`extension.manifest.ts`:

```typescript
// extensions/telegram/extension.manifest.ts
export const envAllowlist = ["TELEGRAM_BOT_TOKEN", "OPENCLAW_STATE_DIR"] as const;
```

The gateway validates the manifest at load time and rejects extensions that access undeclared
vars at runtime (via a `Proxy` over `process.env`).

---

## Immediate Mitigations (No Refactoring Required)

These steps can be applied **today** without architectural changes:

1. **Audit enabled extensions in production** — review which extensions are active;
   disable any that are unused (`extensions` key in `openclaw.config.yaml`).

2. **Rotate secrets after disabling an extension** — if an extension that had access to
   secrets is disabled, rotate those credentials to limit the exposure window.

3. **Review extension code before enabling** — treat extension PRs with the same scrutiny
   as changes to `src/`; they have equivalent privilege.

4. **Never set `OPENCLAW_TEST_FAST=1` or `OPENCLAW_TEST_MEMORY_UNSAFE_REINDEX=1`
   in production** — a module-level guard now throws at startup if these flags are detected
   in `NODE_ENV=production` (see `src/memory/manager-sync-ops.ts` and
   `src/cron/isolated-agent/run.ts`).

5. **Consider a read-only `process.env` proxy** (low effort) — wrap `process.env` in a
   `Proxy` that logs all reads, allowing you to build an accurate env-access audit log
   before committing to a full isolation architecture.
