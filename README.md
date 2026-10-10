# Driver-YL-3
Verilog code to run the YL-3 8 digit 7 segment display that uses two 74HC595 shift registers.

The digit scan index now wraps after all eight digits (0-7), fixing the off-by-one
that skipped the last digit and caused the display to repeat part of its scan.
The shift-register RTL also compiles with the output declarations corrected.

Compile the RTL with Icarus Verilog:

```sh
iverilog -Wall -g2012 -o /tmp/yl3_sim yl3.v yl3_shiftregister.v mojo_top.v
```

[See it in action!](https://www.youtube.com/watch?v=TBHh_up2X0k)

[EDA Playground](http://www.edaplayground.com/x/GTY)
