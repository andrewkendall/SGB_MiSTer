# [Super Game Boy](https://en.wikipedia.org/wiki/Super_Game_Boy) for [MiSTer Platform](https://github.com/MiSTer-devel/Main_MiSTer/wiki)
 
Based on the [SNES core](https://github.com/MiSTer-devel/SNES_MiSTer) written by [srg320](https://github.com/srg320)

## Installing
Copy the `.RBF` to the root of your SD card. Put some ROMs (`*.GBC`, `*.GB`) and the SGB BIOS (`*.SFC`) into SGB folder.

## Features
* MSU-1 Support
* SGB1, SGB2, and SNES clock speed toggle.
* Cheat engine.
* Save/Load Backup Game Boy RAM.
* HORI SGB Commander buttons (Speed, Mute, Window, Color).

## Usage
Load your SGB BIOS from the OSD and load your Game Boy or Game Boy Color game. Here is a list of the [Super Game Boy enhanced games](https://en.wikipedia.org/wiki/List_of_Super_Game_Boy_games) that were released for reference.

The "SGB Speed" option in the OSD allows you to change the clock speed:
* SGB1 = 4.295 MHz (2.4% faster than a real Game Boy)
* SGB2 = 4.194 MHz (The same as an original Game Boy)
* SNES = 4.220 MHz (Brings it close to the SNES's refresh rate of 60.09Hz to reduce stutter)

Press L+R at the same time to enter the Super Game Boy boot rom's menu. If you'd like to manually start the animated screensaver for the alternate borders built into the Super Game Boy, then press L, L, L, L, R in order. You will hear a ding if the border supports the screensaver animations.

## SGB Commander buttons
The core reproduces the extra buttons of the HORI SGB Commander controller. Map them to any pad buttons in "Define buttons":
* **Speed** cycles the Game Boy speed: Normal, Super Slow, Slow. The "Commander Speed" OSD option adds the Commander's hidden fourth Dash mode, which runs about 25% faster and may produce audio/visual noise (as on real hardware).
* **Mute** toggles the Super Game Boy's sound on or off.
* **Window** opens or closes the SGB menu (same as pressing L+R).
* **Color** toggles between the selected palette and the game's original palette (same as pressing X).

Speed and Mute are recognized by the SGB BIOS itself through the same frame-exact button sequences the real Commander sent, injected in sync with the controller latch. They work with every SGB BIOS revision (SGB1 v1.0/1.1/1.2 and SGB2) and, like the real Commander, only operate from controller port 1.
