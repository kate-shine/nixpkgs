{ config, lib, pkgs, ... }:

with builtins;
with lib;
let
  cfg = config.services.osquery;
  flags = import ./flags.nix { inherit cfg lib pkgs; };
in
{
  options.services.osquery = {
    enable = mkEnableOption (mdDoc "osqueryd daemon");

    config = mkOption {
      default = { };
      description = mdDoc ''
        Configuration to be written to the osqueryd JSON configuration file.
        To understand the configuration format, refer to https://osquery.readthedocs.io/en/stable/deployment/configuration/#configuration-components.
      '';
      example = {
        options.utc = false;
      };
      type = types.attrs;
    };

    flags = mkOption {
      default = { };
      description = mdDoc ''
        Attribute set of flag names and values to be written to the osqueryd flagfile.
        For more information, refer to https://osquery.readthedocs.io/en/stable/installation/cli-flags.
      '';
      example = {
        config_refresh = "10";
      };
      type = with types; submodule {
        freeformType = attrsOf str;
        options = {
          database_path = mkOption {
            default = "/var/osquery/osquery.db";
            description = mdDoc "Path used for the database file.";
            type = path;
          };
          logger_path = mkOption {
            default = "/var/log/osquery";
            description = mdDoc "Base directory used for logging.";
            type = path;
          };
          pidfile = mkOption {
            default = "/var/osquery/osqueryd.pidfile";
            description = "Path used for pidfile.";
            type = path;
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.osquery ];
    systemd.services.osqueryd = {
      after = [ "network.target" "syslog.service" ];
      description = "The osquery daemon";
      preStart = ''
        mkdir -p ${escapeShellArg cfg.flags.logger_path}

        mkdir -p $(dirname ${escapeShellArg cfg.flags.database_path})
        mkdir -p $(dirname ${escapeShellArg cfg.flags.pidfile})
      '';
      serviceConfig = {
        ExecStart = "${pkgs.osquery}/bin/osqueryd --flagfile ${flags.flagfile}";
        KillMode = "process";
        KillSignal = "SIGTERM";
        Restart = "on-failure";
        TimeoutStartSec = "infinity";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
