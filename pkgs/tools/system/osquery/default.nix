{ pkgs }:

with pkgs;
let
  buildStdenv = overrideCC stdenv llvmPackages.clangUseLLVM;
  opensslArchive =
    let
      # https://github.com/osquery/osquery/blob/master/libraries/cmake/formula/openssl/CMakeLists.txt#L3-L4
      version = "1.1.1q";
      sha256 = "d7939ce614029cdff0b6c20f0e2e5703158a489a72b2507b8bd51bf8c8fd10ca";
    in
    fetchurl {
      inherit sha256;
      url = "https://www.openssl.org/source/openssl-${version}.tar.gz";
    };
in
buildStdenv.mkDerivation rec {
  pname = "osquery";
  version = "5.5.1";

  src = fetchFromGitHub {
    owner = pname;
    repo = pname;
    rev = version;

    fetchSubmodules = true;
    sha256 = "sha256-Q6PQVnBjAjAlR725fyny+RhQFUNwxWGjLDuS5p9JKlU=";
  };

  patches = [
    ./0001-Remove-git-reset.patch
    ./0002-Use-locale.h-instead-of-removed-xlocale.h-header.patch
    ./0003-Remove-circular-definition-of-AUDIT_FILTER_EXCLUDE.patch
    ./0004-Remove-include-of-random-shuffle-header.patch
    ./0006-Add-include-of-condition_variable.patch
    ./0007-Add-include-of-iomanip.patch
    ./0008-Add-include-of-cstring.patch
    ./0010-Remove-sysctl_utils-and-system_controls.patch
  ];

  nativeBuildInputs = [
    # > Git (>= 2.14.0), CMake (>= 3.21.4), Python 3 are required to build.
    # > The rest of the dependencies are downloaded by CMake.
    # https://osquery.readthedocs.io/en/latest/development/building/
    cmake
    git
    python3

    # https://github.com/osquery/osquery/blob/master/libraries/cmake/formula/openssl/CMakeLists.txt#L94
    perl
  ];

  preConfigure = ''
    find libraries/cmake/source -name 'config.h' -exec sed -i '/#define HAVE_XLOCALE_H 1/d' {} \;
  '';


  cmakeFlags = [
    "-DOSQUERY_VERSION=${version}"
    "-DOSQUERY_OPENSSL_ARCHIVE_PATH=${opensslArchive}"
  ];

  meta = with lib; {
    description = "SQL powered operating system instrumentation, monitoring, and analytics";
    homepage = "https://osquery.io";
    license = licenses.bsd3;
    platforms = platforms.linux;
    maintainers = with maintainers; [ jdbaldry ];
  };
}
