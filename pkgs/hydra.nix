{
  appimageTools,
  fetchurl,
  lib,
  makeWrapper,
  coreutils,
  util-linux,
  ...
}:

let
  pname = "hydra";
  version = "4.3.0";

  src = fetchurl {
    url = "https://github.com/hydralauncher/hydra/releases/download/v${version}/hydralauncher-${version}.AppImage";
    sha256 = "sha256-rcOt0+Wh5J4FeZVh459fXZmNM5Lx0pJ9AnvPcSpHZFE=";
  };

in
appimageTools.wrapType2 {
  inherit pname version src;
  extraPkgs =
    pkgs: with pkgs; [
      libsecret
      libnotify
      vulkan-loader
      libGL
      glib
      libX11
      libXcursor
      libXrandr
      libXi
      alsa-lib
      udev
      pkgsi686Linux.libGL
      pkgsi686Linux.vulkan-loader
      pkgsi686Linux.mesa
    ];

  # Упадёт Hydra под driftwm с «Fatal Wayland communication error» (его баг со
  # всплывающими окнами) — обход: --ozone-platform=x11 в обёртку ниже. Под
  # остальными сессиями флаг только вредит: размытый текст и лишний слой.
  extraInstallCommands = ''
    mv $out/bin/${pname} $out/bin/.${pname}-unwrapped
    cat > $out/bin/${pname} <<EOF
    #!/bin/sh
    exec ${util-linux}/bin/chrt --other 0 \
         ${coreutils}/bin/nice -n 5 \
         ${util-linux}/bin/ionice -c 2 -n 7 \
         $out/bin/.${pname}-unwrapped \
         --disable-features=UseRealtimeAudio "\$@"
    EOF
    chmod +x $out/bin/${pname}
  '';

  meta = with lib; {
    description = "Hydra Launcher";
    homepage = "https://hydralauncher.com";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
}
