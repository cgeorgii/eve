{
  description = "Eve - An extensible event framework";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        haskellPackages = pkgs.haskellPackages;

        eve = haskellPackages.callCabal2nix "eve" ./. {};

      in {
        packages = {
          default = eve;
          eve = eve;
        };

        devShells.default = haskellPackages.shellFor {
          packages = p: [ eve ];
          buildInputs = with haskellPackages; [
            cabal-install
            ghcid
            haskell-language-server
          ];
          withHoogle = true;
        };
      }
    );
}
