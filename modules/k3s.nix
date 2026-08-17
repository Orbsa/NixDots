{ config, lib, pkgs, ... }:
let
  cfg = config.my.k3s;
in
{
  options.my.k3s = {
    enable = lib.mkEnableOption "k3s single-node Kubernetes cluster";
    enableGpu = lib.mkEnableOption "NVIDIA GPU device plugin for k3s containers";
    disableTraefik = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Disable built-in Traefik ingress (not needed for game servers)";
    };
    disableServicelb = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Disable built-in ServiceLB (set true if using MetalLB)";
    };
    extraFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra CLI flags passed to k3s server";
    };
    manifestsPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to directory of Kubernetes manifests auto-deployed by k3s";
    };
    dnsUpstream = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Upstream DNS server CoreDNS forwards to (e.g. a LAN resolver like 10.0.0.1).
        Patches the live coredns ConfigMap and k3s's on-disk coredns manifest so the
        change survives k3s restarts and manifest re-applies.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # ── k3s service ──────────────────────────────────────────────────
    services.k3s = {
      enable = true;
      role = "server";
      extraFlags = lib.concatStringsSep " " ([
        # Disable components that aren't useful for a gaming-server node
      ] ++ lib.optional cfg.disableTraefik "--disable traefik"
        ++ lib.optional cfg.disableServicelb "--disable servicelb"
        ++ cfg.extraFlags);
    };

    # ── Kubernetes tooling ───────────────────────────────────────────
    environment.systemPackages = with pkgs; [
      kubectl
      kubernetes-helm
    ];

    # ── Firewall: k3s internals + NodePort range for game servers ────
    # Use mkAfter so we append to the host's existing rules, not clobber.
    networking.firewall = {
      allowedTCPPorts = lib.mkAfter [ 6443 ];
      allowedUDPPorts = lib.mkAfter [ 8472 ];
      allowedTCPPortRanges = lib.mkAfter [ { from = 30000; to = 32767; } ];
      allowedUDPPortRanges = lib.mkAfter [ { from = 30000; to = 32767; } ];
    };

    # ── Impermanence: persist cluster state across reboots ───────────
    environment.persistence."/persist" = {
      directories = [
        "/var/lib/rancher/k3s"
      ];
    };

    # ── GPU device plugin (optional) ─────────────────────────────────
    # Allows pods to request nvidia.com/gpu resources.
    # Requires hardware.nvidia or services.xserver.videoDrivers = ["nvidia"] on the host.
    systemd.services.k3s-nvidia-device-plugin = lib.mkIf cfg.enableGpu {
      description = "NVIDIA device plugin for k3s";
      wantedBy = [ "multi-user.target" ];
      after = [ "k3s.service" ];
      requires = [ "k3s.service" ];

      path = with pkgs; [ k3s coreutils ];

      script = ''
        # Wait for k3s to write kubeconfig
        until [ -f /etc/rancher/k3s/k3s.yaml ]; do sleep 2; done
        export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

        # Deploy the NVIDIA device plugin daemonset
        kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.16.2/deployments/static/nvidia-device-plugin.yml
      '';

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };

    # ── CoreDNS upstream (optional) ─────────────────────────────────
    # Point CoreDNS at a specific resolver (e.g. VyOS 10.0.0.1, which is
    # authoritative for LAN zones like orbsa.net). Patches the live ConfigMap
    # AND k3s's on-disk coredns manifest so a k3s restart re-applies it.
    systemd.services.k3s-coredns-upstream = lib.mkIf (cfg.dnsUpstream != null) {
      description = "Point k3s CoreDNS at ${cfg.dnsUpstream}";
      wantedBy = [ "multi-user.target" ];
      after = [ "k3s.service" ];
      requires = [ "k3s.service" ];

      path = with pkgs; [ k3s coreutils gnused python3 ];

      script = ''
        # Wait for k3s to write kubeconfig
        until [ -f /etc/rancher/k3s/k3s.yaml ]; do sleep 2; done
        export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
        upstream="${cfg.dnsUpstream}"

        # 1. Persist the change in k3s's coredns manifest (hash-tracked by
        #    k3s), so every k3s start re-applies our forward target.
        manifest=/var/lib/rancher/k3s/server/manifests/coredns.yaml
        if [ -f "$manifest" ]; then
          sed -i "s|forward \. /etc/resolv\.conf|forward . $upstream|" "$manifest"
        fi

        # 2. Patch the live ConfigMap; restart coredns only if it changed.
        corefile=$(kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}')
        if ! printf '%s' "$corefile" | grep -q "forward . $upstream"; then
          new=$(printf '%s' "$corefile" \
            | sed "s|forward \. /etc/resolv\.conf|forward . $upstream|" \
            | python3 -c 'import json,sys; print(json.dumps([{"op":"replace","path":"/data/Corefile","value":sys.stdin.read()}]))')
          kubectl -n kube-system patch configmap coredns --type=json -p "$new"
          kubectl -n kube-system rollout restart deployment/coredns
          kubectl -n kube-system rollout status deployment/coredns --timeout=120s
        fi
      '';

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };

    # Ensure k3s data dir exists with correct ownership before k3s starts.
    systemd.tmpfiles.rules = [
      "d /var/lib/rancher/k3s 0755 root root - -"
    ];
  };
}
