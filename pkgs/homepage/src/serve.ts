/**
 * Tiny static file server for the built site (Bun.serve).
 * Usage: bun run serve   (or BUN_PORT=8080 bun run serve)
 */
import { join, resolve, sep } from "node:path";

const root = resolve(join(import.meta.dir, "..", "dist"));
const port = Number(process.env.BUN_PORT ?? 8787);

const server = Bun.serve({
  port,
  hostname: "0.0.0.0",
  async fetch(req) {
    const url = new URL(req.url);
    let path: string;
    try {
      path = decodeURIComponent(url.pathname);
    } catch {
      return new Response("400 — bad request", { status: 400 });
    }
    // Percent-decoding happens after WHATWG URL dot-segment normalisation, so
    // `%2e%2e%2f` survives as `../` and must be neutralised here. Reject NUL
    // bytes and anything that resolves outside the static root.
    if (path.includes("\0")) {
      return new Response("400 — bad request", { status: 400 });
    }
    if (path === "/" || path === "") path = "/index.html";

    const file = resolve(root, "." + path);
    if (file !== root && !file.startsWith(root + sep)) {
      return new Response("403 — forbidden", { status: 403 });
    }

    const f = Bun.file(file);
    if (await f.exists()) {
      return new Response(f, {
        headers: { "Content-Type": contentType(file) },
      });
    }
    return new Response("404 — not found", { status: 404 });
  },
});

console.log(`✔ serving dist/ at http://localhost:${server.port}`);

function contentType(path: string): string {
  if (path.endsWith(".html")) return "text/html; charset=utf-8";
  if (path.endsWith(".css")) return "text/css; charset=utf-8";
  if (path.endsWith(".js")) return "text/javascript; charset=utf-8";
  if (path.endsWith(".svg")) return "image/svg+xml";
  if (path.endsWith(".json")) return "application/json; charset=utf-8";
  return "application/octet-stream";
}
