# Mobile Actions Smoke Test — Setup

Purpose: verify that Custom GPT **Actions actually fire from the ChatGPT mobile app**
before we build the real Game Master GPT. There is an unresolved community report
(May 2026) that Actions silently stop being invoked on mobile clients while working
fine on desktop web. This test settles it in ~10 minutes.

## 1. Build the throwaway GPT (desktop web — GPTs can't be built on mobile)

1. Go to <https://chatgpt.com/gpts/editor> (logged in with your Plus account).
2. Switch to the **Configure** tab (skip the conversational Create flow).
3. Fill in:
   - **Name:** `NG Smoke Test`
   - **Description:** `Plumbing test - checks Actions fire on mobile`
   - **Instructions:** paste the full contents of `gpt-instructions.txt` (this folder).
4. Turn **off** all capabilities (web browsing, canvas, image gen, code interpreter) —
   we want the action to be the only tool available.
5. Under **Actions** → **Create new action**:
   - **Authentication:** None
   - **Schema:** paste the full contents of `openapi.yaml` (this folder).
   - It should list one available action: `readReadme` (GET). If the editor shows a
     schema error instead, stop and report the error text.
6. **Create** → share setting **"Only me"**.

## 2. Baseline test on desktop web

In the GPT's chat (still on desktop), send: `test`

- Expected: a popup asking to allow `raw.githubusercontent.com` (choose **Always allow**),
  then a reply starting with **ACTION OK** plus the README's first heading and a
  character count.
- If you get ACTION FAILED on desktop, the schema/GPT is misconfigured — mobile isn't
  the problem yet. Report back what it said.

## 3. The real test: mobile app

1. Open the **ChatGPT app** on your phone (update it in the app store first, so we're
   testing the current build).
2. Find `NG Smoke Test` under GPTs and open a **fresh chat**.
3. Send: `test`

## 4. Interpreting results

| Desktop | Mobile | Meaning |
|---|---|---|
| ACTION OK | ACTION OK | Green light — mobile Actions work; we build the full GM GPT. |
| ACTION OK | ACTION FAILED (or it talks around it without calling) | The May-2026 mobile regression is live for you — we discuss fallbacks before building. |
| ACTION FAILED | — | Setup issue, not a platform issue. Report the failure text. |

Also worth one extra probe on mobile if it fails in the app: try the same GPT in your
phone's **browser** at chatgpt.com — the regression report claimed mobile web was
affected too. Knowing app-vs-browser behaviour helps pick the fallback.

Report back the exact replies (a screenshot is fine) and we'll proceed.
