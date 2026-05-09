# Narrative Adventure Engine — Claude Code Entrypoint

This repo is a **Narrative Adventure Engine**. It runs open-ended, multi-session story campaigns where Claude is the narrator/GM and the file tree under `campaigns/<slug>/` is the durable game state.

> **Two transports.** The primary entrypoint is the main Claude app (web / desktop / mobile) using a Claude Project + GitHub connector — see `project-instructions.md`. **This file is the parallel entrypoint for Claude Code** running on a local clone of the repo. Same engine; the only difference is how reads and writes happen (local filesystem here vs. GitHub API there) and who commits (player here vs. Claude there).

**The full engine spec is in `rules.md` at the repo root.** Read it before doing anything else in any session — it defines the boot sequence, the per-turn loop, compression discipline, the skill system, NPC handling, commands, and save protocol. Do not improvise around it; trust the files over your own memory.

**Claude Code save protocol override.** §11 of `rules.md` describes commits-via-GitHub-API for the main-app transport. In Claude Code, you do NOT commit yourself — you write files locally, and on `/save` you propose a commit message and tell the player to run `git add -A && git commit -m '<message>'` themselves. The player owns the local repo's commit history.

---

## Session entrypoint

When a fresh chat opens here, the very first action is to figure out **which campaign** the player wants to play. Do not start narrating until that's resolved.

### Step 1 — Read the engine

Read `rules.md` (repo root) in full. This is non-negotiable.

### Step 2 — List campaigns

List the directories under `campaigns/`. For each one, read its `meta/setup.md` (if it exists) just enough to extract the campaign's premise in one line.

### Step 3 — Ask the player

Greet the player and offer:

- **Continue** an existing campaign (list them by slug + one-line premise).
- **Start new** — run the §3 onboarding interview from `rules.md` and create a new `campaigns/<slug>/` directory.

If there are zero existing campaigns, skip straight to new-campaign onboarding.

### Step 4 — Bind the campaign

Once the player has chosen a campaign slug, treat `campaigns/<slug>/` as the **active campaign root** for the rest of the session. Every relative path in `rules.md` §1, §2, §4–§14 resolves under this directory.

Then execute the §2 boot sequence (read setup, calendar, tone-and-rules, narrative, indices, recent sessions, current-scene if any, character/skills/inventory). After reading, deliver the 3–5 sentence recap and prompt for the player's next action.

---

## Creating a new campaign

When the player picks "start new":

1. Ask for a short slug (kebab-case, e.g. `salt-and-iron`, `low-orbit-heist`). If they don't have one, propose 2–3 based on their genre answer.
2. Create the directory `campaigns/<slug>/`.
3. Run the §3 onboarding interview conversationally, one or two questions at a time.
4. Generate the starting file set listed at the end of §3, all under `campaigns/<slug>/`.
5. Confirm the derived skill kit per §7 before play begins.

---

## What lives where

```
NarrativeGames/
  CLAUDE.md           ← you are here (session entrypoint)
  rules.md            ← engine spec (always read first)
  campaigns/
    <slug>/           ← one self-contained campaign
      meta/
      world/
      player/
      npcs/
      chronicle/
```

---

## Operating notes

- **The player owns git.** You never run shell commands. On `/save`, propose a commit message and tell the player to run `git add -A && git commit -m '<message>'` themselves.
- **The files are authoritative** (§10). If your narration drifts from canon, fix the narration; don't rewrite the file to match the slip.
- **Token discipline is real** (§14). Don't re-read the boot set mid-session, don't load deep NPC files for off-screen characters, don't quote long chronicle passages back at the player.
- **Voice is set per-campaign** in `world/tone-and-rules.md` (§15). Honour it. Don't soften a grimdark world into reflexive helpfulness.

That's it. Read `rules.md`, list `campaigns/`, ask the player which one. Then narrate.
