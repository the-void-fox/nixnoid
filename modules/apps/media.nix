# Графика, видео и звук: редакторы, запись, просмотр.
{ inputs, pkgs, ... }:

{
  imports = [ inputs.artcraft.nixosModules.default ];

  programs.artcraft.enable = true; # ArtCraft от Storyteller.ai

  # Кодеки для всего, что играет медиа через GStreamer.
  environment.systemPackages = with pkgs.gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-ugly
    gst-libav
  ];

  hm.home.packages = with pkgs; [
    krita
    gimp
    glaxnimate
    kdePackages.kdenlive
    obs-studio
    showmethekey # нажатые клавиши на экране — для записи
    audacity
    ffmpeg

    swayimg
    clapper
    kew
  ];

  services.flatpak.packages = [
    "com.github.libresprite.LibreSprite"
    "io.github.nokse22.asciidraw"
  ];
}
