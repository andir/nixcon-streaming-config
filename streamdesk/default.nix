{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  imports = [
    ./obs
    ./decklink
    ./kde
    ./companion
  ];

  nixpkgs.overlays = [
    (self: super: {
      decklink-sdk = super.runCommand "decklink-sdk" {
        inherit (super.obs-studio) src;
      } ''
          cp -rv $src/plugins/decklink/linux/decklink-sdk $out
      '';
      blackmagic-desktop-video = super.blackmagic-desktop-video.overrideAttrs ({ postInstall ? "", buildInputs ? [], ... }: {
        buildInputs = buildInputs ++ [
          self.fontconfig
          self.freetype
          self.xorg.libXrender
          self.xorg.libICE
          self.xorg.libSM
          self.qt5.qtbase
          self.qt5.wrapQtAppsHook
        ];
        postInstall = ''
          ${postInstall}
          find $unpacked
          cp $unpacked/usr/lib/blackmagic/DesktopVideo/BlackmagicDesktopVideoSetup $out/bin
          mkdir $out/DesktopVideo
#          cp -r $unpacked/usr/lib/blackmagic/DesktopVideo/* $out/DesktopVideo
        '';
      });
    })
  ];
  
  environment.systemPackages = with pkgs; [
    git
    firefox
    chromium

    vim
    nano
    pciutils

    blackmagic-desktop-video

    (ffmpeg_7-full.overrideAttrs ({ buildInputs, configureFlags, postFixup ? "", nativeBuildInputs ? [], ... }: {
      buildInputs = buildInputs ++ [ blackmagic-desktop-video ];
      nativeBuildInputs = nativeBuildInputs ++ [ pkgs.makeWrapper ];
      configureFlags = configureFlags ++ ["--enable-decklink" "--enable-nonfree" "--extra-cflags=-I${decklink-sdk}"];
      postFixup = ''
        ${postFixup}
        wrapProgram $bin/bin/ffmpeg --prefix LD_LIBRARY_PATH : "${lib.getLib blackmagic-desktop-video}/lib/"
        wrapProgram $bin/bin/ffprobe --prefix LD_LIBRARY_PATH : "${lib.getLib blackmagic-desktop-video}/lib/"
        wrapProgram $bin/bin/ffplay --prefix LD_LIBRARY_PATH : "${lib.getLib blackmagic-desktop-video}/lib/"
      '';
    }))
    inkscape
    gimp
  ];

  # VM guest additions to improve host-guest interaction
  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;
  virtualisation.vmware.guest.enable = pkgs.stdenv.hostPlatform.isx86;
  # https://github.com/torvalds/linux/blob/00b827f0cffa50abb6773ad4c34f4cd909dae1c8/drivers/hv/Kconfig#L7-L8
  virtualisation.hypervGuest.enable =
    pkgs.stdenv.hostPlatform.isx86 || pkgs.stdenv.hostPlatform.isAarch64;
  services.xe-guest-utilities.enable = pkgs.stdenv.hostPlatform.isx86;
  # The VirtualBox guest additions rely on an out-of-tree kernel module
  # which lags behind kernel releases, potentially causing broken builds.
  virtualisation.virtualbox.guest.enable = false;

  # Firewall must be of for the fancy stuff like OBS websockets
  networking.firewall.enable = false;

  time.timeZone = "Europe/Berlin";

  # Enable plymouth
  boot.plymouth.enable = true;

  hardware.enableAllHardware = true;
  image.modules.iso = {
    # EFI booting
    isoImage.makeEfiBootable = true;

    # USB booting
    isoImage.makeUsbBootable = true;

    # Add Memtest86+ to the CD.
    boot.loader.grub.memtest86.enable = true;

    # Use less privileged nixos user
    users.users.nixos = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
        "video"
      ];
      # Allow the graphical user to login without password
      initialHashedPassword = "";
    };

    # Allow the user to log in as root without a password.
    users.users.root.initialHashedPassword = "";

    # Don't require sudo/root to `reboot` or `poweroff`.
    security.polkit.enable = true;

    # Allow passwordless sudo from nixos user
    security.sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };

    # Automatically log in at the virtual consoles.
    services.getty.autologinUser = "nixos";
  };
  # TODO:
  # * disable screensaver
  # * disable suspend to disk
  # * disable audio output from system notifications (whatever they might be)
}
