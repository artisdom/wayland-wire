{ cabal, cabalInstall, filterSource, hxt, networkMsg, utf8String, QuickCheck, mtl, free, dietSet }:

cabal.mkDerivation
( self:
  { pname = "wayland-pure"
  ; version = "0.1.0"
  ; src = filterSource ./.
  ; buildTools = [ cabalInstall ]
  ; buildDepends = [ hxt networkMsg utf8String mtl free dietSet ]
  ; testDepends = [ QuickCheck ]
  ; doCheck = true
  ; enableSplitObjs = false
  ;
  }
)
