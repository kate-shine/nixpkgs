{ config, lib, pkgs, ... }:

with builtins;
with lib;

let
  cfg = config.services.osquery;
  runtimeValue = flag: default:
    cfg.config.options.${flag}
      or cfg.flags.${flag}
      or default;
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

    flagfile = mkOption {
      default = "/etc/osquery/osquery.flags";
      description = mdDoc ''
        Path to the flagfile used to provide CLI flags to osqueryd.
        For more information, refer to https://osquery.readthedocs.io/en/stable/installation/cli-flags/#flagfile.
      '';
      type = types.path;
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
      type = types.attrsOf types.str;
    };
  };

  config = mkIf cfg.enable {
    environment.etc = {
      "osquery/osquery.conf".text = toJSON cfg.config;
      "osquery/osquery.flags".text = concatStringsSep "\n" (mapAttrsToList (name: value: "--${name}=${value}") cfg.flags);
    };
    environment.systemPackages = [ pkgs.osquery ];
    systemd.services.osqueryd = {
      after = [ "network.target" "syslog.service" ];
      description = "The osquery daemon";
      preStart = ''
        mkdir -p $(dirname ${escapeShellArg cfg.flagfile})

        mkdir -p ${escapeShellArg (runtimeValue "logger_path" "/var/log/osquery") }

        mkdir -p $(dirname ${escapeShellArg (runtimeValue "database_path" "/var/osquery/osquery.db")})
        mkdir -p $(dirname ${escapeShellArg (runtimeValue "pidfile" "/var/osquery/osqueryd.pidfile")})
      '';
      serviceConfig = {
        ExecStart = "${pkgs.osquery}/bin/osqueryd --flagfile ${escapeShellArg cfg.flagfile}";
        KillMode = "process";
        KillSignal = "SIGTERM";
        Restart = "on-failure";
        TimeoutStartSec = "infinity";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
