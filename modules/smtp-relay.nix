{ config, pkgs, lib, ... }:

# Mail service for vix.orbsa.net — two modes:
#
#   relay (default)
#     Outbound SMTP submission relay.
#     Clients connect on :587 (STARTTLS) with SASL PLAIN/LOGIN.
#     Postfix delivers to the internet. No inbound mail.
#
#   backup
#     Backup MX relay. Accepts mail on :25 for the configured domains,
#     queues it, and retries delivery to the primary MX. No local
#     delivery — all mail eventually flows to the primary. Outbound
#     submission on :587 still works.
#
# Toggle between modes by setting services.vix-mail.mode in configuration.nix.
#
# DNS / provider checklist:
#   - A record:  vix.orbsa.net  -> VPS public IP
#   - rDNS/PTR:  VPS public IP   -> vix.orbsa.net (set at your VPS provider)
#   - MX record: vix.orbsa.net with higher priority (e.g. 20) than primary
#   - SPF/DKIM/DMARC on sending domains
#
# Adding a relay user (run on the VPS after first deploy):
#   sudo install -m 0640 -o root -g dovecot2 /dev/null /etc/dovecot/users
#   printf '%s:%s\n' "$user" "$(doveadm pw -s ARGON2ID)" \
#     | sudo tee -a /etc/dovecot/users
#   sudo systemctl reload dovecot2

let
  mailFqdn = "vix.orbsa.net";
  cfg = config.services.vix-mail;
  backupMode = cfg.enable && cfg.mode == "backup";
in {
  options.services.vix-mail = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the Vix mail service";
    };
    mode = lib.mkOption {
      type = lib.types.enum [ "relay" "backup" ];
      default = "relay";
      description = ''
        Operating mode:
        - "relay":  outbound SMTP submission only
        - "backup": backup MX — queues inbound mail for primary
      '';
    };
    domains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "orbsa.net" "thyrsos.tv" "ericbell.dev" ];
      description = "Domains to accept inbound mail for (backup mode only)";
    };
  };

  config = lib.mkIf cfg.enable {
    # ─── TLS certificate (both modes) ───────────────────────────────────
    services.nginx.virtualHosts.${mailFqdn} = {
      enableACME = true;
      addSSL = true;
      locations."/" = { return = "404"; };
    };

    security.acme.certs.${mailFqdn} = {
      webroot = "/var/lib/acme/acme-challenge";
      reloadServices = [ "postfix" ];
    };
    users.users.postfix.extraGroups = [ "acme" "opendkim" ];
    users.users.cleanup = {
      isSystemUser = true;
      group = "cleanup";
      extraGroups = [ "opendkim" ];
    };
    users.groups.cleanup = {};

    # ─── Firewall ───────────────────────────────────────────────────────
    networking.firewall.allowedTCPPorts =
      [ 587 ] ++ lib.optionals backupMode [ 25 ];

    # ─── Postfix ────────────────────────────────────────────────────────
    services.postfix = {
      enable = true;
      enableSubmission = true;
      submissionOptions = {
        smtpd_tls_security_level = "encrypt";
        smtpd_sasl_auth_enable = "yes";
        smtpd_sasl_type = "dovecot";
        smtpd_sasl_path = "private/auth";
        smtpd_sasl_security_options = "noanonymous";
        smtpd_client_restrictions = "permit_sasl_authenticated,reject";
        smtpd_relay_restrictions = "permit_sasl_authenticated,reject";
        milter_macro_daemon_name = "ORIGINATING";
      };
      settings.main = lib.mkMerge [
        {
          myhostname = mailFqdn;
          myorigin = mailFqdn;
          mydestination = [ "localhost" ];
          smtpd_tls_chain_files = [
            "/var/lib/acme/${mailFqdn}/fullchain.pem"
            "/var/lib/acme/${mailFqdn}/key.pem"
          ];
          # IPv4 only — GandiCloud IPv6 lacks PTR/rDNS, Gmail rejects it
          inet_protocols = "ipv4";
          smtputf8_enable = "no";
          mynetworks = [ "127.0.0.0/8" ];
          smtp_tls_security_level = "may";
          smtpd_tls_security_level = "may";
          # OpenDKIM milter for outbound signing
          non_smtpd_milters = [ "unix:/run/opendkim/opendkim.sock" ];
          milter_default_action = "accept";
        }
        (lib.mkIf backupMode {
          # Backup MX: accept mail for these domains, queue, retry primary.
          # Postfix skips its own hostname when delivering to domains in
          # relay_domains, so it won't loop back to itself.
          relay_domains = cfg.domains;
          relay_recipient_maps = "static:OK";
        })
      ];
    };

    # ─── DKIM signing (all outbound) ─────────────────────────────────────
    # OpenDKIM configured manually — NixOS module forces -k/-s on cmdline
    systemd.services.opendkim = {
      description = "OpenDKIM signing daemon";
      after = [ "network.target" "agenix.service" ];
      before = [ "postfix.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "forking";
        ExecStart = "${pkgs.opendkim}/bin/opendkim -l -p local:/run/opendkim/opendkim.sock -x /etc/opendkim/opendkim.conf";
        User = "opendkim";
        Group = "opendkim";
        RuntimeDirectory = "opendkim";
        UMask = "0007";
      };
    };

    users.users.opendkim = {
      isSystemUser = true;
      group = "opendkim";
    };
    users.groups.opendkim = {};

    environment.etc."opendkim/opendkim.conf".text = ''
      Mode                  s
      Socket                local:/run/opendkim/opendkim.sock
      PidFile               /run/opendkim/opendkim.pid
      UserID                opendkim
      SigningTable          refile:/etc/opendkim/SigningTable
      KeyTable              refile:/etc/opendkim/KeyTable
      InternalHosts         refile:/etc/opendkim/TrustedHosts
    '';

    # Signing table: domain → selector
    environment.etc."opendkim/SigningTable".text = ''
      *@orbsa.net    s20190117248._domainkey.orbsa.net
      *@thyrsos.tv   s20231213516._domainkey.thyrsos.tv
      *@ericbell.dev s20231213814._domainkey.ericbell.dev
    '';

    # Key table: (domain, selector) → key file
    environment.etc."opendkim/KeyTable".text = ''
      s20190117248._domainkey.orbsa.net    orbsa.net:s20190117248:${config.age.secrets.dkim-s20190117248.path}
      s20231213516._domainkey.thyrsos.tv   thyrsos.tv:s20231213516:${config.age.secrets.dkim-s20231213516.path}
      s20231213814._domainkey.ericbell.dev ericbell.dev:s20231213814:${config.age.secrets.dkim-s20231213814.path}
    '';

    environment.etc."opendkim/TrustedHosts".text = "127.0.0.1\n92.243.16.128\n";

    # DKIM private keys — managed by agenix
    age.secrets.dkim-s20190117248 = {
      file = ../secrets/dkim-s20190117248.key;
      owner = "opendkim";
      group = "opendkim";
      mode = "0600";
    };
    age.secrets.dkim-s20231213814 = {
      file = ../secrets/dkim-s20231213814.key;
      owner = "opendkim";
      group = "opendkim";
      mode = "0600";
    };
    age.secrets.dkim-s20231213516 = {
      file = ../secrets/dkim-s20231213516.key;
      owner = "opendkim";
      group = "opendkim";
      mode = "0600";
    };

    # Transport map: deliver relay domains to primary MX via tailscale
    services.postfix.transport = lib.optionalString backupMode (
      lib.concatMapStrings (d: "${d}    smtp:[100.111.138.108]:25\n") cfg.domains
    );
    services.dovecot2 = {
      enable = true;
      package = pkgs.dovecot;
      enablePAM = false;
      # These are required by the module assertion but configFile overrides them
      settings = {
        dovecot_config_version = pkgs.dovecot.version;
        dovecot_storage_version = pkgs.dovecot.version;
      };
      configFile = pkgs.writeText "dovecot.conf" ''
        dovecot_config_version = ${pkgs.dovecot.version}
        dovecot_storage_version = ${pkgs.dovecot.version}
        auth_mechanisms = plain login
        passdb passwd-file {
          passwd_file_path = /etc/dovecot/users
        }
        userdb static {
        }
        userdb_fields {
          uid = vmail
          gid = vmail
          home = /var/empty
        }
        service auth {
          unix_listener /var/lib/postfix/queue/private/auth {
            mode = 0660
            user = postfix
            group = postfix
          }
        }
      '';
    };

    systemd.services.dovecot = {
      after = [ "postfix.service" ];
      wants = [ "postfix.service" ];
    };

    # ─── vmail user (uid/gid for Dovecot SASL userdb) ───────────────────
    users.users.vmail = {
      isSystemUser = true;
      group = "vmail";
      home = "/var/empty";
      createHome = false;
    };
    users.groups.vmail = {};
  };
}
