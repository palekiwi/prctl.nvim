{
  description = "prctl.nvim";

  inputs = {
    nixpkgs.url = "nixpkgs";
    fu.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, fu, ... }:
    with fu.lib;
    eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells = {
          default = pkgs.mkShell
            {
              name = "prctl";
              buildInputs =
                with pkgs; [
                  luajit
                  luajitPackages.busted
                  luajitPackages.nlua
                  luajitPackages.nui-nvim

                  vimPlugins.plenary-nvim
                  vimPlugins.telescope-nvim
                ];
            };
        };
      }
    );
}
