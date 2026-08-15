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
Select **Hardware > Controller > SGB Commander**. This selection represents the SGB position of the [HORI SGB Commander](https://www.gameboymuseum.com/game-boy-hardware-guide/accessories/hsd-07/hori-sgb-commander) switch.

Do not make additional input assignments. The core gives the Commander functions to these standard SNES buttons:

* **Y / Speed** selects Normal, Super Slow, and Slow.
* **L / Mute** mutes or restores the Super Game Boy sound.
* **R / Window** opens or closes the SGB menu. The core sends L and R together.
* **X / Color** changes between the selected palette and the original palette.

The **Commander Speed** setting can add the hidden Dash mode. Dash is approximately 25 percent faster than Normal.

Dash can cause unwanted audio or video output. Original hardware can give the same type of output.

Select **Controller > SNES** for the SFC switch position. The core then gives Y, X, R, and L their normal functions.

The core sends the original Speed and Mute sequences to the SGB BIOS. It advances each state after a full automatic read.

The core does not advance a state after a short multitap probe. Tests passed with SGB1 v1.0, v1.1, v1.2, and SGB2.

The original Commander operates from controller port 1. The MiSTer mode has the same limit and supports controller swap.

The mode applies to a MiSTer-mapped controller. It does not translate the raw serial data from a SNAC SNES controller.
