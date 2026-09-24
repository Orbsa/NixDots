export interface Service {
  /** Human-readable program name, e.g. "Sonarr" */
  name: string;
  /** Full URL to the web UI, e.g. "http://10.0.0.103:8989/" */
  url: string;
  /** Group label the service is grouped under, e.g. "unraid" */
  host: string;
}

export interface Host {
  /** Key used by services to reference this host */
  key: string;
  /** Human-readable display label for the group */
  label: string;
  /** IP address of the host (optional, informational) */
  ip?: string;
}
