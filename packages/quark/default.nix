{
  lib,
  stdenv,
  fetchgit,
}:
stdenv.mkDerivation {
  name = "quark";

  src = fetchgit {
    url = "git://git.suckless.org/quark";
    rev = "5ad0df91757fbc577ffceeca633725e962da345d";
    sha256 = "sha256-IQ1K70xAxdnt6fyguMnoA3L9THr20W8O0T38uDgVn0Q=";
  };

  makeFlags = [ "CC:=$(CC)" ];

  installFlags = [ "PREFIX=$(out)" ];

  meta = {
    description = ''
      Extremely small and simple HTTP GET/HEAD-only web server for static
      content.
    '';
    license = lib.licenses.isc;
    platforms = lib.platforms.unix;
  };
}
