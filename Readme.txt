Shooting Stars

A mini game for the Commodore C64 by Jan Klingel, (C) 2020. The game in version 2.3 is using a single interrupt driven sprite but has the title screen separate to keep the code simple and tight. The keyboard is queried by using a raster IRQ on raster line 10, which makes the game very responsive.

The goal of the game is to drive off the screen with the car either to the left or to the right. To do this successfully, at least 20 holes in the street caused by the shooting stars must be fixed, only then can the driver drive off to lunch.

The amount of repaired holes is shown as a score in the right upper corner. As soon as 20 holes are repaired, the letter "L" (for lunchbreak) appears in the left upper corner.

Written in 6502/6510 assembly language. Compatible with Turbo Assembler Pro/Turbo Macro Pro v1.2.

Usage:

Move car with H-left and K-right, avoid the shooting stars.
Repair a hole in the ground with G-left and L-right. 

Memory Table:

+-----------+------------------------------------------------+
+ Zero Page + Content                                        + 
+-----------+------------------------------------------------+
+ $fb       + Current star position, low byte                +
+-----------+------------------------------------------------+
+ $fc       + Current star position, high byte               +
+-----------+------------------------------------------------+
+ $fd       + Current car position, low byte ($07c0-$07e8)   +
+-----------+------------------------------------------------+
+ $fe       + Current car position, high byte                +
+-----------+------------------------------------------------+

+-----------+------------------------------------------------+
+ Address   + Content                                        +
+-----------+------------------------------------------------+
+ $02a7     + First star position, low byte                  +
+-----------+------------------------------------------------+
+ $02a8     + First star position, high byte                 + 
+-----------+------------------------------------------------+
+ $0313     + Speed of the game. Higher value is slower      +
+-----------+------------------------------------------------+
+ $0334     + Jump into main game, 3 bytes                   +
+-----------+------------------------------------------------+
+ $0340     + Sprite 0 (the car), block 13, ends at $037e    +
+-----------+------------------------------------------------+
+ $0801     + Begin of BASIC code, ends at $080d             +
+-----------+------------------------------------------------+
+ $080e     + Begin of IRQ service routine, ends at $0851    +
+-----------+------------------------------------------------+
+ $0853     + Begin of game main code, ends at $0f93         +
+-----------+------------------------------------------------+

Please note that TMP v1.2 loads at $8000 and ends at $c807 (73 blocks of 256 bytes). When the source code is loaded into TMP, it fills memory from $7fff back to $56fd.  

V2.3, 27.12.2020