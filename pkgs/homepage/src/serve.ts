/**
 * Tiny static file server for the built site (Bun.serve).
 * Usage: bun run serve   (or BUN_PORT=8080 bun run serve)
 */
import { join } from "node:path";

const root = join(import.meta.dir, "..", "dist");
const port = Number(process.env.BUN_PORT ?? 8787);

const server = Bun.serve({
  port,
  hostname: "0.0.0.0",
  async fetch(req) {
    const url = new URL(req.url);
    let path = decodeURIComponent(url.pathname);
    if (path === "/" || path === "") path = "/index.html";

    const file = Bun.file(join(root, path));
    if (await file.exists()) {
      return new Response(file, {
        headers: { "Content-Type": contentType(path) },
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
