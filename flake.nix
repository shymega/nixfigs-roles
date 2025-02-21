# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk
#
# SPDX-License-Identifier: GPL-3.0-only
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  inputs.nixfigs-helpers.url = "github:shymega/nixfigs-helpers";

  outputs = {self, ...} @ inputs: let
    genPkgs = system: import inputs.nixpkgs {inherit system;};

    systems = [
      "x86_64-linux"
      "aarch64-linux"
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
      "rnet"
      "clockwork_tests"
      "container"
      "darwin_arm64"
      "darwin_x86"
      "embedded"
      "gaming"
      "gh-runner"
      "gpd_wm2"
      "minimal"
      "personal"
      "proxmox_lxc"
      "proxmox_vm"
      "raspberrypi_4"
      "raspberrypi_z2w"
      "raspberrypi_zw"
      "shynet"
      "steamdeck"
      "work"
      "workstation"
      "wsl"
    ];
    checkRole = role:
      builtins.elem role self.roles;
    checkRoles = roles: builtins.all (role: self.checkRole role) roles;
  };
}
