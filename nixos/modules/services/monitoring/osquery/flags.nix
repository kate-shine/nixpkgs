{ cfg, lib, pkgs }:

with builtins;
with lib;
rec {
  # conf is the osquery configuration file used when the --config_plugin=filesystem.
  # filesystem is the osquery default value for the config_plugin flag.
  conf =
    if usingFilesystemConfigPlugin then
      pkgs.writeText "osquery.conf"
        (toJSON cfg.settings)
    else null;

  # flagfile is the file containing osquery command line flags to be provided to the application using the special --flagfile option.
  flagfile = pkgs.writeText "osquery.flags"
    (concatStringsSep "\n"
      (mapAttrsToList (name: value: "--${name}=${value}")
        # Use the conf derivation if not otherwise specified.
        ({ config_path = conf; } // cfg.flags)));

  # runtimeValue determines the runtime value for an osquery flag from the configuration hierarchy including the filesystem configuration file.
  # This is only useful if --config_plugin=filesystem.
  runtimeValue = flag: default:
    cfg.config.options.${flag}
      or (runtimeValueIgnoringConf flag default);

  # runtimeValueIgnoringConf determines the runtime value for an osquery flag from the configuration hierarchy ignoring the filesystem configuration file.
  # Despite not using the filesystem configuration, this function is only valid for CLI only flags or if --config_plugin=filesystem.
  # It cannot see into other flag configuration from other config plugins which might override this value.
  runtimeValueIgnoringConf = flag: default:
    cfg.flags.${flag}
      or default;

  # usingFilesystemConfigPlugin is the predicate for the use of the --config_plugin=filesystem flag.
  usingFilesystemConfigPlugin = "filesystem" == runtimeValueIgnoringConf "config_plugin" "filesystem";
}
