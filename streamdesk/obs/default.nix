{ pkgs, ... }:
{
  programs.obs-studio = {
    enable = true;
    package =
      (pkgs.obs-studio.override {
        decklinkSupport = false;
      }).overrideAttrs
        (old: {
          cmakeBuildType = "RelWithDebInfo";
        });
    plugins = with pkgs.obs-studio-plugins; [
      obs-source-record
    ];
  };
}
