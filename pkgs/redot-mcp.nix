# Redot 26.1, собранный ИЗ ИСХОДНИКОВ ради встроенного MCP-сервера (modules/mcp),
# которого НЕТ в готовом релизном бинаре (там модуль не вкомпилён). Даёт команды:
#   redot-mcp-engine        — сам движок из исходников
#   redot-mcp <проект>      — запуск MCP-сервера: --headless --mcp-server --path <проект>
#
# Собрано по образцу собственного flake Redot: встроенные (builtin) сторонние либы
# + рантайм-обёртка LD_LIBRARY_PATH (движок dlopen'ит vulkan/GL/X11 через sowrap),
# а не «системный» путь nixpkgs с версия-зависимыми патчами. Патч SConstruct —
# из nixpkgs godot: пробрасываем os.environ в scons, иначе gcc не видит NIX_CFLAGS.
#
# ВНИМАНИЕ: это сборка целого движка из исходников — тяжёлая, локальная (не из
# кэша), ~час+ на слабом CPU, и пересобирается при смене версии.
{
  lib,
  stdenv,
  fetchFromGitHub,
  scons,
  pkg-config,
  python3,
  perl,
  autoPatchelfHook,
  makeWrapper,
  libX11,
  libXcursor,
  libXinerama,
  libXext,
  libXrandr,
  libXrender,
  libXi,
  libXfixes,
  libxkbcommon,
  wayland,
  wayland-scanner,
  libdecor,
  alsa-lib,
  libpulseaudio,
  speechd,
  udev,
  dbus,
  fontconfig,
  freetype,
  libGL,
  vulkan-loader,
}:

let
  runtimeLibs = [
    libX11
    libXcursor
    libXinerama
    libXext
    libXrandr
    libXrender
    libXi
    libXfixes
    libxkbcommon
    wayland
    libdecor
    alsa-lib
    libpulseaudio
    speechd
    udev
    dbus
    fontconfig
    freetype
    libGL
    vulkan-loader
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "redot-mcp";
  version = "26.1-stable";

  src = fetchFromGitHub {
    owner = "Redot-Engine";
    repo = "redot-engine";
    rev = "redot-${finalAttrs.version}";
    hash = "sha256-MX+3xAdGTM5wluWYN9lBpahQxlfrAKM7REjNIleYFKo=";
  };

  nativeBuildInputs = [
    scons
    pkg-config
    python3
    perl
    autoPatchelfHook
    makeWrapper
    wayland-scanner
  ];

  buildInputs = runtimeLibs;
  runtimeDependencies = runtimeLibs;

  # Заставляем scons использовать окружение сборки (nix PATH/NIX_CFLAGS/…),
  # иначе Environment(tools=[]) стартует пустым и gcc не находит заголовки.
  postPatch = ''
    perl -pi -e '{ $r += s:(env = Environment\(.*):\1\nenv["ENV"] = os.environ: } END { exit ($r != 1) }' SConstruct
  '';

  # Модуль modules/mcp собирается по умолчанию (config.py: can_build=True, без is_enabled).
  sconsFlags = [
    "platform=linuxbsd"
    "target=editor"
    "arch=x86_64"
    "precision=single"
    "production=no"
    "debug_symbols=no"
  ];

  enableParallelBuilding = true;
  requiredSystemFeatures = [ "big-parallel" ];

  installPhase = ''
    runHook preInstall

    binary=$(ls bin/redot.linuxbsd.editor.* 2>/dev/null | head -1)
    if [ -z "$binary" ]; then
      echo "ERROR: собранный бинарь не найден. Содержимое bin/:"
      ls -la bin/ || true
      exit 1
    fi
    echo "Found binary: $binary"

    mkdir -p $out/bin
    cp "$binary" $out/bin/.redot-mcp-unwrapped
    chmod +x $out/bin/.redot-mcp-unwrapped

    # Голый движок из исходников (с MCP внутри).
    makeWrapper $out/bin/.redot-mcp-unwrapped $out/bin/redot-mcp-engine \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}"

    # Обёртка MCP-сервера: `redot-mcp <путь_к_проекту>`.
    makeWrapper $out/bin/.redot-mcp-unwrapped $out/bin/redot-mcp \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}" \
      --add-flags "--headless --mcp-server --path"

    runHook postInstall
  '';

  meta = {
    description = "Redot Engine 26.1 из исходников с нативным MCP-сервером";
    homepage = "https://github.com/Redot-Engine/redot-engine";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "redot-mcp";
  };
})
