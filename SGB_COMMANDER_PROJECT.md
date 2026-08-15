# HORI SGB Commander Mode for the MiSTer SGB Core

## Engineering proposal and validation record

| Item | Value |
| --- | --- |
| Project | MiSTer Super Game Boy core |
| Feature | HORI SGB Commander controller mode |
| Proposal branch | `sgb-commander-proposal` |
| Base revision | `128954b` (`main`, release 20260802) |
| Commit structure | One proposal commit above `main` |
| Test date | 2026-08-15 |
| Test result | Pass |
| Final test file | `SGB_20260815_Commander.rbf` |
| SHA-256 | `5523535b04c40aeb16057abfa760ba719fb1fbb206095216736e52d7c7e00a04` |

## 1. Purpose

This project adds HORI SGB Commander operation to the MiSTer SGB core.

The feature uses the standard SNES controller map. It does not add special MiSTer button assignments.

The user selects one of two controller types in the Hardware menu:

- `SNES`
- `SGB Commander`

This selection represents the SFC/SGB switch on the original controller.

The core then assigns the Commander functions to Y, X, R, and L. These assignments agree with the controller labels.

## 2. Result

The completed feature supplies these functions:

| Standard button | Commander label | Result in Commander mode |
| --- | --- | --- |
| Y | Speed | Selects the next SGB speed mode |
| X | Color | Changes between the selected palette and the original palette |
| R | Window | Opens or closes the SGB window |
| L | Mute | Mutes or restores the SGB sound |

The `SNES` selection gives normal SNES controller operation. All standard inputs pass through without a change.

The `SGB Commander` selection changes only the required button roles. The other controller buttons keep their normal roles.

The implementation reproduces the controller words that the SGB BIOS expects. It does not directly change internal speed or sound signals.

### 2.1 Change summary

The proposal makes these changes:

| Area | Change |
| --- | --- |
| OSD | Adds SNES and SGB Commander controller selections |
| OSD | Adds three-mode and Dash-enabled Speed selections |
| Controller path | Adds Commander translation before the port 1 `ioport` module |
| Speed | Sends the original nine-state BIOS sequence |
| Mute | Sends the original eight-state BIOS sequence |
| Window | Changes R to L+R |
| Color | Keeps X as the BIOS Color input |
| Read timing | Ignores short multitap probes and uses full reads |
| Port behavior | Keeps controller swap and does not change port 2 |
| Build | Adds the RTL file and selects fitter seed 2 |
| Documentation | Adds user instructions and this engineering record |
| Verification | Adds a self-checking SystemVerilog testbench |

The proposal does not add controller-map inputs. It does not change raw SNAC serial data.

### 2.2 Test summary

The final test program used the exact RBF that is identified in this record.

| Test level | Evidence | Result |
| --- | --- | --- |
| RTL simulation | Exact Speed and Mute sequences | Pass |
| Timing-boundary simulation | Tests before and after the ninth clock | Pass |
| Multitap simulation | Eight-clock probes do not advance a command | Pass |
| Static check | Verilator reports no lint fault | Pass |
| Quartus timing | Seed 2 has positive worst slack and zero TNS | Pass |
| File identity | Build and MiSTer SHA-256 values agree | Pass |
| SGB2 hardware | Complete three-mode and four-mode Speed cycles | Pass |
| BIOS hardware | Speed works with four tested BIOS revisions | Pass |
| Video hardware | Read timing works with PAL and NTSC | Pass |
| Function hardware | Speed, Mute, Window, and Color operate correctly | Pass |
| Cleanup | Controllers and MiSTer settings returned to a safe state | Pass |

The hardware test did not include every Game Boy ROM. Color results remain dependent on the game.

Raw SNAC translation is outside the proposal scope. Section 19 gives all limits.

## 3. Reason for the controller selection

An initial option was to add four new MiSTer input assignments. This option was not necessary.

All supported controllers already have standard SNES assignments for Y, X, R, and L. The Commander uses these same physical positions.

A controller selection gives these advantages:

- The user does not have to make more input assignments.
- One controller map works in the two modes.
- The operation agrees with the switch on the original Commander.
- The OSD clearly shows the active controller behavior.
- The normal SNES mode stays available.
- Existing controller map files stay valid.

This design also prevents unclear assignments for controllers with different labels.

## 4. Original hardware behavior

The HORI SGB Commander is a Japan-only SNES controller for Super Game Boy operation.

The controller has an `SGB/SFC` switch. Its front labels identify four special buttons:

- `SPEED-Y`
- `COLOR-X`
- `WINDOW-R`
- `MUTE-L`

The special Speed and Mute buttons do not send one new controller bit. They send a timed series of standard SNES controller words.

The SGB BIOS compares these words with internal tables. A correct series starts the applicable BIOS function.

Window sends L and R together. Color remains the standard X input.

### 4.1 Standard speed operation

The normal Commander speed order is:

1. Normal
2. Super Slow
3. Slow
4. Normal

The MiSTer option name is `3 modes`.

### 4.2 Hidden Dash operation

Dash is an authentic SGB BIOS function. It is not a new speed mode made by this project.

All four inspected BIOS revisions contain the Dash branch. The original Commander makes this branch available through a hidden start action.

The user holds Up when the original controller receives power. A reconnect gives the same start condition.

The MiSTer core does not need a physical reconnect. The `4 modes+Dash` option makes the authentic branch available.

The four-mode order is:

1. Normal
2. Dash
3. Super Slow
4. Slow
5. Normal

Dash is approximately 25 percent faster than Normal. Real hardware can give video or audio noise in this mode.

The MiSTer core can give the same type of unwanted output. This output is a property of Dash and not a controller fault.

## 5. User interface

The change adds two items to the Hardware menu.

| Menu item | Values | Function |
| --- | --- | --- |
| `Controller` | `SNES`, `SGB Commander` | Selects the controller behavior |
| `Commander Speed` | `3 modes`, `4 modes+Dash` | Selects the Speed cycle |

`Controller` uses status bit 15. `Commander Speed` uses status bit 16.

The settings do not add an input-map requirement.

### 5.1 Difference from the existing SGB Speed setting

The core already has an `SGB Speed` setting. It selects the base Game Boy clock.

Its selections are SGB1, SGB2, and SNES. This setting is separate from the new Commander controls.

`Commander Speed` does not select the base clock. It only selects the command cycle that Y sends to the BIOS.

Thus, the two settings have different purposes:

| Setting | Purpose |
| --- | --- |
| `SGB Speed` | Selects the core base clock |
| `Commander Speed` | Includes or excludes Dash in the BIOS Speed cycle |

### 5.2 Operation

To use normal SNES controls, do these steps:

1. Open the MiSTer OSD.
2. Open the Hardware menu.
3. Set `Controller` to `SNES`.

To use Commander controls, do these steps:

1. Open the MiSTer OSD.
2. Open the Hardware menu.
3. Set `Controller` to `SGB Commander`.
4. Set `Commander Speed` to the necessary cycle.
5. Use Y, X, R, and L for the printed Commander roles.

## 6. Function details

### 6.1 Speed

Y starts the Speed command sequence. The core consumes Y while Commander mode is active.

The BIOS receives this sequence on successive full controller reads:

| Sequence state | 3 modes | 4 modes+Dash |
| ---: | --- | --- |
| 0 | L | L |
| 1 | R | R |
| 2 | No button | No button |
| 3 | R | R |
| 4 | L | L |
| 5 | No button | No button |
| 6 | L | L |
| 7 | R | R |
| 8 | No button | Y and Right |

The final Y and Right state is BIOS word `$4100`. It selects the Dash-enabled branch.

The three-mode sequence gives a neutral final state. Its BIOS word is `$0000`.

One Y press starts one sequence. A held Y button does not continuously start new sequences.

### 6.2 Mute

L starts the Mute command sequence. The core consumes L while Commander mode is active.

The BIOS receives this sequence:

| Sequence state | Controller state |
| ---: | --- |
| 0 | R |
| 1 | L |
| 2 | No button |
| 3 | L |
| 4 | R |
| 5 | No button |
| 6 | R |
| 7 | L |

This sequence is the Speed pattern with L and R exchanged. It stops one state before the Speed sequence.

Each completed sequence changes the current mute state. The next completed sequence restores the other state.

### 6.3 Window

R makes the core send L and R together. The SGB BIOS uses this standard combination for its window.

The first press opens the window. The next press closes the window.

### 6.4 Color

X stays as X. The SGB BIOS gives the Color function to this input.

Color changes between the selected palette and the title's original palette. The visible result depends on the title and its current state.

A title can restrict palette changes. A title can also supply its own SGB palettes.

Therefore, Color is not a new universal palette generator. It requests the normal BIOS color change.

The hardware test used Donkey Kong. X changed an 11-color selected set to a 5-color original set.

A second X press restored the 11-color set.

## 7. Compatibility

### 7.1 BIOS revisions

The investigation used these four user-supplied SGB BIOS revisions:

- SGB1 v1.0
- SGB1 v1.1
- SGB1 World Rev 2, also identified as v1.2
- SGB2

All four revisions contain the same Speed and Mute tables.

The Speed table is at SNES address `$01:E389`. The Mute table is at SNES address `$01:E39B`.

The feature passed hardware tests with all four revisions.

### 7.2 Game compatibility

Speed, Mute, and Window are SGB BIOS functions. Their command recognition does not depend on a cartridge-specific input map.

This system design gives compatibility across normal Game Boy ROMs. The work did not include an exhaustive test of every ROM.

Color also uses a BIOS function. Its visible result can differ because games can control their palette state.

The test results support system-level compatibility. They do not make an unsupported claim that every cartridge received an individual test.

### 7.3 SGB2 timing

SGB2 has timing that is closer to an original Game Boy. It is the strict reference for this feature.

SGB2 was a Japan-only product. It did not receive an official United Kingdom release.

This history made a separate PAL test important. PAL users usually use an SGB1 BIOS revision.

The implementation first had to pass SGB2. It then had to pass all SGB1 revisions.

The complete SGB2 speed cycles passed. Thus, the strict timing reference did not show a sequence error.

### 7.4 Video standards

The full test set used NTSC. A separate test used the PAL setting with SGB1 World Rev 2.

The PAL test passed. This result confirms that the read synchronization does not depend on NTSC frame timing.

### 7.5 Controller ports

The original Commander operates from controller port 1. The MiSTer feature has the same limit.

MiSTer controller swap stays effective. The module processes the mapped controller that becomes port 1.

Port 2 stays unchanged. The feature does not change multitap operation on port 2.

### 7.6 SNAC

The module processes MiSTer-mapped controller data. It does not process raw SNAC serial data.

A SNAC SNES controller supplies its own serial controller stream. The Commander translation does not change this stream.

Select `SNES` for normal SNAC use. A future change can add a separate raw serial translator if necessary.

## 8. Investigation

### 8.1 Initial question

The first question was whether four extra input assignments were necessary.

Visual inspection of the controller showed that its special labels use Y, X, R, and L. This supported a controller-mode design.

The next question was whether each button was a simple remap. BIOS inspection showed that only Color and Window are simple cases.

Speed and Mute require command sequences across multiple controller reads.

### 8.2 BIOS table inspection

The four BIOS files were inspected independently. Each file had the same command tables and the same Dash branch.

This inspection supplied these results:

- The Speed sequence has nine states.
- The Mute sequence has eight states.
- Mute exchanges L and R in the Speed pattern.
- The normal Speed path ends with `$0000`.
- The Dash Speed path ends with `$4100`.
- `$4100` represents Y and Right.

These results show that Dash is firmware behavior. They also show that direct internal speed control is not necessary.

### 8.3 Controller-read inspection

The SGB BIOS does not make only one type of controller read.

It makes short manual reads during its multitap check. It also makes full automatic SNES controller reads.

The manual check includes eight clocks after the latch falls. A command must not advance after these eight clocks.

The automatic read includes 16 clocks. Its ninth low-latch clock identifies a full read.

This difference supplied a stable read marker.

### 8.4 MiSTer input inspection

The existing `ioport` module stores `JOY_OUT` while the controller latch is high. It then shifts the stored word.

Thus, a command state is isolated before the serial read starts. A later output change cannot damage the current stored word.

This behavior made it possible to prepare the next command state before the next latch.

## 9. Design decisions

### 9.1 Selected design

The selected design inserts one small module before the port 1 `ioport` instance.

The data path is:

```text
Mapped controller
        |
        v
Port swap selection
        |
        v
sgb_commander
        |
        v
Port 1 ioport shift register
        |
        v
SNES controller bus
        |
        v
SGB BIOS
```

The module receives the controller latch and port 1 clock. It uses these signals to identify complete reads.

### 9.2 Designs not selected

#### Extra MiSTer input assignments

This design duplicated buttons that already exist. It also required a new map for each controller.

#### Direct internal control

This design could directly set speed, mute, or palette state. It would bypass the authentic BIOS command path.

The selected design lets each BIOS perform its own function. This behavior is closer to the original controller.

#### Advance after eight clocks

This design would mistake the BIOS multitap probe for a complete controller read. It could advance a sequence too early.

#### Advance at the terminal clock

This design would have less time before the next latch. It would also make the terminal clock a critical state boundary.

The selected ninth-clock marker gives more time. It prepares the next word well before the next latch.

## 10. RTL implementation

### 10.1 Module

The new module is `rtl/sgb_commander.sv`.

The module has these inputs:

- System clock
- Reset
- Controller latch
- Port 1 controller clock
- Commander enable
- Dash enable
- The 12-bit mapped controller word

The module supplies one 12-bit controller word to `ioport`.

### 10.2 State

The module stores these principal states:

| State | Purpose |
| --- | --- |
| `active` | Shows that a command sequence is active |
| `pending` | Shows that a new command waits for a full-read marker |
| `mute` | Selects the Speed or Mute sequence |
| `step` | Selects the current sequence state |
| `read_clocks` | Counts low-latch controller clocks through the ninth clock |
| Edge history | Detects new button, latch, and clock edges |

Reset clears all command state. A change to `SNES` also clears all command state.

### 10.3 Trigger operation

A new Y edge requests Speed. A new L edge requests Mute.

The module stores this request as pending. It does not modify the controller word that `ioport` already stored.

At the ninth clock, the module starts or advances the sequence. The new state is ready for the next latch.

An eight-clock probe does not start or advance a sequence.

If Y and L start together, Speed has priority. An active sequence ignores a new trigger until the sequence ends.

### 10.4 Idle operation

In Commander mode, the module removes Y and L from the idle controller word. These buttons are command triggers.

X passes through without a change. R passes through and also adds L.

Thus, R produces the L and R combination for Window.

In SNES mode, the complete input word passes through without a change.

## 11. Source changes

### `SGB.sv`

- Adds `Controller` to the Hardware menu.
- Adds `Commander Speed` to the Hardware menu.
- Selects the mapped controller for port 1.
- Instantiates `sgb_commander` before `ioport`.
- Keeps controller swap behavior.

### `rtl/sgb_commander.sv`

- Implements the Commander button roles.
- Generates the exact Speed and Mute sequences.
- Detects full automatic reads.
- Ignores short multitap probes.
- Supports the authentic Dash branch.
- Passes normal SNES controls without a change.

### `sim/sgb_commander_tb.sv`

- Adds a self-checking SystemVerilog testbench.
- Models manual multitap probes.
- Models full automatic controller reads.
- Checks command content and timing boundaries.

### `files.qip`

- Adds the new RTL module to the Quartus project.

### `README.md`

- Adds the Commander feature to the feature list.
- Explains the two controller selections.
- Explains the standard button roles.
- Explains Dash and the SNAC limit.
- Uses Simplified Technical English for all Commander instructions.

### `SGB_COMMANDER_PROJECT.md`

- Records the investigation and design decisions.
- Records the source changes and compatibility limits.
- Records the simulation, build, timing, and hardware tests.
- Supplies the test evidence for an upstream review.

### `SGB.qsf`

- Changes the Quartus fitter seed from 1 to 2.
- Uses a fitter result that passes all timing constraints.

## 12. Simulation and static checks

### 12.1 Reproduction commands

Use these commands from the repository root:

```sh
iverilog -g2012 -s sgb_commander_tb \
  -o /tmp/sgb_commander_tb \
  rtl/sgb_commander.sv sim/sgb_commander_tb.sv
vvp /tmp/sgb_commander_tb

verilator --lint-only --Wall -Wno-DECLFILENAME \
  rtl/sgb_commander.sv sim/sgb_commander_tb.sv

git diff --check
```

The simulation result is `PASS: sgb_commander`.

Verilator reports no lint fault with the stated command. `git diff --check` reports no whitespace fault.

### 12.2 Testbench coverage

The self-checking testbench verifies these cases:

- SNES mode passes all 12 inputs through.
- X stays X in Commander mode.
- R becomes L and R in Commander mode.
- Y is consumed as a Speed trigger.
- L is consumed as a Mute trigger.
- An eight-clock manual probe does not advance a command.
- The ninth clock marks an automatic read.
- The exact three-mode Speed sequence is correct.
- The exact Dash-enabled Speed sequence is correct.
- The exact Mute sequence is correct.
- A mode change aborts a command safely.
- SNES mode restores normal Y and L operation.
- A trigger before the ninth clock cannot change the stored current word.
- A trigger after the ninth clock waits for the next full read.

The two boundary tests check the most important timing risk.

## 13. Quartus build and timing checks

### 13.1 Need for a seed check

The feature adds logic near the controller path. A complete Quartus build was necessary.

Quartus placement can give different timing for different fitter seeds. Therefore, the work compared multiple seeds.

### 13.2 Seed results

| Seed | HDMI worst slack | Tight core worst slack | Result |
| ---: | ---: | ---: | --- |
| 1 | Negative | Not limiting | Rejected because of an HDMI timing failure |
| 2 | +0.295 ns | +0.657 ns | Pass and selected |
| 3 | +0.404 ns | +0.116 ns | Pass |
| 4 | Not limiting | -0.368 ns | Rejected because of a core timing failure |
| 5 | -0.108 ns | Not limiting | Rejected because of an HDMI timing failure |

Seed 2 gives positive slack on HDMI and the tight core path. It gives more core margin than seed 3.

All seed 2 timing groups have zero total negative slack. The final timing review found no negative slack.

The seed change does not change the functional RTL. It selects a placement that meets the timing requirements.

## 14. Final build file

The selected build file is:

```text
SGB_20260815_Commander.rbf
```

Its SHA-256 value is:

```text
5523535b04c40aeb16057abfa760ba719fb1fbb206095216736e52d7c7e00a04
```

The same file was copied to the MiSTer target:

```text
/media/fat/_Console/SGB_20260815_Commander.rbf
```

The build output, local staging copy, and MiSTer copy had the same SHA-256 value.

The hardware tests used this exact seed 2 file.

### 14.1 Build trace

The seed sweep used one source revision for all matrix jobs. Each job changed only the fitter seed in `SGB.qsf`.

The seed 2 job made the final test RBF. The final proposal branch also sets seed 2 in `SGB.qsf`.

The temporary matrix workflow does not supply a Quartus source file. It was removed from the proposal branch after the build.

The final functional RTL and project assignments agree with the tested seed 2 job.

## 15. Hardware test method

The test used a physical MiSTer system. The procedure exercised the final RBF from the MiSTer console menu.

A temporary virtual controller supplied repeatable button and OSD input. Physical controller interfaces remained available for final restoration.

The general procedure was:

1. Copy the final RBF to the MiSTer SD card.
2. Calculate the SHA-256 value on the MiSTer.
3. Compare it with the build value.
4. Start the final RBF.
5. Select the required BIOS and video standard.
6. Select `SGB Commander` in the OSD.
7. Send one Commander input at a time.
8. Measure or inspect the applicable system result.
9. Repeat the test for each required BIOS.
10. Remove temporary test files and controller services.

The speed test used the BIOS modulo frame counter. Samples used approximately one-second observation periods.

Small Normal differences, such as 59 through 62, come from the sample boundary. They do not indicate a speed-state difference.

## 16. Hardware test results

### 16.1 SGB2 three-mode Speed

| Speed state | Observed counter change |
| --- | ---: |
| Normal | 61 |
| Super Slow | 34 |
| Slow | 44 |
| Normal after the full cycle | 59 |

The sequence order and all three speed levels were correct.

### 16.2 SGB2 four-mode Speed with Dash

| Speed state | Observed counter change |
| --- | ---: |
| Normal | 62 |
| Dash | 76 |
| Super Slow | 33 |
| Slow | 43 |
| Normal after the full cycle | 59 |

The measured Dash ratio is close to 1.25. The result agrees with the expected 25-percent speed increase.

### 16.3 Speed with all BIOS revisions

| BIOS | Initial Normal | Next Super Slow | Result |
| --- | ---: | ---: | --- |
| SGB1 v1.0 | 61 | 34 | Pass |
| SGB1 v1.1 | 61 | 34 | Pass |
| SGB1 World Rev 2 | 61 | 34 | Pass |
| SGB2 | 61 to 62 | 33 to 34 | Pass |

SGB2 also received the complete three-mode and four-mode cycle tests shown above.

### 16.4 PAL test

The PAL test used SGB1 World Rev 2. The live core status confirmed the PAL selection.

Normal measured 61. Super Slow measured 34. The PAL result passed.

### 16.5 Mute test

The Mute test used SGB2. The OSD enabled save-state data for the internal state check.

The BIOS work-RAM value at `$015F` changed as follows:

```text
0 -> 1 -> 0
```

The first L press enabled mute. The second L press restored sound.

Fresh save-state times confirmed that each value came from the current test.

### 16.6 Window test

The Window test used R in Commander mode. The first R press opened the BIOS window.

The next R press closed the window. The result was visible on the MiSTer display.

### 16.7 Color test

The Color test used Donkey Kong during stable game operation. The initial selected set showed 11 colors.

The first X press selected the original title set. This set showed 5 colors.

The second X press restored the 11-color selected set. Visible captures confirmed both changes.

Boot-screen samples were not accepted as Color evidence. The final test used stable game operation.

## 17. Test corrections during the work

Some early tests used an incomplete SGB1 start period. These samples did not give reliable BIOS results.

The test procedure was corrected to include the full SGB1 start period. All reported SGB1 results use the corrected procedure.

An early seed 1 build had a negative HDMI timing result. It was not used as the final build.

The seed sweep found passing and failing placements. Seed 2 was selected from measured timing results.

Temporary build files with rejected names were removed from the MiSTer. Only the final Commander RBF was kept.

## 18. Acceptance results

| Requirement | Evidence | Result |
| --- | --- | --- |
| No extra input assignments | Uses standard Y, X, R, and L map | Pass |
| Normal SNES mode | Full input pass-through simulation | Pass |
| Commander button roles | Simulation and hardware tests | Pass |
| Authentic BIOS command path | BIOS table sequences | Pass |
| Three Speed modes | SGB2 full-cycle measurement | Pass |
| Hidden Dash mode | SGB2 four-mode full-cycle measurement | Pass |
| Mute toggle | Work-RAM value `0 -> 1 -> 0` | Pass |
| Window toggle | Visible open and close test | Pass |
| Color toggle | Donkey Kong palette test | Pass |
| All tested SGB BIOS revisions | Four-revision speed test | Pass |
| PAL and NTSC read timing | Hardware tests in both settings | Pass |
| Multitap probe isolation | Self-checking simulation | Pass |
| Port 1 behavior | RTL connection and hardware operation | Pass |
| Port 2 unchanged | RTL scope review | Pass |
| Static timing | Seed 2 has positive slack and zero TNS | Pass |
| Final file identity | SHA-256 comparison | Pass |

## 19. Limits and non-goals

- Commander translation applies only to the mapped controller on port 1.
- Raw SNAC serial data does not receive Commander translation.
- The work does not electrically emulate a physical Commander controller.
- The work reproduces the controller words that the BIOS receives.
- Color output depends on the game and the current BIOS palette state.
- Dash can cause unwanted audio or video output, as on original hardware.
- The work does not claim that every Game Boy ROM received an individual test.
- The work does not change port 2 or multitap behavior.
- The work does not add new controller assignments.

## 20. Final MiSTer state and cleanup

After the tests, the MiSTer used these safe settings:

| Setting | Final value |
| --- | --- |
| Controller | SGB Commander |
| Commander Speed | 3 modes |
| Video standard | NTSC |
| SNAC | Off |
| Save state to SD | Off |

The final raw status bytes were:

```text
00 80 00 10 00 00 00 00
```

These bytes confirmed Commander mode, the three-mode cycle, NTSC, and no SNAC input.

Both physical controller devices were returned to their normal `hid-generic` driver.

The test device identifiers were:

- `0003:054C:0CDA.0005`
- `0003:0CA3:0024.000C`

The temporary virtual controller service was stopped. Temporary ROM, input-map, save-state, and capture files were removed.

The removed QA paths included:

- `/media/fat/games/SGB-QA`
- `/media/fat/config/inputs/input_cafe_5342_v3.map`
- `/media/fat/savestates/SGB/sgb_speed_test_1.ss`

Rejected test RBF files were removed. The final `SGB_20260815_Commander.rbf` file stayed in the Console directory.

The removed test builds were:

- `SGB_20260814_Commander.rbf`
- `SGB_20260814_Latch.rbf`

The final cleanup check passed.

## 21. Submission state

The proposal branch contains one focused commit above the base revision.

The commit includes the RTL, OSD integration, testbench, fitter seed, user instructions, and engineering record.

All proposal documentation and source comments use ASD-STE100 Simplified Technical English.

The branch comparison is:

<https://github.com/MiSTer-devel/SGB_MiSTer/compare/main...andrewkendall:sgb-commander-proposal?expand=1>

No upstream pull request was open when this record was prepared.

## 22. Conclusion

The project gives the MiSTer SGB core an accurate HORI SGB Commander mode.

The user selects a controller type instead of making extra button assignments. Standard controller buttons then receive the correct Commander roles.

Speed and Mute use the original BIOS command sequences. Window and Color use the original BIOS input paths.

The design distinguishes short BIOS probes from full controller reads. It also keeps the next command word stable before the next latch.

Simulation, lint, full Quartus builds, timing review, and physical MiSTer tests passed.

The tests include all four tested SGB BIOS revisions, SGB2 full cycles, PAL operation, and all four Commander functions.

## 23. References

- [Game Boy Museum: HORI SGB Commander](https://www.gameboymuseum.com/game-boy-hardware-guide/accessories/hsd-07/hori-sgb-commander)
- [`README.md`](README.md)
- [`SGB.sv`](SGB.sv)
- [`rtl/sgb_commander.sv`](rtl/sgb_commander.sv)
- [`sim/sgb_commander_tb.sv`](sim/sgb_commander_tb.sv)

## 24. Language note

This record uses ASD-STE100 Simplified Technical English principles.

Sentences are short. Instructions use one action per step. Technical names have one meaning in this record.

The technical names include BIOS, Commander, Dash, HDMI, MiSTer, OSD, PAL, RBF, RTL, SGB, SNAC, and WNS.
