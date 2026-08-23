# pi3-nix-fm

NixOS on a Raspberry Pi 3 B, built with the `raspberry-pi-3` profile from
[nixos-hardware](https://github.com/NixOS/nixos-hardware/tree/master/raspberry-pi).


## Layout

One flake, two `nixosConfigurations` sharing `src/configuration.nix`:

| Output | Extra module | Purpose |
| --- | --- | --- |
| `default` | `src/filesystems.nix` | the running system |
| `sd-image` | `src/sd-image.nix` | builds `packages.aarch64-linux.sd-image` |

Two configurations rather than one plus `extendModules`, because the SD-image
module cannot be shared:

- `sd-image-aarch64.nix` imports `profiles/base.nix`, and `sd-image.nix` imports
  `profiles/all-hardware.nix`. That is installer-grade bloat — `nixos-install-tools`,
  ZFS, every hardware module — which has no business living on the Pi's SD card.
- `sd-image.nix` declares `fileSystems."/"` and `fileSystems."/boot/firmware"`
  **without** `mkDefault`, so it hard-conflicts with anything the running system
  declares.

One flake rather than two, because two lockfiles would drift: the image you flash
and the closure you later switch to would be built from different nixpkgs. A
nested flake also could not reach `../../../lib/flake`.

## Building and deploying

Builds are aarch64 on an x86_64 host, so `wl-nix-fm` sets
`boot.binfmt.emulatedSystems = [ "aarch64-linux" ]`. Without it nothing here
builds.

```sh
# build the image
nix build ./flakes/system/pi3-nix-fm#packages.aarch64-linux.sd-image

# deploy to a running board
nixos-rebuild switch \
  --flake /etc/nixos/flakes/system/pi3-nix-fm#default \
  --target-host <user>@<ip> --sudo \
  --ask-sudo-password
```

Build on the laptop and push the closure rather than building on the Pi: 1 GB of
RAM and an SD card make on-board builds painful.

## Kernel: mainline, not the vendor kernel

```nix
boot.kernelPackages = pkgs.linuxPackages;
```

The `raspberry-pi-3` profile sets this to
`lib.mkDefault (linuxPackagesFor linux-rpi)`. A plain assignment beats that
`mkDefault`.

`linux-rpi` is built from source against the vendor defconfig and is in no
binary cache, so accepting it means an emulated aarch64 kernel compile — hours —
on every nixos-hardware bump. Mainline covers the Pi 3 B and substitutes from
`cache.nixos.org`.

**This choice has a consequence, see the next section.** Delete the line to
return to the vendor kernel, and read on before doing so.

## Device tree: must match the kernel

```nix
boot.loader.generic-extlinux-compatible.useGenerationDeviceTree = lib.mkForce true;
```

**Kernel and device tree have to agree.** This is the single most important
constraint in this configuration, and getting it wrong produces a board that
boots to a black screen.

The `raspberry-pi-3` profile sets `useGenerationDeviceTree = false`, which makes
the boot-loader builder omit the `FDTDIR` line from `extlinux.conf`. U-Boot then
passes the kernel the **vendor** device tree that the GPU firmware built from
`config.txt`. That is right for `linux-rpi`, and wrong for mainline: mainline's
`vc4` driver cannot resolve the DDC I2C node in a vendor DTB.

Symptoms of the mismatch, all from one cause:

```
vc4-drm soc:gpu: [drm] *ERROR* Failed to get ddc i2c adapter by node
platform leds: deferred probe pending: leds-gpio: Failed to get GPIO
sdhost-bcm2835: unexpected command 6 error
mmc0: error -84 whilst initialising SD card
mmc0: error -110 whilst initialising SD card
```

`vc4` displaces the `simpledrm` firmware framebuffer that works early in boot,
so HDMI shows the first few seconds of console output and then goes black. The
`mmc0` errors are the same mismatch reaching `bcm2835-sdhost`: the card took
35–45 seconds and four or five retries to initialise, and boots died abruptly
under disk load.

Forcing this option on emits `FDTDIR`, so U-Boot loads the DTB shipped with the
running kernel (`broadcom/bcm2837-rpi-3-b.dtb`) and the device tree matches the
driver.

### Consequence: `config.txt` device tree settings no longer reach Linux

With `FDTDIR` set, U-Boot replaces the device tree the GPU firmware built. Every
`dtparam` and `dtoverlay` in `config.txt` is therefore **discarded before Linux
sees it**.

So the usual Raspberry Pi tuning knobs are unavailable — `dtparam=sd_force_pio=on`,
`sd_overclock=25`, `dtoverlay=disable-bt` have no effect. Equivalent
changes have to go through `hardware.deviceTree.overlays` or a kernel parameter
instead.

This also means `configtxt.settings.all.enable_uart` no longer enables the UART
node in the device tree the kernel receives — the firmware-level clock fix still
applies, but if serial is silent, this is the first thing to check.

## Firmware partition

```nix
hardware.raspberry-pi.firmware = {
  enable = true;
  uboot.enable = true;
};
```

`enable` adds an activation script that repopulates the firmware partition on
every `nixos-rebuild switch`. It is off by default, and needs `/boot/firmware`
mounted — which is why `src/filesystems.nix` deliberately omits `noauto`. If it
is not mounted the script logs `not a mounted partition, skipping firmware
install` and the write silently lands on the root filesystem instead.

`uboot.enable` is **required**, and also off by default. `hardware.raspberry-pi.firmware`
`mkForce`s `sdImage.populateFirmwareCommands`, discarding the one
`sd-image-aarch64.nix` provides. Its own install script copies `u-boot.bin`, and
emits `config.txt`'s `kernel=` line, only when this is enabled.

Leave it off and the image gets no U-Boot and no `kernel=` line. The GPU
firmware looks for `kernel8.img`, finds nothing, and the board does not boot —
while a `extlinux.conf` sits unread on the ext4 partition. The
failure is silent and only visible over serial.

Verify before flashing, reading the FAT partition without mounting it:

```sh
zstd -dc result/sd-image/*.img.zst | head -c 41943040 > head.img
fdisk -l head.img                                    # partition 1 offset, ×512
nix shell nixpkgs#mtools --command mdir  -i head.img@@8388608 ::
nix shell nixpkgs#mtools --command mtype -i head.img@@8388608 ::/config.txt
```

`u-boot.bin` must be present and `config.txt` must contain `kernel=u-boot.bin`.

## Console log level

```nix
boot.consoleLogLevel = 4;
```

NixOS defaults to 4 (`err` and above reach the console) but
`sd-image-aarch64.nix` raises it to `lib.mkDefault 7` (`debug`).
A plain assignment beats that `mkDefault` and pins the
same value for both configurations.

This is what silences the HDMI connector poll. DRM re-probes connectors it has
no reliable hotplug interrupt for every 10 seconds
(`DRM_OUTPUT_POLL_PERIOD`), re-reading the display's EDID and warning each time
the read comes back malformed:

```
hdmi-audio-codec.1.auto: HDMI: Unknown ELD version 0
EDID has corrupt header
```

Both are warning level, so neither reaches the console at 4 — they still go to
the journal, nothing is hidden. The picture works regardless because DRM scores
the EDID header rather than demanding an exact match, and carries on with a
recovered or fallback EDID. `Unknown ELD version 0` is downstream: the HDMI
audio codec never got a usable audio block, so HDMI audio will not work. Neither
matters on a headless board; a different HDMI cable is the fix if it ever does.

Raise this back to 7 when debugging an early boot problem.

## Other notes

- `system.stateVersion = "26.05"` — first install was on 26.05. Do not bump it.
- `zramSwap.enable` — 1 GB of RAM, and swapping to an SD card is miserable.
- `boot.loader.generic-extlinux-compatible.configurationLimit = 10` — old
  generations keep their kernel and initrd in `/boot` on the root partition,
  which adds up quickly on a small card.
- No `hardware-configuration.nix`: there is nothing to scan. The profile covers
  the kernel, initrd modules and wireless firmware; `fileSystems` come from
  `src/filesystems.nix` or `src/sd-image.nix`.

## Debugging a board that will not boot

Serial is the only reliable channel: USB-TTL adapter on the GPIO header, pin 6 →
GND, pin 8 (TXD) → adapter RX, pin 10 (RXD) → adapter TX, 115200 8N1. Then
`nix run nixpkgs#picocom -- -b 115200 /dev/ttyUSB0`.

Failing that, the SD card can be read on another machine. `/nix-path-registration`
is the useful marker: first boot removes it, so if it is still present the first
boot never completed. `/var/log/journal/` can be read directly with
`journalctl --file=<path>` without mounting anything as root.
