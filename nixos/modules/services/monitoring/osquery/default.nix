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
      type = types.attrsOf types.str;
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.osquery ];
    systemd.services.osqueryd = {
      after = [ "network.target" "syslog.service" ];
      description = "The osquery daemon";
      preStart =
        if flags.usingFilesystemConfigPlugin then ''
          mkdir -p ${escapeShellArg (flags.runtimeValue "logger_path" "/var/log/osquery") }

          mkdir -p $(dirname ${escapeShellArg (flags.runtimeValue "database_path" "/var/osquery/osquery.db")})
          mkdir -p $(dirname ${escapeShellArg (flags.runtimeValue "pidfile" "/var/osquery/osqueryd.pidfile")})
        '' else "";
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
