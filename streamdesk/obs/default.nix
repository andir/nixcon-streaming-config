{ pkgs, ... }:
{
  programs.obs-studio = {
    enable = true;
    package = pkgs.obs-studio.override {
      decklinkSupport = true;
    };
    plugins = with pkgs.obs-studio-plugins; [
      obs-source-record
      obs-webkitgtk
    ];
  };
}
