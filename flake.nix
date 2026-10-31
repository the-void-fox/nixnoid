{
  description = "A setup for mildly paranoid people";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote.url = "github:nix-community/lanzaboote";
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    # ── Рабочие столы ──────────────────────────────────────────────────────────

    # Без follows: hyprstack собирает свои hyprland и quickshell, и подмена
    # nixpkgs под ними означала бы сборку композитора из исходников.
    hyprstack.url = "github:hase9awa/hyprstack-shell";

    # Прибита ревизией вместе со своим nixpkgs: их форк Quickshell (noctalia-qs)
    # не собирается с Qt 6.12 («Meta Types must be fully defined»), а сама
    # noctalia объявляет nixpkgs плавающей веткой. Из этого же снимка берётся
    # mango — см. modules/desktop/sessions/mango.
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell/3aab45a2f34fd47666b05892b95054952e788de1";
      inputs.nixpkgs.url = "github:nixos/nixpkgs/7525d999cd850b9a488817abc89c75dc733acf17";
    };

    driftwm = {
      url = "github:malbiruk/driftwm";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Программы вне nixpkgs ──────────────────────────────────────────────────

    # Без follows: под собственный nixpkgs этого флейка node лежит в кэше готовой.
    claude-code.url = "github:sadjow/claude-code-nix";

    helium = {
      url = "github:AlvaroParker/helium-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    artcraft = {
      url = "github:Devitek/artcraft-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Свои проекты ───────────────────────────────────────────────────────────
    # Только с github: git+file:// привязал бы сборку системы к этой машине.
    # Локальную копию на одну сборку подставляет `rebuild --local <вход>`.

    void-connect = {
      url = "github:the-void-fox/VoidConnect";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-rim = {
      url = "github:the-void-fox/rust-rim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [ ./configuration.nix ];
      };

      # `nix fmt` — привести весь репозиторий к nixfmt.
      formatter.${system} = pkgs.nixfmt-tree;

      # Rust с графикой (winit, iced, wgpu) без своего флейка в проекте:
      #   nix develop /etc/nixos#rust
      # или строка `use flake /etc/nixos#rust` в .envrc проекта.
      devShells.${system}.rust = pkgs.mkShell rec {
        packages = [ pkgs.pkg-config ];
        buildInputs = with pkgs; [
          wayland
          libxkbcommon
          freetype
          fontconfig
          vulkan-loader
          libGL
        ];
        # winit и wgpu подгружают эти библиотеки через dlopen уже при запуске.
        LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputs;
      };
    };
}
