import type { Host, Service } from "./types.ts";

/**
 * Discovery of web UIs across the homelab.
 *
 * Strategy (per the operator's instruction):
 *   1. SSH into `unraid` and `proxy`, list their Docker containers and the IP
 *      each container is bound to (Unraid uses macvlan, so every container has
 *      its own LAN IP).
 *   2. Assume each service's port from the container name (see CONTAINER_MAP).
 *   3. Add services hosted on this Nix box (Plex, Jellyfin, Tautulli, Pelican
 *      Panel/Wings, Portainer).
 *
 * Output: data/services.json (consumed by build.ts).
 */

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

/** IP of this Nix host. Auto-detected, overridable here. */
const LOCAL_IP = await detectLocalIp();

/** Public URL of the Pelican Panel (it force-redirects to HTTPS and is only
 *  reachable through the reverse proxy). */
const PELICAN_PANEL_URL = "https://game.orbsa.net";

/** SSH hosts to query for containers. */
const SSH_HOSTS: Array<{ key: string; label: string; ip: string }> = [
  { key: "unraid", label: "unraid", ip: "10.0.0.10" },
  { key: "proxy", label: "proxy", ip: "10.0.0.3" },
];

/**
 * Container name -> web UI. Only web-facing services are listed; agents,
 * databases, schedulers, etc. are skipped.
 */
const CONTAINER_MAP: Record<string, { name: string; port: number; https?: boolean }> = {
  sonarr: { name: "Sonarr", port: 8989 },
  sonarr4k: { name: "Sonarr (4K)", port: 8989 },
  radarr: { name: "Radarr", port: 7878 },
  radarr4k: { name: "Radarr (4K)", port: 7878 },
  readarr: { name: "Readarr", port: 8787 },
  jackett: { name: "Jackett", port: 9117 },
  jackett2: { name: "Jackett 2", port: 9117 },
  transmission: { name: "Transmission", port: 9091 },
  transmission1: { name: "Transmission 1", port: 9091 },
  transmission2: { name: "Transmission 2", port: 9091 },
  homeassistant: { name: "Home Assistant", port: 8123 },
  vaultwarden: { name: "Vaultwarden", port: 80 },
  immich: { name: "Immich", port: 8080 },
  metube: { name: "MeTube", port: 8081 },
  "binhex-official-metube": { name: "MeTube", port: 8081 },
  chaptarr: { name: "Chaptarr", port: 8789 },
  pasta: { name: "Pasta", port: 80 },
  "rreading-glasses": { name: "Rreading Glasses", port: 8788 },
  "pocket-id": { name: "Pocket ID", port: 1411 },
  copyparty: { name: "Copyparty", port: 3923 },
  poste: { name: "Poste.io", port: 443, https: true },
  beszel: { name: "Beszel", port: 8090 },
  nginx: { name: "Nginx", port: 80 },
  seerr: { name: "Seerr", port: 5055 },
  npmplus: { name: "NPMplus", port: 81 },
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

async function detectLocalIp(): Promise<string> {
  // Prefer the LAN interface address (10.0.0.0/23).
  const { stdout } =
    await Bun.$`hostname -I`.quiet().catch(() => ({ stdout: "" as unknown as Buffer }));
  const ips = String(stdout).trim().split(/\s+/);
  const lan = ips.find((ip) => ip.startsWith("10.0.0.") || ip.startsWith("10.0.1."));
  return lan ?? ips[0] ?? "127.0.0.1";
}

async function ssh(hostKey: string, command: string): Promise<string> {
  const proc = Bun.spawnSync(
    [
      "ssh",
      "-o", "BatchMode=yes",
      "-o", "ConnectTimeout=10",
      "-o", "StrictHostKeyChecking=accept-new",
      hostKey,
      command,
    ],
    { stdout: "pipe", stderr: "pipe" },
  );
  if (proc.exitCode !== 0) {
    throw new Error(`ssh ${hostKey} failed: ${String(proc.stderr).trim()}`);
  }
  return String(proc.stdout);
}

/** Fetch `name | image | network | ip` per container from a remote Docker host. */
async function remoteContainers(
  hostKey: string,
): Promise<Array<{ name: string; image: string; ip: string | null }>> {
  const script = `
    for c in $(docker ps --format '{{.Names}}'); do
      img=$(docker inspect -f '{{.Config.Image}}' "$c" 2>/dev/null)
      ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' "$c" 2>/dev/null | xargs | tr ' ' ',')
      printf '%s|%s|%s\\n' "$c" "$img" "$ip"
    done
  `;
  const out = await ssh(hostKey, script);
  return out
    .trim()
    .split("\n")
    .filter(Boolean)
    .map((line) => {
      const [name, image, ip] = line.split("|");
      // Only keep a routable LAN IP (drop docker-internal 172.x/10.42.x bridges).
      const ips = (ip ?? "").split(",").filter((i) => i && !i.startsWith("172.") && !i.startsWith("10.42"));
      return { name, image, ip: ips[0] ?? null };
    });
}

// ---------------------------------------------------------------------------
// Discovery
// ---------------------------------------------------------------------------

async function scanContainers(): Promise<{ hosts: Host[]; services: Service[] }> {
  const hosts: Host[] = [{ key: "plix", label: "plix", ip: LOCAL_IP }];
  const services: Service[] = [];

  for (const host of SSH_HOSTS) {
    let containers;
    try {
      containers = await remoteContainers(host.key);
    } catch (err) {
      console.warn(`⚠  skipping ${host.key}: ${(err as Error).message}`);
      continue;
    }
    hosts.push(host);

    for (const c of containers) {
      const key = c.name.toLowerCase();
      const mapping = CONTAINER_MAP[key];
      if (!mapping) continue; // not a web UI we know about (agent/db/scheduler/…)

      const ip = c.ip ?? host.ip;
      const scheme = mapping.https ? "https" : "http";
      services.push({
        name: mapping.name,
        url: `${scheme}://${ip}${mapping.port === 80 || mapping.port === 443 ? "" : `:${mapping.port}`}/`,
        host: host.key,
      });
    }
  }

  services.sort((a, b) => a.name.localeCompare(b.name));
  return { hosts, services };
}

async function scanLocal(hosts: Host[]): Promise<Service[]> {
  const services: Service[] = [];
  const candidates: Array<{ name: string; url: string }> = [
    { name: "Plex", url: `http://${LOCAL_IP}:32400/web` },
    { name: "Jellyfin", url: `http://${LOCAL_IP}:8096` },
    { name: "Tautulli", url: `http://${LOCAL_IP}:8181` },
    { name: "Portainer", url: `https://${LOCAL_IP}:9443` },
    { name: "Pelican Wings", url: `http://${LOCAL_IP}:8131` },
    { name: "Pelican Panel", url: PELICAN_PANEL_URL },
  ];

  for (const c of candidates) {
    // Confirm the UI is actually up before advertising it.
    const up = await isUp(c.url);
    if (up) services.push({ name: c.name, url: c.url, host: "plix" });
    else console.warn(`⚠  local service not reachable, skipping: ${c.name} (${c.url})`);
  }

  // Ensure the "plix" host group exists if anything was found.
  if (services.length > 0 && !hosts.some((h) => h.key === "plix")) {
    hosts.push({ key: "plix", label: "plix", ip: LOCAL_IP });
  }
  return services;
}

async function isUp(url: string): Promise<boolean> {
  const proc = Bun.spawnSync(
    ["curl", "-sS", "-m", "6", "-k", "-L", "-o", "/dev/null", "-w", "%{http_code}", url],
    { stdout: "pipe", stderr: "pipe" },
  );
  const code = String(proc.stdout).trim();
  // 000 = connection failed; treat 4xx/5xx-but-reachable (e.g. 401 login, 301) as up.
  return code.length === 3 && code !== "000" && !code.startsWith("5");
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  const { hosts, services: containerServices } = await scanContainers();
  const localServices = await scanLocal(hosts);
  const all = [...containerServices, ...localServices].sort((a, b) =>
    a.name.localeCompare(b.name),
  );

  const out = { generatedAt: new Date().toISOString(), hosts, services: all };
  await Bun.write("data/services.json", JSON.stringify(out, null, 2) + "\n");

  console.log(`✔ wrote data/services.json — ${all.length} services across ${hosts.length} hosts`);
}

await main();
