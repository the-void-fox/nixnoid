# Нейросети: локальные модели и клиенты.
{ pkgs, ... }:

{
  # Модели на Radeon через ROCm. 10.3.0 — это gfx1030: под ним ROCm принимает
  # и соседние RDNA2-карты, которых нет в его списке.
  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;
    rocmOverrideGfx = "10.3.0";
  };

  hm.home.packages = [ pkgs.koboldcpp ];

  services.flatpak.packages = [ "br.com.wiselabs.simplexity" ]; # клиент Perplexity
}
