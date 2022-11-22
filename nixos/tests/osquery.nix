import ./make-test-python.nix ({ lib, pkgs, ... }:

with lib;

{
  name = "osquery";
  meta = with maintainers; {
    maintainers = [ jdbaldry znewman01 ];
  };

  nodes.machine = { config, pkgs, ... }: {
    services.osquery = {
      enable = true;

      config.options = {
        nullvalue = "NULL";
        utc = false;
      };
      flags = {
        config_refresh = "10";
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

      # osqueryd was able to query information about the host.
      machine.succeed("echo 'SELECT address FROM etc_hosts LIMIT 1;' | osqueryi --flagfile ${flags.flagfile} | tee /dev/console | grep -q '127.0.0.1'")

      # osquery binaries respect configuration from the Nix config option.
      machine.succeed("echo 'SELECT value FROM osquery_flags WHERE name = \"utc\";' | osqueryi --flagfile ${flags.flagfile} | tee /dev/console | grep -q false")

      # osquery binaries respect configuration from the Nix flags option.
      machine.succeed("echo 'SELECT value FROM osquery_flags WHERE name = \"config_refresh\";' | osqueryi --flagfile ${flags.flagfile} | tee /dev/console | grep -q 10")

      # Demonstrate that osquery binaries prefer configuration file options over CLI flags.
      machine.succeed("echo 'SELECT value FROM osquery_flags WHERE name = \"nullvalue\";' | osqueryi --flagfile ${flags.flagfile} | tee /dev/console | grep -q NULL")
    '';
})
