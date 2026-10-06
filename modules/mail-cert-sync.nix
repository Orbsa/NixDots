{ config, lib, pkgs, ... }:

# Keeps poste.io's TLS certificate in step with the NPMplus proxy that owns it.
#
# The proxy (10.0.0.3) issues mail.orbsa.net's certificate via a Cloudflare DNS-01
# challenge — deliberately, because the firewall DNATs ports 80/443 to the proxy so
# poste (10.0.0.5) can never answer an HTTP-01 challenge itself. That is what broke
# poste's built-in renewal and let its certificate expire in August 2026.
# poste still terminates SMTP/IMAP/POP3/Sieve, which a reverse proxy cannot serve,
# so the renewed material has to be pushed to the mail host on every renewal.
# modules/mail-cert-sync.sh carries the detail; this module wires it to a timer.
let
  cfg = config.my.mailCertSync;

  script = pkgs.writeShellApplication {
    name = "mail-cert-sync";
    runtimeInputs = with pkgs; [
      openssh
      coreutils
      diffutils # cmp — the certificate/key match check
      gnutar # staging the material onto the mail host over ssh
      openssl
    ];
    # SC2029: expanding these paths on the client side is the intent — they are
    # paths the remote side already has, not values meant to be interpolated
    # remotely.
    excludeShellChecks = [ "SC2029" ];
    text = builtins.readFile ./mail-cert-sync.sh;
  };
in
{
  options.my.mailCertSync = {
    enable = lib.mkEnableOption "sync mail.orbsa.net's TLS certificate from NPMplus to poste.io on Unraid";

    certificateId = lib.mkOption {
      type = lib.types.int;
      default = 28;
      description = ''
        NPMplus certificate id. Its live lineage is
        /data/tls/certbot/live/npm-<id> inside the npmplus container on CT 200.
      '';
    };

    onCalendar = lib.mkOption {
      type = lib.types.str;
      default = "*-*-* 00/6:00:00";
      description = ''
        How often to check for a renewed certificate. The certificate is
        short-lived (~6 days, Let's Encrypt "shortlived" profile with ARI-driven
        renewal), so four checks a day keeps poste's copy fresh.
      '';
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "admin";
      description = "User whose ~/.ssh carries the `proxy` and `unraid` aliases.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.mail-cert-sync = {
      description = "Sync mail.orbsa.net's TLS certificate from the NPMplus proxy to poste.io";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      environment.CERT_ID = toString cfg.certificateId;
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = "users";
        ExecStart = "${script}/bin/mail-cert-sync";
      };
    };

    systemd.timers.mail-cert-sync = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.onCalendar;
        Persistent = true;
        RandomizedDelaySec = "15min";
      };
    };
  };
}
