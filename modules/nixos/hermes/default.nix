{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./acme
    ./tls
  ];

  options.modules.hermes = {
    enable = lib.mkOption {
      description = "Whether to enable Hermes.";
      default = false;
      type = lib.types.bool;
    };
    directory = lib.mkOption {
      description = "The root directory to statically host.";
      default = "/var/www";
      readOnly = true;
      type = lib.types.uniq lib.types.path;
    };
    symlinks = lib.mkOption {
      description = ''
        For each symlink name, which will be created in the root directory, its
        target.
      '';
      default = { };
      type = lib.types.attrsOf lib.types.path;
    };
    preStart = {
      scripts = lib.mkOption {
        description = ''
          The list of scripts to run before starting the server.
        '';
        default = [ ];
        type = lib.types.listOf lib.types.path;
      };
      packages = lib.mkOption {
        description = "The list of packages required by the scripts.";
        default = [ ];
        type = lib.types.listOf lib.types.package;
      };
    };
  };

  config = lib.mkIf config.modules.hermes.enable {
    users = {
      users = {
        hermes = {
          hashedPassword = "!";
          isSystemUser = true;
          group = "hermes";
          createHome = true;
          home = config.modules.hermes.directory;
        };
      };
      groups = {
        hermes = { };
      };
    };

    systemd = {
      services = {
        hermes-setup = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          serviceConfig =
            let
              permissions = pkgs.writeShellScriptBin "permissions" ''
                ${pkgs.sbase}/bin/chmod -R g+rwx \
                ${config.modules.hermes.directory}
              '';
              clean = pkgs.writeShellScriptBin "clean" ''
                ${pkgs.sbase}/bin/rm -rf \
                ${config.modules.hermes.directory}/*
              '';
              symlinks =
                config.modules.hermes.symlinks
                |> builtins.mapAttrs (
                  name: target:
                  let
                    inherit (config.modules.hermes) directory;
                  in
                  ''
                    ${pkgs.sbase}/bin/mkdir -p \
                    ${directory}/${builtins.dirOf name}

                    ${pkgs.sbase}/bin/ln -sf ${target} \
                    ${directory}/${name}

                    ${pkgs.sbase}/bin/chown -Rh hermes:hermes \
                    ${directory}/${name}
                  ''
                )
                |> builtins.attrValues
                |> builtins.concatStringsSep "\n"
                |> pkgs.writeShellScriptBin "symlinks";
            in
            {
              User = "root";
              Group = "root";
              Type = "oneshot";
              ExecStart = [
                "${permissions}/bin/permissions"
                "${clean}/bin/clean"
                "${symlinks}/bin/symlinks"
              ];
            };
        };
        hermes =
          let
            inherit (config.modules.hermes) preStart;
          in
          rec {
            enable = true;
            wantedBy = [ "multi-user.target" ];
            requires = [ "hermes-setup.service" ];
            after = [ "network.target" ];
            path = preStart.packages;
            serviceConfig =
              let
                inherit (config.modules.hermes) customHeaderScripts tls;
                script = pkgs.writeShellScriptBin "script" ''
                  ${builtins.concatStringsSep "\n" preStart.scripts}

                  ${pkgs.hermes}/bin/hermes \
                    -d ${config.modules.hermes.directory} \
                    -p 80 \
                    -i index.html \
                    -u hermes \
                    -g hermes
                '';
              in
              {
                User = "root";
                Group = "root";
                Restart = "on-failure";
                Type = "simple";
                ExecStart = "${script}/bin/script";
              };
          };
      };
      paths = {
        hermes = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          pathConfig = {
            PathModified = [
              config.modules.hermes.directory
            ] ++ builtins.attrValues config.modules.hermes.symlinks;
          };
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 ];
  };
}
