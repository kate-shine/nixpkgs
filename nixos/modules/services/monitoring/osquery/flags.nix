{ cfg, lib, pkgs }:

with builtins;
with lib;
rec {
  # conf is the osquery configuration file used when the --config_plugin=filesystem.
  # filesystem is the osquery default value for the config_plugin flag.
  conf = pkgs.writeText "osquery.conf" (toJSON cfg.settings);

  # flagfile is the file containing osquery command line flags to be provided to the application using the special --flagfile option.
  flagfile = pkgs.writeText "osquery.flags"
    (concatStringsSep "\n"
      (mapAttrsToList (name: value: "--${name}=${value}")
        # Use the conf derivation if not otherwise specified.
        ({ config_path = conf; } // cfg.flags)));
}
