{
  hardware.decklink.enable = true;

  # pipewire has issues with the blackmagic snd driver
  services.pipewire.enable = false;
  services.pulseaudio.enable = true;
}
