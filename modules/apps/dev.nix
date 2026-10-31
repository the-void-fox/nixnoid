# Разработка: git, Rust, редакторы, игровые движки, контейнеры.
{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    config.credential.helper = "libsecret";
  };

  # `use flake` или `use nix` в .envrc проекта — и окружение поднимается само
  # при входе в каталог: nix-direnv кэширует его и держит от сборщика мусора.
  programs.direnv.enable = true;

  # Podman вместо Docker; команда `docker` тоже работает.
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  environment.systemPackages = with pkgs; [
    rustup
    (python3.withPackages (ps: [ ps.tkinter ]))
  ];

  hm = {
    programs.gh.enable = true;

    home.packages = with pkgs; [
      claude-code
      vscodium-fhs
      lazygit
      nixfmt
      nodejs_26

      # Игры: Redot (форк Godot) с C# и он же из исходников — ради встроенного
      # MCP-сервера. redot-mcp собирается локально, час с лишним.
      redot
      redot-mcp
      dotnet-sdk_8
      assetripper # ассеты из готовых игр на Unity
    ];
  };

  services.flatpak.packages = [
    "com.github.marhkb.Pods" # Podman в окне
    "eu.jumplink.Learn6502" # ассемблер 6502
  ];
}
