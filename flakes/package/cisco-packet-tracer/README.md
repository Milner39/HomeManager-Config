Download the latest Ubuntu installer from https://www.netacad.com/resources/lab-downloads.

Move the installer to this directory and name it `CiscoPacketTracer.deb`

Run
```
git add --intent-to-add ./CiscoPacketTracer.deb
git update-index --assume-unchanged ./CiscoPacketTracer.deb
```
To trick nix into still adding the installer to the nix store

Consume the package from other flakes like normal