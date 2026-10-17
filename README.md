# Driver-YL-3
Verilog driver for 8-digit 7-segment display modules built on two daisy-chained
74HC595 shift registers, such as the YL-3. The included top level targets the
Tang Nano 9K and bounces "HELLO" across the display.

## Files

- `seg7x8_595.v` - display driver: continuously scans the 8 digits from 64 bits of ASCII
- `top.v` - "HELLO" demo top level (power-on reset + animation), defaults for the Tang Nano 9K
- `tangnano9k.cst` - Tang Nano 9K pin constraints
- `mojo_top.v` - Mojo V3 top level: wraps `top.v` with 50 MHz timing
- `mojo.ucf` - Mojo V3 pin constraints
- `yl3.ino/` - equivalent Arduino sketch

## Wiring (Tang Nano 9K)

| Module | FPGA pin |
|--------|----------|
| RCK    | 70       |
| SCK    | 71       |
| DIO    | 72       |
| VCC    | 3.3 V    |
| GND    | GND      |

S1 (pin 3) resets the design.

## Wiring (Mojo V3)

| Module | FPGA pin |
|--------|----------|
| RCK    | P74      |
| SCK    | P66      |
| DIO    | P57      |
| VCC    | 3.3 V    |
| GND    | GND      |

## Arduino

`yl3.ino/yl3.ino.ino` drives the same module from an Arduino: DIO on pin 2,
SCK on pin 4, RCK on pin 7. It sends the segment byte first, matching
`SEG_FIRST = 1`.

## Module variants

These modules aren't all wired the same way. `seg7x8_595` has parameters for
the differences:

| Parameter   | Meaning |
|-------------|---------|
| `SEG_FIRST` | 0 = shift `{digit, segments}`, 1 = shift `{segments, digit}` |
| `DIGIT_XOR` | XORed into the digit index; 4 swaps the two 4-digit halves |
| `DIGIT_INV` | 1 = digit select is active low |
| `SEG_INV`   | 1 = segments are active high |
| `BIT_DIV`   | CLK cycles per driver tick (sets the shift clock speed) |

`top.v` and `mojo_top.v` default to `SEG_FIRST = 1` and `DIGIT_XOR = 4` for the
module this was tested with. The original YL-3 used `SEG_FIRST = 0` and
`DIGIT_XOR = 0`.

## Driver notes

- Only one of SCK, RCK and DIO changes per driver tick (DIO changes while SCK is
  low, RCK rises after SCK has settled). Changing them together let edges couple
  between jumper wires and fake extra shift clocks.
- `top.v` holds the design in reset for ~2.4 ms after configuration, so it starts
  without pressing reset.

## Build

With the open source toolchain ([OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build)):

```sh
yosys -p "read_verilog top.v seg7x8_595.v; synth_gowin -top top -json Driver-YL-3.json"
nextpnr-himbaechel --json Driver-YL-3.json --write Driver-YL-3_pnr.json \
  --device GW1NR-LV9QN88PC6/I5 --vopt family=GW1N-9C --vopt cst=tangnano9k.cst
gowin_pack -d GW1N-9C -o Driver-YL-3.fs Driver-YL-3_pnr.json
openFPGALoader -b tangnano9k Driver-YL-3.fs      # add -f to write to flash
```

For the Mojo V3, add `mojo_top.v`, `top.v`, `seg7x8_595.v` and `mojo.ucf` to an
ISE project for the XC6SLX9 with `mojo_top` as the top module.

Simulate with Icarus Verilog:

```sh
iverilog -Wall -g2012 -o /tmp/yl3_sim top.v seg7x8_595.v
```

[See it in action!](https://www.youtube.com/watch?v=TBHh_up2X0k)
