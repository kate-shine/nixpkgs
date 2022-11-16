{ pkgs }:

with pkgs;
let
  buildStdenv =
    # Run Build Command(s):/nix/store/25nm17pd42qmyczrkh80ya2hh9jvgp0g-gnumake-4.3/bin/make -f Makefile cmTC_c9e5b/fast && /nix/store/25nm17pd42qmyczrkh80ya2hh9jvgp0g-gnumake-4.3/bin/make  -f CMakeFiles/cmTC_c9e5b.dir/build.make CMakeFiles/cmTC_c9e5b.dir/build
    # make[1]: Entering directory '/build/source/build/CMakeFiles/CMakeTmp'
    # Building C object CMakeFiles/cmTC_c9e5b.dir/testCCompiler.c.o
    # /nix/store/i276imkk9kkv73qs5p4xjipsd8rr6rby-ccache-links-wrapper-/bin/clang    -MD -MT CMakeFiles/cmTC_c9e5b.dir/testCCompiler.c.o -MF CMakeFiles/cmTC_c9e5b.dir/testCCompiler.c.o.d -o CMakeFiles/cmTC_c9e5b.dir/testCCompiler.c.o -c /build/source/build/CMakeFiles/CMakeTmp/testCCompiler.c
    # Linking C executable cmTC_c9e5b
    # /nix/store/981zhk10rbx38si8m01xfx5a2iqlincz-cmake-3.24.2/bin/cmake -E cmake_link_script CMakeFiles/cmTC_c9e5b.dir/link.txt --verbose=1
    # /nix/store/i276imkk9kkv73qs5p4xjipsd8rr6rby-ccache-links-wrapper-/bin/clang CMakeFiles/cmTC_c9e5b.dir/testCCompiler.c.o -o cmTC_c9e5b 
    # clang-11: error: no input files
    # overrideCC stdenv (ccacheWrapper.override {
    #   cc = clang;
    #   # sudo mkdir -m0770 -p /var/cache/ccache
    #   # sudo chown --reference=/nix/store /var/cache/ccache
    #   # nix.settings.extra-sandbox-paths = [ "/var/cache/ccache" ];
    #   # programs.ccache.enable = true;
    #   extraConfig = ''
    #     export CCACHE_COMPRESS=1
    #     export CCACHE_DIR=/var/cache/ccache
    #     export CCACHE_UMASK=007
    #   '';
    # });
    clangStdenv;
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
  # /nix/store/pmgnlnbygb95s4zc8sqhknz9sdz934pk-binutils-2.39/bin/ld: cannot find -lc++abi: No such file or directory
  # /nix/store/pmgnlnbygb95s4zc8sqhknz9sdz934pk-binutils-2.39/bin/ld: cannot find -lc++: No such file or directory
  # Unable to include <sys/sysctl.h> in osquery/tables/system/posix/sysctl_utils.h needed by osquery/tables/system/posix/system_controls.cpp
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
  ];

  nativeBuildInputs = [
    # > Git (>= 2.14.0), CMake (>= 3.21.4), Python 3 are required to build.
    # > The rest of the dependencies are downloaded by CMake.
    # https://osquery.readthedocs.io/en/latest/development/building/
    cmake
    git
    python3
    # https://github.com/osquery/osquery/blob/master/libraries/cmake/formula/openssl/CMakeLists.txt#L43
    libunwind
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
