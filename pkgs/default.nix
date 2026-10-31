# Оверлей: свои пакеты и пакеты из входов флейка — как обычные pkgs.<имя>.
#
# Он для НОВЫХ пакетов и для подмены листьев графа. Подменишь пакет из его
# середины (была попытка с adwaita-icon-theme) — из кэша выпадет всё, что от
# него зависит, и соберётся из исходников. Такие правки делаются на месте.
inputs: final: _prev:

let
  fromInput = name: inputs.${name}.packages.${final.stdenv.hostPlatform.system}.default;
in
{
  hydra-launcher = final.callPackage ./hydra.nix { };
  redot = final.callPackage ./redot.nix { };
  redot-mcp = final.callPackage ./redot-mcp.nix { };

  claude-code = fromInput "claude-code"; # в nixpkgs отстаёт на несколько версий
  helium = fromInput "helium";
  rust-rim = fromInput "rust-rim";
  void-connect = fromInput "void-connect";
}
