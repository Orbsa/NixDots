{ pkgs }:
pkgs.runelite.overrideAttrs (old: {
  buildPhase = builtins.replaceStrings
    [ "-Dmaven.test.skip" ]
    [ "-Dmaven.test.skip -Drunelite.128=runelite_128.png -Drunelite.splash=runelite_splash.png -Drunelite.net=runelite.net" ]
    old.buildPhase;
})
