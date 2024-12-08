{
  description = "NixOS configuration for enclosure infrastructure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nix-utils = {
      url = "git+https://codeberg.org/noctologue/nix-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      agenix,
      nix-utils,
      nixos-hardware,
    }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      inherit (nix-utils.mkLib { inherit nixpkgs systems; }) forAllSystems;
    in
    {
      nixosConfigurations.rabelais = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/rabelais/configuration.nix
          nixos-hardware.nixosModules.lenovo-thinkpad-t480
          agenix.nixosModules.default
          {
            users.users.pml = {
              isNormalUser = true;
              extraGroups = [
                "wheel"
                "networkmanager"
              ];

              openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG6VU5bCvCJZRRhaxXQQHVD3FwW/GYcRAxmTxyIGBxRt pml@montaigne"
              ];
            };

            age.secrets.wireguard-private-key = {
              file = ./secrets/wireguard-private-rabelais.age;
              owner = "root";
              mode = "0600";
            };

            age.identityPaths = [ "/root/.age/system.key" ];
          }
        ];
      };

      formatter = forAllSystems ({ pkgs, ... }: pkgs.nixfmt-rfc-style);

      devShells = forAllSystems (
        { pkgs, ... }:
        {
          default = pkgs.mkShell {
            name = "machines";
            packages = with pkgs; [ rage ];
          };
        }
      );
    };
}
