{
  services.desktopManager.plasma6.enable = true;

  services.displayManager = {
    sddm.enable = true;
    autoLogin = {
      enable = true;
      user = "nixos";
    };
  };


  services.pipewire = {
    enable = true;
    audio.enable = false;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
    ];
  };
    

  programs.kde-pim.enable = false;
    security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  services.xserver.enable = true;

  # KDE complains if power management is disabled (to be precise, if
  # there is no power management backend such as upower).
  powerManagement.enable = true;

}
