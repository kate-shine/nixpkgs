{ config, lib, pkgs, ... }:

with builtins;
with lib;

let
  cfg = config.services.osquery;
in
{
  options.services.osquery = {
    enable = mkEnableOption "osquery";

    databasePath = mkOption {
      default = "/var/osquery/osquery.db";
      description = "Path used for the database file.";
      type = types.path;
    };
    loggerPath = mkOption {
      default = "/var/log/osquery";
      description = "Base directory used for filesystem logging.";
      type = types.path;
    };
    pidfile = mkOption {
      default = "/var/osquery/osqueryd.pidfile";
      description = "Path used for the pid file.";
      type = types.path;
    };
    utc = mkOption {
      default = true;
      description = "Attempt to convert all UNIX calendar times to UTC.";
      type = types.bool;
    };

    extraConfig = mkOption {
      default = { };
      description = "Extra configuration to be recursively merged into the JSON configuration file.";
      type = types.attrs // {
        merge = loc: foldl' (res: def: recursiveUpdate res def.value) { };
      };
    };
  };

  config = mkIf cfg.enable {
    environment.etc."osquery/osquery.conf".text = toJSON (
      recursiveUpdate
        {
          options = {
            config_plugin = "filesystem";
            database_path = cfg.databasePath;
            logger_plugin = "filesystem";
            logger_path = cfg.loggerPath;
            utc = cfg.utc;
          };
        }
        cfg.extraConfig
    );
    environment.systemPackages = [ pkgs.osquery ];
    systemd.services.osqueryd = {
      after = [ "network.target" "syslog.service" ];
      description = "The osquery daemon";
      path = [ pkgs.osquery ];
      preStart = ''
        mkdir -p ${escapeShellArg cfg.loggerPath}
        mkdir -p "$(dirname ${escapeShellArg cfg.pidfile})"
        mkdir -p "$(dirname ${escapeShellArg cfg.databasePath})"
      '';
      serviceConfig = {
        ExecStart = "${pkgs.osquery}/bin/osqueryd";
        KillMode = "process";
        KillSignal = "SIGTERM";
        Restart = "on-failure";
        TimeoutStartSec = "infinity";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
