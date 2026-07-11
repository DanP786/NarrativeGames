# ChatGPT GM — Full Setup Guide

Recreates the Claude Project GM on mobile ChatGPT. Three parts: a GitHub token,
a Cloudflare Worker (the transport), and a Custom GPT (the GM). One-time setup,
~30 minutes. The smoke test (`smoke-test/SETUP.md`) should already have passed.

Architecture: **ChatGPT GPT → Actions → Cloudflare Worker → GitHub API → this repo.**
The Worker exists so the GPT never touches base64 and can write a whole turn's
files as one commit. Nothing depends on your PC being on.

---

## Part 1 — GitHub fine-grained PAT (~5 min)

1. GitHub → <https://github.com/settings/personal-access-tokens/new>
   (Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token).
2. **Token name:** `narrativegames-gm-worker`
3. **Expiration:** your call — 90 days is a sane default; put a renewal reminder somewhere.
4. **Repository access:** "Only select repositories" → `DanP786/NarrativeGames`.
5. **Repository permissions:** **Contents → Read and write.** (Metadata read-only gets added automatically.) Nothing else.
6. Generate, and **copy the token now** — GitHub shows it once. Park it somewhere safe until Part 2 step 6.

## Part 2 — Cloudflare Worker (~10 min, free tier, no local tools)

1. Sign up / log in at <https://dash.cloudflare.com> (free plan is fine — 100k requests/day, a session uses maybe 100).
2. Left sidebar → **Workers & Pages** → **Create** → **Create Worker** (the "Hello World" template).
3. Name it `narrativegames-gm` → **Deploy** (deploys the placeholder).
4. Click **Edit code**, delete the placeholder, paste the entire contents of `worker/worker.js` (this folder), then **Deploy** again.
5. Note your Worker URL — it looks like `https://narrativegames-gm.<your-subdomain>.workers.dev`.
6. Back on the Worker's page → **Settings** → **Variables and Secrets** → add two entries, both type **Secret**:
   - `GITHUB_TOKEN` = the PAT from Part 1.
   - `API_KEY` = a long random string. Generate one locally with:
     `node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"`
     Keep a copy — the GPT needs it in Part 4.

### Verify the Worker

**PowerShell (recommended):** from the repo root, run the bundled script with your
real Worker URL and API key:

```powershell
.\chatgpt\worker\verify.ps1 -Worker "https://narrativegames-gm.YOUR-SUBDOMAIN.workers.dev" -Key "your-api-key"
```

It runs all four checks below and prints OK per test. Note: test 1 SHOULD report
"rejected without key" — that is the pass result.

**Or manually via Git Bash** (bash syntax — will NOT work pasted into PowerShell), replace the URL and KEY:

```bash
WORKER="https://narrativegames-gm.YOUR-SUBDOMAIN.workers.dev"
KEY="your-api-key"

# 1. auth rejected without key (expect: {"error":"unauthorized"})
curl -s "$WORKER/list"

# 2. list campaigns (expect: JSON array of campaign dirs)
curl -s -H "X-API-Key: $KEY" "$WORKER/list?path=campaigns"

# 3. read a file (expect: markdown text)
curl -s -H "X-API-Key: $KEY" "$WORKER/read?path=rules.md" | head -5

# 4. write test — creates then deletes a scratch file (two commits)
curl -s -X POST -H "X-API-Key: $KEY" -H "Content-Type: application/json" \
  -d '{"message":"worker write test","files":[{"path":"chatgpt/write-test.txt","content":"hello from the worker"}]}' \
  "$WORKER/commit"
curl -s -X POST -H "X-API-Key: $KEY" -H "Content-Type: application/json" \
  -d '{"message":"worker write test cleanup","files":[],"deletes":["chatgpt/write-test.txt"]}' \
  "$WORKER/commit"
```

All four behaving = transport done. (Remember to `git pull` locally after write tests —
the Worker commits straight to GitHub main.)

## Part 3 — (already done) rules.md

`rules.md` §0 and §11 now name the ChatGPT transport alongside the Claude ones.
No action needed; listed here so the guide is complete.

## Part 4 — The GM Custom GPT (~10 min, desktop web)

Same flow as the smoke test, different payloads:

1. <https://chatgpt.com/gpts/editor> → **Configure** tab.
2. **Name:** `Narrative GM` (or whatever you'll enjoy tapping on).
3. **Description:** `GM for the NarrativeGames engine — campaigns live in the GitHub repo.`
4. **Instructions:** paste the ENGINE ENTRYPOINT section of `gpt-instructions.md`
   (everything from `## ENGINE ENTRYPOINT` to the end of the file).
5. **Capabilities:** all OFF (especially web browsing — reads must go through the actions).
6. **Actions → Create new action:**
   - **Authentication:** type **API Key** → Auth type **Custom** → Custom header name: `X-API-Key` → paste the `API_KEY` value from Part 2.
   - **Schema:** paste `openapi.yaml` (this folder), then **edit the `servers:` url line** to your real Worker URL from Part 2 step 5.
   - The actions table should show `listDir`, `readFile`, `commitFiles`.
   - Use the inline **Test** button on `listDir` — should return the repo root listing.
7. **Create** → **Only me**.

## Part 5 — End-to-end test

On desktop web first, then repeat the short version on your phone:

1. Fresh chat with the GPT → say `continue`.
   - Expect: it reads `rules.md`, lists ALL campaigns with premises, and asks which one.
   - First action call will prompt to allow your worker domain — **Always allow**.
2. Pick a campaign. Expect the §2 boot sequence (a burst of readFile calls) then a 3–5 sentence recap.
3. Play 1–2 routine turns. Expect at most a small per-turn commit (current-scene one-liner).
4. `/endscene`, then `/save`. Expect one `save:`-prefixed commit and a confirmation with commit id.
5. Check the repo on GitHub: commit messages should follow `<slug> S NN T NN: <beat>` / `<slug> S NN — save: <summary>`.
6. Phone: fresh chat, `continue`, one turn, `/save`. Same expectations, smaller test.

## Troubleshooting

- **401 unauthorized from actions:** header name must be exactly `X-API-Key` and the key must match the Worker secret.
- **GPT "can't reach" the action on mobile only:** the May-2026 mobile regression — re-run the smoke test and report.
- **502 "GitHub ... failed":** usually an expired/mis-scoped PAT. Regenerate with Contents read+write on this repo, update the `GITHUB_TOKEN` secret.
- **Model narrates but forgets to commit:** say "commit that" once; if it recurs, that's an instructions-tightening issue — flag it for a `gpt-instructions.md` revision.
- **Local clone out of date:** the GPT commits straight to GitHub. `git pull` before playing via Claude Code, and push local changes before playing via the GPT.
