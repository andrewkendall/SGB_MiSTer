# [Super Game Boy](https://en.wikipedia.org/wiki/Super_Game_Boy) for [MiSTer Platform](https://github.com/MiSTer-devel/Main_MiSTer/wiki)
 
Based on the [SNES core](https://github.com/MiSTer-devel/SNES_MiSTer) written by [srg320](https://github.com/srg320)

## Installing
Copy the `.RBF` to the root of your SD card. Put some ROMs (`*.GBC`, `*.GB`) and the SGB BIOS (`*.SFC`) into SGB folder.

## Features
* MSU-1 Support
* SGB1, SGB2, and SNES clock speed toggle.
* Cheat engine.
* Save/Load Backup Game Boy RAM.
* HORI SGB Commander controller mode.

## Usage
Load your SGB BIOS from the OSD and load your Game Boy or Game Boy Color game. Here is a list of the [Super Game Boy enhanced games](https://en.wikipedia.org/wiki/List_of_Super_Game_Boy_games) that were released for reference.

The "SGB Speed" option in the OSD allows you to change the clock speed:
* SGB1 = 4.295 MHz (2.4% faster than a real Game Boy)
* SGB2 = 4.194 MHz (The same as an original Game Boy)
* SNES = 4.220 MHz (Brings it close to the SNES's refresh rate of 60.09Hz to reduce stutter)

Press L+R at the same time to enter the Super Game Boy boot rom's menu. If you'd like to manually start the animated screensaver for the alternate borders built into the Super Game Boy, then press L, L, L, L, R in order. You will hear a ding if the border supports the screensaver animations.

## SGB Commander controller
Set **Hardware > Controller** to **SGB Commander** to reproduce the SGB position of the [HORI SGB Commander](https://www.gameboymuseum.com/game-boy-hardware-guide/accessories/hsd-07/hori-sgb-commander)'s SGB/SFC switch. No extra inputs need to be mapped: the standard SNES buttons automatically take the roles printed on the Commander:
* **Y / Speed** cycles the Game Boy speed: Normal, Super Slow, Slow. The **Commander Speed** option adds the Commander's hidden fourth Dash mode, which runs about 25% faster and may produce audio/visual noise (as on real hardware).
* **L / Mute** toggles the Super Game Boy's sound on or off.
* **R / Window** opens or closes the SGB menu (the controller sends L+R).
* **X / Color** toggles between the selected palette and the game's original palette.

Set **Controller** to **SNES** for the SFC switch position, where Y, X, R and L are ordinary SNES buttons.

Speed and Mute are recognized by the SGB BIOS itself through the same frame-exact button sequences the real Commander sent, injected in sync with the controller latch. They work with every SGB BIOS revision (SGB1 v1.0/1.1/1.2 and SGB2) and, like the real Commander, only operate from controller port 1.

The mode applies to MiSTer-mapped controllers on port 1. A SNAC SNES controller supplies its own raw serial data and is not translated.
