import type { Host, Service } from "./types.ts";

/**
 * Static site generator. Reads data/services.json and emits a single
 * self-contained dist/index.html with inlined CSS — no JS, no build deps.
 */

interface Data {
  generatedAt?: string;
  hosts: Host[];
  services: Service[];
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function render(data: Data): string {
  const groups = new Map<string, Service[]>();
  for (const s of data.services) {
    const list = groups.get(s.host) ?? [];
    list.push(s);
    groups.set(s.host, list);
  }

  const hostById = new Map(data.hosts.map((h) => [h.key, h]));
  const ordered = [...groups.entries()].sort(([a], [b]) => a.localeCompare(b));

  const sections = ordered
    .map(([key, services]) => {
      const host = hostById.get(key);
      const ip = host?.ip ? ` <span class="ip">${escapeHtml(host.ip)}</span>` : "";
      const cards = [...services]
        .sort((a, b) => a.name.localeCompare(b.name))
        .map(
          (s) => `
        <a class="card" href="${escapeHtml(s.url)}" target="_blank" rel="noopener noreferrer">
          <span class="name">${escapeHtml(s.name)}</span>
          <span class="url">${escapeHtml(s.url)}</span>
        </a>`,
        )
        .join("");
      return `
      <section>
        <h2>${escapeHtml(host?.label ?? key)}${ip}</h2>
        <div class="grid">${cards}</div>
      </section>`;
    })
    .join("");

  const stamp = data.generatedAt ? `<p class="stamp">generated ${escapeHtml(data.generatedAt)}</p>` : "";

  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Homelab</title>
<style>
  :root {
    color-scheme: light dark;
    --bg: #fafafa;
    --fg: #17171a;
    --muted: #6b6b74;
    --card: #ffffff;
    --border: #e6e6ea;
    --accent: #2f6fed;
    --hover: #f2f5fc;
  }
  @media (prefers-color-scheme: dark) {
    :root {
      --bg: #101013;
      --fg: #e8e8ec;
      --muted: #8a8a94;
      --card: #1a1a1f;
      --border: #2a2a31;
      --accent: #6d9bff;
      --hover: #1e2430;
    }
  }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    padding: 48px 24px 80px;
    background: var(--bg);
    color: var(--fg);
    font: 15px/1.5 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    -webkit-font-smoothing: antialiased;
  }
  main { max-width: 1080px; margin: 0 auto; }
  header { margin-bottom: 40px; }
  h1 { font-size: 26px; font-weight: 650; margin: 0 0 4px; letter-spacing: -0.02em; }
  .subtitle { color: var(--muted); margin: 0; font-size: 14px; }
  section { margin-bottom: 36px; }
  h2 {
    font-size: 13px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.06em;
    color: var(--muted);
    margin: 0 0 14px;
  }
  .ip { color: var(--muted); opacity: 0.7; font-weight: 400; text-transform: none; letter-spacing: 0; }
  .grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
    gap: 10px;
  }
  .card {
    display: flex;
    flex-direction: column;
    gap: 3px;
    padding: 13px 15px;
    background: var(--card);
    border: 1px solid var(--border);
    border-radius: 10px;
    text-decoration: none;
    color: inherit;
    transition: border-color 120ms ease, background 120ms ease, transform 120ms ease;
  }
  .card:hover { border-color: var(--accent); background: var(--hover); transform: translateY(-1px); }
  .name { font-weight: 550; }
  .url { font: 12px/1.4 ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, monospace; color: var(--muted); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .stamp { color: var(--muted); font-size: 12px; margin-top: 48px; text-align: center; opacity: 0.7; }
</style>
</head>
<body>
<main>
  <header>
    <h1>Homelab</h1>
    <p class="subtitle">web interfaces across 10.0.0.0/24</p>
  </header>
  ${sections}
  ${stamp}
</main>
</body>
</html>`;
}

const data = JSON.parse(await Bun.file("data/services.json").text()) as Data;
await Bun.write("dist/index.html", render(data));
console.log(`✔ built dist/index.html — ${data.services.length} services`);
