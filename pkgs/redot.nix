{
  stdenv,
  fetchzip,
  lib,
  autoPatchelfHook,
  makeWrapper,
  dotnetCorePackages,
  libGL,
  libX11,
  libXcursor,
  libXinerama,
  libXext,
  libXrandr,
  libXrender,
  libXi,
  libXfixes,
  libxkbcommon,
  alsa-lib,
  pulseaudio,
  dbus,
  fontconfig,
  freetype,
  udev,
  vulkan-loader,
  libdecor,
  wayland,
  speechd,
  ...
}:

let
  pname = "redot";

  # БЕЗ префикса "redot-": шаблон URL ниже добавляет его сам.
  # Пока здесь стояло "redot-26.3-stable", получался тег
  # redot-redot-26.3-stable и файл Redot_vredot-26.3-stable_... — оба
  # несуществующие, сборка падала на 404.
  # Тег релиза: redot-26.3-stable, архив: Redot_v26.3-stable_linux_mono_x64.zip
  version = "26.3-stable";

  # Сборка mono требует .NET 8 (tfm "net8.0" в GodotSharp/*/runtimeconfig.json).
  dotnet-sdk = dotnetCorePackages.sdk_8_0;

  src = fetchzip {
    url = "https://github.com/Redot-Engine/redot-engine/releases/download/redot-${version}/Redot_v${version}_linux_mono_x64.zip";
    sha256 = "sha256-jQF9b4itHdoCZkfGv6YR12d6z+VOL4pyTSNMtq1T+UI=";
    stripRoot = false;
  };

  # Движок подгружает их через dlopen уже при запуске.
  runtimeLibs = [
    libGL
    vulkan-loader
    libX11
    libXcursor
    libXinerama
    libXext
    libXrandr
    libXrender
    libXi
    libXfixes
    libxkbcommon
    alsa-lib
    pulseaudio
    dbus
    dbus.lib
    fontconfig
    fontconfig.lib
    freetype
    udev
    libdecor
    wayland
    speechd
  ];

in
stdenv.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = runtimeLibs;
  runtimeDependencies = runtimeLibs;

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mkdir -p $out/share/applications

    local binary=$(find . -maxdepth 1 -type f -name "*.x86_64*" | head -1)

    if [ -z "$binary" ]; then
      echo "ERROR: Cannot find binary!"
      ls -la
      exit 1
    fi

    cp "$binary" $out/bin/.redot-unwrapped
    chmod +x $out/bin/.redot-unwrapped

    if [ -d "GodotSharp" ]; then
      cp -r GodotSharp $out/bin/
    fi

    makeWrapper $out/bin/.redot-unwrapped $out/bin/redot \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}" \
      --prefix PATH : "${dotnet-sdk}/bin" \
      --set DOTNET_ROOT "${dotnet-sdk}"

    cat > $out/share/applications/redot.desktop << EOF
    [Desktop Entry]
    Name=Redot Engine
    Comment=Multi-platform 2D and 3D game engine
    Exec=$out/bin/redot %f
    Icon=redot
    Terminal=false
    Type=Application
    Categories=Development;IDE;
    EOF

    runHook postInstall
  '';

  meta = with lib; {
    description = "Redot Engine - форк Godot Engine";
    homepage = "https://github.com/Redot-Engine/redot-engine";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "redot";
  };
}
