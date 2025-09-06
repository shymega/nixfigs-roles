# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk
#
# SPDX-License-Identifier: GPL-3.0-only
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  inputs.nixfigs-helpers.url = "github:shymega/nixfigs-helpers";

  outputs = {self, ...} @ inputs: let
    genPkgs = system: import inputs.nixpkgs {inherit system;};

    systems = [
      "aarch64-darwin"
      "aarch64-linux"
      "armv6l-linux"
      "armv7l-linux"
      "i686-linux"
      "riscv64-linux"
      "x86_64-darwin"
      "x86_64-linux"
    ];

    treeFmtEachSystem = f: inputs.nixpkgs.lib.genAttrs systems (system: f inputs.nixpkgs.legacyPackages.${system});
    treeFmtEval = treeFmtEachSystem (
      pkgs:
        inputs.nixfigs-helpers.inputs.treefmt-nix.lib.evalModule pkgs "${
          inputs.nixfigs-helpers.helpers.formatter
        }"
    );

    forEachSystem = inputs.nixpkgs.lib.genAttrs systems;
  in {
    # for `nix fmt`
    formatter = treeFmtEachSystem (pkgs: treeFmtEval.${pkgs.system}.config.build.wrapper);
    # for `nix flake check`
    checks =
      treeFmtEachSystem (pkgs: {
        formatting = treeFmtEval.${pkgs}.config.build.wrapper;
      })
      // forEachSystem (system: {
        pre-commit-check = import "${inputs.nixfigs-helpers.helpers.checks}" {
          inherit self system;
          inherit (inputs.nixfigs-helpers) inputs;
          inherit (inputs.nixpkgs) lib;
        };
      });
    devShells = forEachSystem (
      system: let
        pkgs = genPkgs system;
      in
        import inputs.nixfigs-helpers.helpers.devShells {inherit pkgs self system;}
    );
    roles = [
      "clockworkpi-dev"
      "clockworkpi-prod"
      "container"
      "darwin"
      "darwin-arm64"
      "darwin-x86"
      "embedded"
      "gaming"
      "github-runner"
      "gitlab-runner"
      "gpd-duo"
      "gpd-wm2"
      "jovian"
      "minimal"
      "mobile-nixos"
      "nix-on-droid"
      "personal"
      "proxmox-lxc"
      "proxmox-vm"
      "raspberrypi-arm64"
      "raspberrypi-zero"
      "rnet"
      "shynet"
      "steam-deck"
      "work"
      "workstation"
      "wsl"
    ];
    utils = rec {
      inherit (self) roles;
      checkRole = role: (builtins.elem role roles);
      checkRoleIn = targetRole: hostRoles:
        (builtins.elem targetRole roles) && (builtins.elem targetRole hostRoles);
      checkRoles = targetRoles: hostRoles: (builtins.any checkRole targetRoles) && (builtins.any checkRole hostRoles);
      checkAllRoles = targetRoles: hostRoles: (builtins.all checkRole targetRoles) && (builtins.all checkRole hostRoles);
    };
  };
}
