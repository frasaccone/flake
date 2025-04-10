{
  config,
  pkgs,
  inputs,
  ...
}:
let
  mainServer = ../main-server;

  rootDomain = import "${mainServer}/domain.nix";
  gitDomain = "git.${rootDomain}";

  scripts = import ./scripts.nix { inherit config pkgs inputs; };

  stagit = {
    destDir = "/var/tmp/stagit";
    reposDir = config.modules.git.directory;
  };
in
{
  imports = [
    ./disk-config.nix
  ];

  modules = {
    bind = {
      enable = true;
      domain = rootDomain;
      records = import "${mainServer}/dns.nix" rootDomain;
    };
    darkhttpd = {
      enable = true;
      preStart = {
        scripts =
          let
            stagitCreate = scripts.stagitCreate {
              inherit (stagit) destDir reposDir;
              httpBaseUrl = "https://${gitDomain}";
            };

            stagitCreateAndChown =
              let
                script = pkgs.writeShellScriptBin "stagit-create-and-chown" ''
                  ${stagitCreate}
                  ${pkgs.sbase}/bin/chown -R git:git ${stagit.destDir}
                '';
              in
              "${script}/bin/stagit-create-and-chown";
          in
          [
            stagitCreateAndChown
          ];
      };
      symlinks =
        {
          "index.html" = "/var/tmp/stagit/index.html";
          "favicon.png" = "/var/tmp/stagit/favicon.png";
          "logo.png" = "/var/tmp/stagit/logo.png";
          "style.css" = "/var/tmp/stagit/style.css";
        }
        // (
          config.modules.git.repositories
          |> builtins.attrNames
          |> builtins.map (name: {
            inherit name;
            value = "/var/tmp/stagit/${name}";
          })
          |> builtins.listToAttrs
        );
      acme = {
        enable = true;
        email = "admin@${rootDomain}";
        domain = gitDomain;
      };
      tls = {
        enable = true;
        pemFiles =
          let
            inherit (config.modules.darkhttpd.acme) directory;
          in
          [
            "${directory}/${gitDomain}/fullchain.pem"
            "${directory}/${gitDomain}/privkey.pem"
          ];
      };
    };
    git = {
      enable = true;
      repositories =
        {
          flake = {
            description = "Francesco Saccone's Nix flake.";
          };
          hermes = {
            description = "HTTP GET/HEAD-only web server for static content.";
          };
          password-store = {
            description = "Francesco Saccone's password store.";
          };
          site = {
            description = "Francesco Saccone's site content.";
          };
        }
        |> builtins.mapAttrs (
          name:
          { description }:
          {
            additionalFiles = {
              inherit description;
              owner = "Francesco Saccone";
              url = "git://${gitDomain}/${name}";
            };
            hooks.postReceive = scripts.stagitPostReceive {
              inherit (stagit) destDir reposDir;
              inherit name;
              httpBaseUrl = "https://${gitDomain}";
            };
          }
        );
      daemon = {
        enable = true;
      };
    };
    openssh.listen = {
      enable = true;
      port = 22;
      authorizedKeyFiles = rec {
        root = [
          "${mainServer}/ssh/francescosaccone.pub"
        ];
        git = root;
      };
    };
  };

  networking.domain = gitDomain;
}
