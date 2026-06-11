# Narrative Adventure Engine — Architecture

Three views of the engine: the **transports** (how the player reaches Claude), the **repo layout** (how the campaign's durable state is organised), and the **per-turn loop** (what happens each time the player takes an action).

The authoritative spec is [`rules.md`](rules.md); these diagrams are orientation, not contract.

---

## 1. System / transports

The engine ships as a `rules.md` spec at the repo root. Two transports load it via different entrypoint files but converge on the same file-based state in git.

```mermaid
flowchart TB
    Player(("Player"))

    subgraph Transports["Two transports — same engine"]
        direction LR
        MainApp["Claude main app<br/>(web / desktop / mobile)<br/>Claude Project + GitHub connector"]
        Code["Claude Code<br/>(local CLI on a clone)"]
    end

    subgraph Entrypoints["Entry-point files (loaded first)"]
        direction LR
        PI["project-instructions.md<br/>pasted into Project<br/>custom instructions"]
        CMD["CLAUDE.md<br/>at repo root"]
    end

    Engine["<b>rules.md</b><br/>shared engine spec<br/>§1 layout · §2 boot · §3 onboarding<br/>§4 per-turn loop · §6 compression<br/>§7 skills · §8 NPCs · §9 commands<br/>§10 canon · §11 save · §15 voice · §16 arc"]

    subgraph IO["State I/O"]
        direction LR
        GH["GitHub MCP connector<br/>read + write via API<br/><i>Claude commits per turn</i>"]
        FS["Local filesystem tools<br/>read + write to disk<br/><i>player runs git commit on /save</i>"]
    end

    Repo[("Git repo<br/>campaigns/&lt;slug&gt;/<br/>source of truth")]

    Player --> MainApp
    Player --> Code
    MainApp --> PI
    Code --> CMD
    PI --> Engine
    CMD --> Engine
    Engine --> GH
    Engine --> FS
    GH <--> Repo
    FS <--> Repo
```

**Key difference between transports:** who writes git history. On the main app Claude commits each turn via the GitHub API; in Claude Code the player commits manually on `/save`. Everything else — the rules, the file shapes, the loops — is identical.

---

## 2. Repo / campaign structure

The repo holds many self-contained campaigns under `campaigns/<slug>/`. Files marked **★** are part of the **boot set** (§2) — read at the start of every fresh chat. Everything else is loaded lazily as entities come on-screen.

```mermaid
flowchart TB
    subgraph RepoRoot["Repo root (shared across all campaigns)"]
        RULES["rules.md ★ — engine spec"]
        CMD["CLAUDE.md — Claude Code entrypoint"]
        PI["project-instructions.md — main-app entrypoint"]
        CAMPS["campaigns/"]
    end

    CAMPS --> Campaign

    subgraph Campaign["campaigns/&lt;slug&gt;/ — one self-contained campaign"]
        direction TB

        subgraph Meta["meta/"]
            SETUP["setup.md ★ — onboarding answers"]
            CAL["calendar.md ★ — in-world date"]
            MAIN["main-thread.md ★ — central question + status"]
            ACT["act-tracker.md ★ — only if structured (§16)"]
        end

        subgraph World["world/"]
            DESC["description.md — geography, cultures, magic/tech"]
            TAR["tone-and-rules.md ★ — tone, voice, prose style,<br/>death rule, mind-reading rule"]
            NARR["narrative.md ★ — long-arc summary"]
            LOCS["locations/<br/>_index.md ★ + &lt;slug&gt;.md (lazy)"]
            FACS["factions/<br/>_index.md + &lt;slug&gt;.md (lazy)"]
            ITEMS["items/<br/>_index.md + &lt;slug&gt;.md (lazy)"]
        end

        subgraph PlayerDir["player/"]
            CHAR["character.md ★"]
            SKILLS["skills.md ★ — tiered (§7)"]
            INV["inventory.md ★"]
            ACTS["actions.md — reputation-shaping deeds"]
            PERS["personality.md — perception by region/faction"]
        end

        subgraph NPCs["npcs/"]
            NIDX["_index.md ★ — one-line roster"]
            NDEEP["&lt;slug&gt;.md — deep files (lazy load on screen)"]
            NDEAD["deceased/&lt;slug&gt;.md — archived"]
        end

        subgraph Chronicle["chronicle/ — three temporal layers (§6)"]
            HOT["current-scene.md ★ — <b>HOT</b><br/>beat-by-beat; cleared at scene end"]
            RECENT["session-NN.md ★ (last 1–2) — <b>RECENT</b><br/>finalised at /save"]
            LONG["→ rolled up into world/narrative.md<br/><b>LONG-TERM</b>"]
        end

        RECENT -.-> LONG
        LONG -.-> NARR
    end
```

**The three temporal layers** map to compression discipline:

- **HOT** (`current-scene.md`) — verbose, ephemeral. Cleared on scene end.
- **RECENT** (`session-NN.md`) — built across a session, summarised on `/save`.
- **LONG-TERM** (`world/narrative.md`, `player/actions.md`) — the story-as-remembered-in-a-decade. Only major beats survive here.

---

## 3. Per-turn loop

The five-step cycle from §4. Significance (routine / charged / climactic) is the dial that controls how much Claude reads, how rich the prose gets, and how much state gets written. Routine is cheap; climactic loads and writes broadly.

```mermaid
flowchart TB
    Turn(["Player turn arrives"])

    A["<b>Step A — Assess significance</b><br/>routine · charged · climactic<br/>(plus current act if structured — §16.3)"]

    B{tier?}

    BR["<b>Routine reads</b><br/>none — use loaded context"]
    BC["<b>Charged reads</b><br/>on-screen NPC deep files<br/>current location's deep file<br/>any faction/item directly invoked"]
    BX["<b>Climactic reads</b><br/>everything Charged loads, plus<br/>narrative.md re-read, plus<br/>actions.md + personality.md, plus<br/>off-screen NPCs referenced by name"]

    C["<b>Step C — Respond</b><br/>routine: 1–3 sentences, functional<br/>charged: full prose, sensory detail<br/>climactic: lean in — pacing, silences<br/><i>only narrate NPCs who act/react/are addressed</i>"]

    NPC["<b>Per-NPC silent check</b> (§8)<br/>short-term goal? methods on the table?<br/>disposition meters toward PC?<br/>relational meters toward other NPCs present?"]

    D{tier?}

    DR["<b>Routine writes</b><br/>one-liner → current-scene.md"]
    DC["<b>Charged writes</b><br/>current-scene.md beat<br/>NPC deep files (meter shifts ±1–5)<br/>npcs/_index.md if public tag changed"]
    DX["<b>Climactic writes</b><br/>everything Charged writes, plus<br/>flagged note for next /save rollup<br/>actions.md if reputation-shaping<br/>narrative.md if long-arc moved<br/>meters may shift ±5–20"]

    E["<b>Step E — Skill ticks</b> (§7)<br/>successful non-trivial use → +1 tick<br/>climactic successes count double<br/>announce only on tier crossings"]

    Done(["Wait for next turn"])

    Turn --> A --> B
    B -- routine --> BR
    B -- charged --> BC
    B -- climactic --> BX
    BR --> C
    BC --> NPC --> C
    BX --> NPC
    C --> D
    D -- routine --> DR
    D -- charged --> DC
    D -- climactic --> DX
    DR --> E
    DC --> E
    DX --> E
    E --> Done
```

**Significance bias is set per scene** but a single turn can escalate (a sudden confession, betrayal, reveal). The player can force the tier with `/routine`, `/charged`, or `/climactic`. In structured campaigns the current act biases the default — Act 1 leans routine/charged, Act 2 defaults to charged, Act 3 biases climactic.

---

## See also

- [`rules.md`](rules.md) — the engine spec (read first)
- [`CLAUDE.md`](CLAUDE.md) — Claude Code session entrypoint
- `project-instructions.md` — main-app session entrypoint
