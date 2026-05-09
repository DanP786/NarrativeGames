# NarrativeGames

A multi-campaign **Narrative Adventure Engine** — open-ended, multi-session story games where Claude is the narrator/GM and a git repo on GitHub is the durable world state.

## Architecture

- **`rules.md`** — the engine spec. Read by Claude at the start of every session.
- **`project-instructions.md`** — entrypoint for the **main Claude app** (web / desktop / mobile). Paste its contents into a Claude Project's Custom Instructions, connect this GitHub repo to the Project, and you're set.
- **`CLAUDE.md`** — entrypoint for **Claude Code** running on a local clone. Same engine, different transport.
- **`campaigns/<slug>/`** — one self-contained campaign per directory. Created lazily on new-campaign onboarding.

The repo lives on GitHub. Reads and writes from the main Claude app go through the GitHub connector / MCP — every file write becomes a commit. From Claude Code, reads and writes go through the local filesystem and the player commits manually.

## Setup (one-time)

1. **Push this repo to GitHub.** Create an empty repo (e.g. `Spectarium/NarrativeGames` or your own user), then:
   ```
   git remote add origin git@github.com:<owner>/<repo>.git
   git push -u origin main
   ```
2. **Enable the GitHub connector in Claude.** In the main Claude app, open Settings → Connectors → GitHub and authorise it for the repo (or organisation).
3. **Create a Claude Project.** Name it whatever you like (e.g. "Narrative Adventure"). Open the Project's Custom Instructions, and paste the contents of `project-instructions.md` (everything from the `## ENGINE ENTRYPOINT` heading down).
4. **Attach the repo to the Project.** Add the GitHub repo as a Project knowledge source / connector binding so Claude can read and write to it.

## How to play

From any device — web, desktop, or mobile — open the Project and say `continue`. Claude will read `rules.md`, list campaigns, and either resume one or run new-campaign onboarding.

At the end of a session, type `/save`. Claude does the session rollup and makes a summary commit on `main` (prefix `save:` so you can grep session boundaries from the git log).

## Local play (Claude Code)

If you want to play from a terminal on the machine that holds the local clone, just open Claude Code in this directory and say `continue`. `CLAUDE.md` handles the entrypoint. You commit manually.

## See also

`rules.md` for the full engine: skill tiers, NPC handling, compression discipline, command vocabulary, save protocol.
