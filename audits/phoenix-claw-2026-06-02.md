# Continuity audit — phoenix-claw

*Read-only audit. Generated 2026-06-02. Findings against `rules.md` §6/§8/§10/§11/§16; does **not** rewrite canon — you decide what to act on.*

> **UPDATE 2026-06-02 — fixes applied.** #1 (`calendar.md` rewritten to fold-cruise/Mos Eisley), #2 (Theron `_index` line refreshed to S4), and #3 (Naia Tul + Klornakka added to the roster) are **done**. #4 (the banned “working-X” tic in the persistent files) left for normal edits — low-urgency. Engine root-cause fix landed in `rules.md` (§2/§6/§11).

**Verdict:** phoenix-claw's S4 `/save` was done well — `narrative.md`, `player/character.md`, `meta/main-thread.md`, and `current-scene.md` are all current and consistent (ship in fold-cruise ~30 min from Mos Eisley, Naia Tul to collect, Phantom Voice ping overdue). The *alive-only* line, the soft-death rule, and the 3rd-person-present voice are all tracked with real precision. **But `calendar.md` was missed in that rollup and is a full session stale**, and the `_index` roster has two gaps. None of the fiction contradicts itself — this is rollup hygiene.

---

## 🟠 Act on before next session

### 1. `meta/calendar.md` is a whole session behind — and actively wrong now
Calendar says: *location = "Phoenix Claw in hyperspace, vector Kel Sahr (Ord Mantell) → Bonadan… first day of transit just opened,"* notable-upcoming = *"Touchdown at Bonadan in 5-6 days; **Theron disembarks there**; Theron's blaster power-pack to be returned before drop,"* and a "Resolved this period" list of **S2/S3** items (Pyx retrieval, Aargau box, Risa's bracelet, intimate register pulled back).
- **That is the state at the *start* of S4** — before Vandros even happened.
- **Actual current state (`session-04.md`, `current-scene.md`, `narrative.md`):** S4 has fully played — Vandros/Henn's Field captivity & escape, Berran, Korro, the five-week Bonadan stretch — and the ship is now in **fold-cruise to Tatooine / Mos Eisley, ~30 minutes out, Naia Tul to pick up, Phantom Voice ping overdue.**
- **It also asserts things that are now false:** Theron did **not** disembark at Bonadan — he came back to the ramp and is **committed, exclusive, aboard in the second cabin**. The blaster-power-pack errand resolved inside S4 (it was in Berran's co-pilot bag).
- **Why it matters most:** `calendar.md` is a ★ boot-set file — the first thing a fresh chat reads to answer "where are we." Right now it would place the ship heading *backwards* to Bonadan with Theron about to leave. This is the single highest-value fix.
- **Fix:** rewrite to fold-cruise → Tatooine/Mos Eisley; Naia Tul contract live; Phantom Voice ping overdue-to-open; Theron aboard & committed; move the S2/S3 "resolved" items out (they're already in `narrative.md`).

### 2. `_index.md` — Theron's roster line is frozen at S3
His entry reads *"aboard… in transit Kel Sahr → Bonadan, ~4 days remaining… last seen S03 scene 1 (asleep on Scarlet's bunk)."* That predates **all of S4**: the bar-sitting rupture, the five-week Bonadan separation, the ramp-foot return with the shirt, the cockpit committal (mutual exclusivity + break-clause), and his move into the second cabin as asset-to-her-trade.
- Notable because every *other* S4 NPC in the index (Korro, Berran, Mirai, Vass, Renna…) **is** current — Theron, the most important one, is the one that wasn't refreshed.
- **Fix:** update to "aboard *Phoenix Claw*, fold-cruise to Tatooine; committed/exclusive (S4); second cabin; asset-to-her-trade; last seen S04 scene 8."

---

## 🟡 Worth a look

### 3. Naia Tul (and Klornakka) aren't on the roster
`main-thread.md`, `character.md`, and `session-04.md` all treat **Naia Tul** as the live, accepted contract and "the next test" of the line — she's effectively the inbound on-screen NPC for S5 — but `_index.md` has **no entry** for her, nor for the client junior-Hutt **Klornakka**.
- **Fix:** add a roster line — *Naia Tul | not yet met | Mos Eisley working-stalls | contract target (alive-only, answer-the-question clause) | Hutt client Klornakka.* Klornakka can be a one-liner (off-screen client).

### 4. The banned "working-X" tic has re-colonised the persistent files
`tone-and-rules.md` lists, as a **player-named prohibition that must persist across sessions**: *"No 'working' as adjective wallpaper — not working captain, working spacer, working pro, working class…"* But the saved bookkeeping is full of exactly this in narration/summary voice: `_index` *"Working-boss who did not draw,"* main-thread *"working hit/watch list,"* plus *working theory / working trade / working-class register / working district* across `_index` and the session files.
- **Why it matters:** §10/§2 — a fresh chat boots off these files and re-learns house style from them. A prohibition that's purged from live prose but left thick in the persistent canon will quietly re-seed itself. (In-character *dialogue* like Berran's "you are a working captain" is arguably fine; the issue is the narrator/summary voice.)
- **Fix (optional, low-urgency):** on the next rollup, swap the summary-voice instances for the specific word (captain, freighter-boss, spacer, etc.). Not worth a special pass; fold into normal edits.

---

## 🟢 Minor / acknowledged
- **Korro** and **Berran** are marked *"Deep file: pending"* in `_index` — not drift, just outstanding. Both are flagged long-arc; worth the deep files before either returns, since both left strong unresolved hooks (Korro carried off / "my plan is not my plan"; Berran "respected," will lift and disappear).

---

## ✅ Confirmed solid (spot-checks that passed)
- **S4 rollup is otherwise exemplary.** `current-scene.md` correctly cleared and points to the S5 open; `narrative.md`, `main-thread.md`, and `character.md` agree on the committal, the medical state (grade-2 concussion window, no-stims-3-weeks/no-head-blow-6-weeks), credits (~65k), and loadout.
- **The central spine is tracked with unusual rigour.** The *alive-only* line's three pressure-tests (salt-house S2 / bracelet S3 / Berran S4) and the framing of the Naia Tul job as "the first contract that is itself the threat to the line" are consistent across `main-thread.md` and `character.md`.
- **Soft-death rule honoured** — the Vandros captivity resolved as concussion/lost-time/betrayal, never death.
- **POV / mind-reading (§8):** standard-SW sensing rules stated and not violated; Scarlet's interiority kept private, tells-not-thoughts in the chronicle.
- **Phantom Voice ping** is consistently tracked as queued-and-now-overdue across calendar (the one true thing it still says), main-thread, and current-scene.
- One tiny loose end the files themselves flag: Berran's pistol — "given to Theron… returned to Scarlet's stash at some point — TBC" (`session-04.md` save-state). Self-noted; just don't lose it.

*— End phoenix-claw audit.*
