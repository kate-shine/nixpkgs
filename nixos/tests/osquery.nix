import ./make-test-python.nix ({ pkgs, ... }:
let
  loggerPath = "/var/log/osquery/logs";
  pidfile = "/run/osqueryd.pid";
in
{
  name = "osquery";
  meta = with pkgs.lib.maintainers; {
    maintainers = [ jdbaldry ];
  };

  nodes.machine = { config, pkgs, ... }: {
    services.osquery = {
      inherit loggerPath pidfile;

      enable = true;
    };
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("osqueryd.service")

    machine.succeed("echo 'SELECT address FROM etc_hosts LIMIT 1;' | osqueryi | grep '127.0.0.1'")

    machine.succeed("echo 'SELECT value FROM osquery_flags WHERE name = \"logger_path\";' | osqueryi | grep ${loggerPath}")

    machine.succeed("echo 'SELECT value FROM osquery_flags WHERE name =\"pid_file\";' | osqueryi | grep ${pidfile}")
  '';
})
