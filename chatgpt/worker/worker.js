// Narrative Adventure Engine — GitHub transport worker for the ChatGPT GM GPT.
//
// Endpoints (all require header  X-API-Key: <API_KEY secret>):
//   GET  /list?path=<dir>       -> JSON [{name, path, type}] for a directory ("" = repo root)
//   GET  /read?path=<file>      -> raw file text (plain text, not base64)
//   GET  /campaigns             -> JSON [{slug, last_session, setup}] for every campaign (one call)
//   GET  /boot?campaign=<slug>  -> JSON {campaign, files:[{path, content}], missing:[path]} —
//                                  the full rules.md §2 boot set in one call
//   POST /commit                -> body {message, files:[{path, content}], deletes?:[path]}
//                                  writes all files as ONE commit on main; content is plain text
//
// Secrets (Worker Settings -> Variables and Secrets, both type "Secret"):
//   GITHUB_TOKEN — fine-grained PAT, this repo only, Contents: Read and write
//   API_KEY      — long random string, shared with the GPT action's auth setting

const REPO = "DanP786/NarrativeGames";
const BRANCH = "main";

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

function encodePath(p) {
  return p.split("/").filter(Boolean).map(encodeURIComponent).join("/");
}

function gh(env, endpoint, opts = {}) {
  return fetch(`https://api.github.com/repos/${REPO}/${endpoint}`, {
    method: opts.method || "GET",
    headers: {
      authorization: `Bearer ${env.GITHUB_TOKEN}`,
      accept: opts.accept || "application/vnd.github+json",
      "user-agent": "narrativegames-gm-worker",
      "x-github-api-version": "2022-11-28",
      ...(opts.body ? { "content-type": "application/json" } : {}),
    },
    body: opts.body ? JSON.stringify(opts.body) : undefined,
  });
}

async function ghFail(res, step) {
  const detail = (await res.text()).slice(0, 500);
  return json({ error: `GitHub ${step} failed`, status: res.status, detail }, 502);
}

async function handleList(env, url) {
  const path = url.searchParams.get("path") || "";
  const res = await gh(env, `contents/${encodePath(path)}?ref=${BRANCH}`);
  if (res.status === 404) return json({ error: `not found: ${path}` }, 404);
  if (!res.ok) return ghFail(res, "list");
  const items = await res.json();
  if (!Array.isArray(items)) {
    return json({ error: `${path} is a file, not a directory — use /read` }, 400);
  }
  return json(items.map((i) => ({ name: i.name, path: i.path, type: i.type })));
}

async function handleRead(env, url) {
  const path = url.searchParams.get("path");
  if (!path) return json({ error: "path query param required" }, 400);
  const res = await gh(env, `contents/${encodePath(path)}?ref=${BRANCH}`, {
    accept: "application/vnd.github.raw+json",
  });
  if (res.status === 404) return json({ error: `not found: ${path}` }, 404);
  if (!res.ok) return ghFail(res, "read");
  return new Response(await res.text(), {
    headers: { "content-type": "text/plain; charset=utf-8" },
  });
}

async function readRaw(env, path) {
  const res = await gh(env, `contents/${encodePath(path)}?ref=${BRANCH}`, {
    accept: "application/vnd.github.raw+json",
  });
  if (!res.ok) return null;
  return res.text();
}

async function listContents(env, path) {
  const res = await gh(env, `contents/${encodePath(path)}?ref=${BRANCH}`);
  if (!res.ok) return null;
  const items = await res.json();
  return Array.isArray(items) ? items : null;
}

// The rules.md §2 boot set (paths relative to the campaign root).
// Files that don't exist are reported in "missing", not errors.
const BOOT_FILES = [
  "meta/setup.md",
  "meta/calendar.md",
  "meta/main-thread.md",
  "meta/act-tracker.md",
  "world/tone-and-rules.md",
  "world/narrative.md",
  "npcs/_index.md",
  "world/locations/_index.md",
  "chronicle/current-scene.md",
  "player/character.md",
  "player/skills.md",
  "player/inventory.md",
];

async function handleCampaigns(env) {
  const dirs = await listContents(env, "campaigns");
  if (!dirs) return json({ error: "campaigns/ not found" }, 502);
  const campaigns = await Promise.all(
    dirs
      .filter((d) => d.type === "dir")
      .map(async (d) => {
        const [setup, chron] = await Promise.all([
          readRaw(env, `campaigns/${d.name}/meta/setup.md`),
          listContents(env, `campaigns/${d.name}/chronicle`),
        ]);
        const sessions = (chron || [])
          .map((f) => (f.name.match(/^session-(\d+)\.md$/) || [])[1])
          .filter(Boolean)
          .map(Number);
        return {
          slug: d.name,
          last_session: sessions.length ? Math.max(...sessions) : 0,
          setup: setup ? setup.slice(0, 1500) : null,
        };
      })
  );
  return json(campaigns);
}

async function handleBoot(env, url) {
  const slug = url.searchParams.get("campaign");
  if (!slug) return json({ error: "campaign query param required" }, 400);
  const root = `campaigns/${slug}`;
  const dir = await listContents(env, root);
  if (dir === null) return json({ error: `campaign not found: ${slug}` }, 404);

  const chron = await listContents(env, `${root}/chronicle`);
  const sessionFiles = (chron || [])
    .filter((f) => /^session-\d+\.md$/.test(f.name))
    .sort((a, b) => a.name.localeCompare(b.name))
    .slice(-2)
    .map((f) => `chronicle/${f.name}`);

  const files = [];
  const missing = [];
  await Promise.all(
    [...BOOT_FILES, ...sessionFiles].map(async (p) => {
      const content = await readRaw(env, `${root}/${p}`);
      if (content === null) missing.push(p);
      else files.push({ path: `${root}/${p}`, content });
    })
  );
  return json({ campaign: slug, files, missing });
}

async function handleCommit(env, request) {
  const body = await request.json().catch(() => null);
  const files = body && Array.isArray(body.files) ? body.files : [];
  const deletes = body && Array.isArray(body.deletes) ? body.deletes : [];
  if (!body || typeof body.message !== "string" || !body.message.trim()) {
    return json({ error: "message (string) is required" }, 400);
  }
  if (files.length === 0 && deletes.length === 0) {
    return json({ error: "files (array of {path, content}) or deletes (array of paths) required" }, 400);
  }
  for (const f of files) {
    if (!f || typeof f.path !== "string" || typeof f.content !== "string") {
      return json({ error: "each files entry must be {path: string, content: string} — content is plain text" }, 400);
    }
  }

  const refRes = await gh(env, `git/ref/heads/${BRANCH}`);
  if (!refRes.ok) return ghFail(refRes, "get ref");
  const headSha = (await refRes.json()).object.sha;

  const headRes = await gh(env, `git/commits/${headSha}`);
  if (!headRes.ok) return ghFail(headRes, "get head commit");
  const baseTree = (await headRes.json()).tree.sha;

  const tree = [
    ...files.map((f) => ({ path: f.path, mode: "100644", type: "blob", content: f.content })),
    ...deletes.map((p) => ({ path: p, mode: "100644", type: "blob", sha: null })),
  ];
  const treeRes = await gh(env, "git/trees", {
    method: "POST",
    body: { base_tree: baseTree, tree },
  });
  if (!treeRes.ok) return ghFail(treeRes, "create tree");
  const newTree = (await treeRes.json()).sha;

  const commitRes = await gh(env, "git/commits", {
    method: "POST",
    body: { message: body.message, tree: newTree, parents: [headSha] },
  });
  if (!commitRes.ok) return ghFail(commitRes, "create commit");
  const newSha = (await commitRes.json()).sha;

  const updateRes = await gh(env, `git/refs/heads/${BRANCH}`, {
    method: "PATCH",
    body: { sha: newSha },
  });
  if (!updateRes.ok) return ghFail(updateRes, "update ref");

  return json({
    ok: true,
    commit: newSha.slice(0, 10),
    message: body.message,
    written: files.map((f) => f.path),
    deleted: deletes,
  });
}

export default {
  async fetch(request, env) {
    if (!env.API_KEY || request.headers.get("x-api-key") !== env.API_KEY) {
      return json({ error: "unauthorized" }, 401);
    }
    const url = new URL(request.url);
    // Tolerate sloppy clients: collapse duplicate slashes and trailing slash
    const route = url.pathname.replace(/\/+/g, "/").replace(/\/$/, "") || "/";
    try {
      if (request.method === "GET" && route === "/list") return handleList(env, url);
      if (request.method === "GET" && route === "/read") return handleRead(env, url);
      if (request.method === "GET" && route === "/campaigns") return handleCampaigns(env);
      if (request.method === "GET" && route === "/boot") return handleBoot(env, url);
      if (request.method === "POST" && route === "/commit") return handleCommit(env, request);
      return json({ error: `no route: ${request.method} ${route}` }, 404);
    } catch (e) {
      return json({ error: String(e) }, 500);
    }
  },
};
