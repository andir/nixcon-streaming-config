{ pkgs, ... }:
{
  boot.kernelParams = [ "acpi_enforce_resources=lax" ];
  boot.kernelModules = [ "nct6775" ];

  environment.systemPackages = [ pkgs.lm_sensors ];

  environment.etc."sensors.d/asrock-x600-itx.conf".text = ''
    chip "nct6799-isa-0290"
      label fan1 "CPU Fan"
      label fan2 "Chassis Fan 1"
  '';

  hardware.fancontrol.enable = true;
  # this configure the chassis fan such that it spins up to max speed above 45C on the CPU.
  hardware.fancontrol.config = ''
    INTERVAL=10
    DEVPATH=hwmon5=devices/platform/nct6775.656
    DEVNAME=hwmon5=nct6799
    FCTEMPS=hwmon5/pwm4=hwmon5/temp7_input
    FCFANS= hwmon5/pwm4=hwmon5/fan4_input
    MINTEMP=hwmon5/pwm4=20
    MAXTEMP=hwmon5/pwm4=45
    MINSTART=hwmon5/pwm4=175
    MINSTOP=hwmon5/pwm4=60
    MINPWM=hwmon5/pwm4=60
    MAXPWM=hwmon5/pwm4=255
  '';
}
