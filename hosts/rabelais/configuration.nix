{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices.root = {
    device = "/dev/disk/by-uuid/e25bcceb-2477-4fec-817d-9824cb141b2f";
    preLVM = true;
  };

  boot.resumeDevice = "/dev/mapper/vg0-swap";

  boot.kernel.sysctl = {
    "vm.swapiness" = 10;
    "vm.vfs_cache_pressure" = 50;
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  networking.hostName = "rabelais";

  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "en_US.UTF-8";

  services.resolved = {
    enable = true;
    dnssec = "true";
  };

  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
    dns = "systemd-resolved";
  };

  networking.wireless.iwd.enable = true;

  networking.wireguard.interfaces.enclosure = {
    ips = [ "10.20.1.2/24" ];
    privateKeyFile = config.age.secrets.wireguard-private-key.path;

    peers = [
      {
        publicKey = "6cgstwCsLAJkIH/a0vmhqvCYHT/Y7Qrpfn+tGG+Bp1M=";
        endpoint = "49.13.151.170:51820";
        allowedIPs = [
          "10.10.1.0/24"
          "10.20.1.0/24"
        ];
        persistentKeepalive = 25;
      }
    ];
  };

  networking.nameservers = [ "10.10.1.1" ];
  networking.search = [ "enclosure.internal" ];

  networking.firewall = {
    enable = true;
    allowedUDPPorts = [ 51820 ];
    trustedInterfaces = [ "enclosure" ];
  };

  services.xserver.enable = true;

  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.desktopManager.gnome.sessionPath = [ pkgs.gnome3.mutter ];

  nixpkgs.overlays = [
    # GNOME 46: triple-buffering-v4-46
    (final: prev: {
      mutter = prev.mutter.overrideAttrs (old: {
        src = pkgs.fetchFromGitLab {
          domain = "gitlab.gnome.org";
          owner = "vanvugt";
          repo = "mutter";
          rev = "triple-buffering-v4-46";
          hash = "sha256-C2VfW3ThPEZ37YkX7ejlyumLnWa9oij333d5c4yfZxc=";
        };
      });
    })
  ];

  services.printing.enable = true;

  services.logind = {
    lidSwitch = "ignore";
    lidSwitchDocked = "ignore";
    lidSwitchExternalPower = "ignore";
    extraConfig = ''
      IdleAction=ignore
      HandlePowerKey=ignore
      HandleSuspendKey=ignore
    '';
  };

  # Audio configuration
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    openssl
    cacert
  ];

  services.openssh.enable = true;

  system.stateVersion = "24.05";
}
