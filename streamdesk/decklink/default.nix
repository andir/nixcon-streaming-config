{
  hardware.decklink.enable = true;

  # pipewire has issues with the blackmagic snd driver
  services.pipewire = {
    audio.enable = false;
    alsa.enable = false;
    pulse.enable =false;
  };
  services.pulseaudio.enable = true;
}
