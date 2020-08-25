ShootingStars

A simple (and crude) demo game for the Commodore C64 by Jan Klingel, (C) 2020. The game in version 1 is using no sprites and no title screen to keep the code simple and tight.

The goal of the game is to drive off the screen with the tank either to the left or to the right.

Written in 6502/6510 assembly language. Compatible with Turbo Assembler Pro/Turbo Macro Pro v1.2.

Usage:

Move tank with H-left and K-left, avoid the shooting stars.
Repair a hole in the ground with G-left and L-right. 

Memory Table:

+-----------+------------------------------------------------+
+ Zero Page + Current star position, low byte ($0400-$07e8)  + 
+-----------+------------------------------------------------+
+ $fb       + Current star position, high byte               +
+-----------+------------------------------------------------+
+ $fc       + Current car position, low byte ($07c0-$07e8)   +
+-----------+------------------------------------------------+
+ $fd       + Current car position, high byte                +
+-----------+------------------------------------------------+
+ $2a7      + First star position, low byte ($0400-$0428)    +
+-----------+------------------------------------------------+
+ §2a8      + First star position, high byte                 + 
+-----------+------------------------------------------------+