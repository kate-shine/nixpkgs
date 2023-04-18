import ./make-test-python.nix ({ lib, pkgs, ... }:

with lib;

let
  config_refresh = "10";
  logger_path = "/var/other/log/path";
  nullvalue = "NULL";
  utc = false;
in
{
  name = "osquery";
  meta = with maintainers; {
    maintainers = [ jdbaldry znewman01 ];
  };

  nodes.machine = { config, pkgs, ... }: {
    services.osquery = {
      enable = true;

      config.options = { inherit nullvalue utc; };
      flags = {
        inherit config_refresh logger_path;
        nullvalue = "IGNORED";
      };
    };
  };

  testScript = { nodes, ... }:
    let
      cfg = nodes.machine.config.services.osquery;
      flags = import ../modules/services/monitoring/osquery/flags.nix { inherit cfg lib pkgs; };
    in
    ''
      machine.start()
      machine.wait_for_unit("osqueryd.service")

      # Stop the osqueryd service so that we can use osqueryi to check information stored in the database.
      machine.wait_until_succeeds("systemctl stop osqueryd.service")

      # osqueryd was able to query information about the host.
      machine.succeed("echo 'SELECT address FROM etc_hosts LIMIT 1;' | osqueryi --flagfile ${flags.flagfile} | tee /dev/console | grep -q '127.0.0.1'")

      # osquery binaries respect configuration from the Nix config option.
      machine.succeed("echo 'SELECT value FROM osquery_flags WHERE name = \"utc\";' | osqueryi --flagfile ${flags.flagfile} | tee /dev/console | grep -q ${boolToString utc}")

      # osquery binaries respect configuration from the Nix flags option.
      machine.succeed("echo 'SELECT value FROM osquery_flags WHERE name = \"config_refresh\";' | osqueryi --flagfile ${flags.flagfile} | tee /dev/console | grep -q ${config_refresh}")

      # Demonstrate that osquery binaries prefer configuration file options over CLI flags.
      machine.succeed("echo 'SELECT value FROM osquery_flags WHERE name = \"nullvalue\";' | osqueryi --flagfile ${flags.flagfile} | tee /dev/console | grep -q ${nullvalue}")

      # Module creates directories for default database_path and pidfile flag values.
      machine.succeed("test -d $(dirname ${cfg.flags.database_path})")
      machine.succeed("test -d $(dirname ${cfg.flags.pidfile})")

      # Module creates directories for alternative logger_path flag value.
      machine.succeed("test -d ${logger_path}")
    '';
})
