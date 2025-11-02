{
  description = "website for c3a.de";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.default = pkgs.mkShell {
        buildInputs = [
          pkgs.nodejs_24
        ];
      };

      packages.default = pkgs.buildNpmPackage {
        name = "c3a-website";
        src = ./website;
        npmDepsHash = "sha256-Fke655KMahYphBSm/F0RdfiOwxiQimedU4eoNIGPpwo=";

        installPhase = ''
          runHook preInstall
          mkdir -p $out
          cp -r $src/dist/* $out/
          runHook postInstall
        '';
      };

      packages.image = let
        nginxConfig = pkgs.writeText "nginx.conf" ''

          daemon off;
          user nginx nginx;
          error_log /dev/stdout info;
          pid /dev/null;
          events {}
          
          http {
            access_log /dev/stdout;
            include ${pkgs.nginx}/conf/mime.types;
            server {
              listen 80;
              index index.html;
              root ${self.packages.${system}.default};
            }
          }
        '';
      in 
      pkgs.dockerTools.buildImage {
        name = "c3a-website";
        tag = "latest";

        extraCommands = ''
          mkdir -p var/log/nginx
          mkdir -p var/cache/nginx
        '';

        runAsRoot = ''
          #!${pkgs.stdenv.shell}
          ${pkgs.dockerTools.shadowSetup}
          groupadd --system nginx
          useradd --system --gid nginx nginx
        '';

        config = {
          cmd = [
            "${pkgs.nginx}/bin/nginx" "-c" nginxConfig
          ];
        };
      };
    }
  );
}
