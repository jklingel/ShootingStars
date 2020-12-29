; Shooting Stars
; Mini Game (c) Jan Klingel 2020
; Version 27.12.2020;V2.3
; Written for MOS 6510 Commodore 64
; using Turbo Macro Pro v1.2

         *= $0334
auto_start
         ; This is just an early jump
         ; into the main game code. TMP
         ; does not like code parts
         ; being out of order address-
         ; wise. This leads to very long
         ; compile times and unclosed
         ; files.
         jmp game
;---------------------------------------
         *= $0340  ; sprite block 13
car_sprite
         ; This is the green car we can
         ; drive around.
         .byte 0,0,0
         .byte 0,0,0
         .byte 0,0,0
         .byte 0,0,0
         .byte 0,0,0
         .byte 0,0,0
         .byte 0,60,0
         .byte 0,66,0
         .byte 0,129,0
         .byte 1,0,128
         .byte 2,128,64
         .byte 30,64,120
         .byte 35,255,196
         .byte 65,0,130
         .byte 128,96,1
         .byte 152,64,25
         .byte 164,0,37
         .byte 218,0,91
         .byte 37,0,164
         .byte 37,255,164
         .byte 24,0,24
;---------------------------------------
         *= $0801
         ; The BASIC line to start the
         ; game with
         .byte $0c,$08,$0a,$00,$9e,$20
         .byte $32,$31,$33,$31,$00,$00
         .byte $00
;---------------------------------------
         *= $080e
rasterirq
         ; The interrupt routine...
         ; Check if VIC triggered an
         ; interrupt (bit 0 of $d019 set
         ; means the raster compare is
         ; the source of the IRQ)
         .block
         lda #%00000001
         bit intflag
         bmi read_keyb
         ; Load interrupt control reg,
         ; this will clear all inter-
         ; rupts
         lda $dc0d
         cli
         ; Jump to entry point of normal
         ; interrupt routine if no
         ; raster compare IRQ triggered
         jmp $ea31

read_keyb
         ; Clear all interrupts first
         lda #15
         sta intflag

         ; Read the keyboard using
         ; kernal function for pre-
         ; defined keys.
         jsr $ffe4 ; getin
         cmp #$48  ; key "H" pressed
         beq car_left
         cmp #$4b  ; key "K" pressed
         beq car_right
         cmp #$47  ; key "G" pressed
         beq rep_left
         cmp #$4c  ; key "L" pressed
         beq rep_right
         jmp end

car_left
         jsr move_car_left
         jmp end
car_right
         jsr move_car_right
         jmp end
rep_left
         jsr repair_left
         jmp end
rep_right
         jsr repair_right
end
         pla
         tay
         pla
         tax
         pla
         rti
         .bend
;---------------------------------------
         *= $0853
game
         ; The game

bstar    = 90      ; Chr for the bstars
star     = $2a     ; Chr for the star
starpos  = $fb     ; Position of star
startpos = $02a7   ; First pos of star
ground   = $66     ; Chr for the ground
sid      = $d400   ; SID-II voice 1
sprite0x = $d000   ; Sprite 0 pos x
spritexm = $d010   ; Sprite pos x MSB
raster   = $d012   ; Current raster line
intctrl  = $d011   ; Interrupt ctrl reg
intflag  = $d019   ; Interrupt flag reg
speed    = $0313   ; Speed of the game
         ; Higher value means slower

         ; 3 lines for the help screen
cborder  = 6       ; blue
cbackgr  = 6       ; blue
ctext    = 5       ; green

         jsr help_screen
         jsr init_sid
         jsr init_keyb
         jsr init_random
         jsr init_irq
         jsr init_screen
         jsr init_ground
         jsr init_sprite
         jsr print_score
main
         jsr print_bstars
         jsr new_star
         jsr starsound
         jsr print_star
         jsr delete_star
         jmp main
;---------------------------------------
help_screen
         ; Lower/uppercase chr set
         lda $d018
         ora #%00000010
         sta $d018

         lda #cborder ; set color
         sta $d020
         lda #cbackgr
         sta $d021

         lda #147
         jsr $ffd2 ; clear screen

         clc
         ldx #0    ; y coordinate
         ldy #0    ; x coordinate
         jsr $e50a ; plot, pos cursor
         lda #ctext
         sta $0286 ; textcolor
         lda #<help_scr0
         ldy #>help_scr0
         jsr $ab1e ; print string
         lda #<help_scr1
         ldy #>help_scr1
         jsr $ab1e ; print string
         lda #<help_scr2
         ldy #>help_scr2
         jsr $ab1e
         lda #<help_scr3
         ldy #>help_scr3
         jsr $ab1e
         lda #<help_scr4
         ldy #>help_scr4
         jsr $ab1e
         lda #0
         sta $c6   ; clear keyb buffer
getkey
         jsr $ffe4 ; getin
         cmp #$20  ; wait for space key
         bne getkey

         ; Uppercase/graphic chrs
         lda $d018
         and #%11111101
         sta $d018

         rts
;---------------------------------------
print_score
         ; Print the score in the right
         ; upper corner. Every repaired
         ; hole adds a one to the score
         .block
         lda #4    ; purple
         sta $0286 ; set textcolor

         clc       ; needed by plot
         ldx #0    ; y coordinate
         ldy #30   ; x coordinate
         jsr $e50a ; plot, pos cursor
         lda #<str_score
         ldy #>str_score
         jsr $ab1e ; print string

         ldx score
         lda score+1
         jsr $bdcd ; linprt

         lda score
         cmp #20   ; min score is 20
         bne end
         lda #1
         sta flag
         lda #12   ; "L" lunchbreak
         sta $0400
         lda #4
         sta $d800
end
         rts
         .bend
;---------------------------------------
print_bstars
         ; Print some stars on the back-
         ; ground sky
         .block
         ldx #0    ; index for zero page
         ldy #0    ; index for startable
loop

         lda bstartable,y
         cmp $ff   ; check end of table
         beq end
         sta $fc   ; MSB of star address
         iny
         lda bstartable,y
         sta $fb   ; LSB of star address
         lda #bstar
         sta ($fb,x)
         iny
         bpl loop  ; branch always
end
         rts
         .bend
;---------------------------------------
new_star
         ; Define the start position of
         ; a new shooting star.
         .block
         clc
         lda $d41b  ; get random col no
         ; Make sure that random no is
         ; not greater than 39.
         lsr a      ; divide accu by 2
         lsr a      ; divide accu by 2
         tax        ; secure accu
         sbc #23    ; subtract 23
         bcs skip   ; accu was < 39
         txa        ; accu was >= 39
skip
         clc
         adc #39    ; move to 2nd line
         sta starpos
         sta startpos
         lda #$04   ; high byte of scr
         sta starpos+1
         sta startpos+1
         rts
         .bend
;---------------------------------------
starsound
         ; Produce the sound of falling
         ; shooting stars.
         lda #15
         sta sid+24 ; volume
         lda #0*16+5
         sta sid+5  ; attack+decay
         lda #15*16+10
         sta sid+6  ; sustain+release
         ldx #200
         sta sid    ; freq LSB
         ldx #2
         sta sid+1  ; freq MSB
         lda #1+128
         sta sid+4  ; noise gen on
         lda #128
         sta sid+4  ; noise gen off
         rts
;---------------------------------------
print_star
         ; Draw the falling shooting
         ; star on the screen for x rows
         ; and include collision detec-
         ; tion with the car.
         .block
         ldy #$00  ; offset
         ldx #24   ; 24 rows
loop
         lda #star
         sta (starpos),y
         lda starpos
         clc       ; Detect collision
         lda $d01f ; VIC IRQ register
         lsr a
         bcs game_over
         lda #3
         sta speed
         jsr wait
         lda #40   ; 40 columns
         clc
         adc starpos
         sta starpos
         bcc skip
         inc starpos+1
skip
         dex
         bne loop
         rts
         .bend
;---------------------------------------
game_over
         ; The shooting star hit the
         ; car...
         ; Delete sprite 0
         .block
         lda $d015
         and #%11111110
         sta $d015

         ; Display game over
         ; message and exit after user
         ; pressed the space bar.
         clc
         ldx #15   ; y coordinate
         ldy #8    ; x coordinate
         jsr $e50a ; plot, pos cursor
         lda #2    ; red
         sta $0286 ; textcolor
         lda #<gameover
         ldy #>gameover
         jsr $ab1e ; print string
         lda #0
         sta $c6   ; clear keyb buffer
getkey
         jsr $ffe4 ; getin
         cmp #$20
         bne getkey
         brk
         .bend
;---------------------------------------
delete_star
         ; When the shooting star is at
         ; bottom of the screen, delete
         ; its trace top to bottom.
         .block
         lda startpos
         sta starpos
         lda startpos+1
         sta starpos+1
         ldy #0    ; offset
         ldx #24   ; 24 rows
loop
         lda #$20  ; space chr
         sta (starpos),y
         lda #1
         sta speed
         jsr wait
         lda #$28  ; 40 columns
         clc
         adc starpos
         sta starpos
         bcc skip
         inc starpos+1
skip
         dex
         bne loop
         rts
         .bend
;---------------------------------------
move_car_left
         ; Calculate column of car on
         ; the text screen
         .block
         lda sprite0x
         jsr div8
         sbc #3
         tax
         lda spritexm
         lsr a     ; check MSB bit 0
         bcc check4hole
         txa
         clc
         adc #32   ; right half screen
         tax
check4hole
         lda $07c0,x
         ; Check for hole in the ground
         cmp #$20
         beq end

         ; Move sprite 0 y positions
         ; to the left
         ldy #8
loop
         ldx sprite0x
         cpx #0
         beq msb_off
         jmp skip
msb_off
         lda spritexm
         and #%11111110
         sta spritexm
skip
         dex
         stx sprite0x
         dey
         bne loop

         ; Check if car moved to the
         ; left border.
         cpx #4
         beq test_msb
         jmp end
test_msb
         lda spritexm
         lsr a     ; check for MSB bit 0
         bcc check_flag
         jmp end
check_flag
         lda flag
         cmp #1
         beq game_won
         jmp game_over
end
         rts
         .bend
;---------------------------------------
move_car_right
         ; Calculate column of car on
         ; the text screen
         .block
         lda sprite0x
         jsr div8
         tax
         lda spritexm
         lsr a     ; check MSB bit 0
         bcc check4hole
         txa
         clc
         adc #32   ; right half screen
         tax
check4hole
         lda $07c0,x
         ; Check for hole in the ground
         cmp #$20
         beq end

         ; Move sprite 0 y positions
         ; to the right
         ldy #8
loop
         ldx sprite0x
         cpx #255
         beq msb_on
         jmp skip
msb_on
         lda spritexm
         ora #%00000001
         sta spritexm
skip
         inx
         stx sprite0x
         dey
         bne loop

         ; Check if car moved to the
         ; right border.
         cpx #84
         beq test_msb
         jmp end
test_msb
         lda spritexm
         lsr a     ; check for MSB bit 0
         bcs check_flag
         jmp end
check_flag
         lda flag
         cmp #1
         beq game_won
         jmp game_over
end
         rts
         .bend
;---------------------------------------
div8
; Divide accu by 8, store result in accu
         .block
         sec
         ldy #255
loop
         iny
         sbc #8
         bcs loop
         adc #8
         tya
         rts
         .bend
;---------------------------------------
game_won
         ; The car moved all the way
         ; to the border and the
         ; player won the game. Exit the
         ; game after the user pressed
         ; the space bar.
         .block
         clc
         ldx #15   ; y coordinate
         ldy #9    ; x coordinate
         jsr $e50a ; plot, pos cursor
         lda #5    ; green
         sta $0286 ; textcolor
         lda #<congrats
         ldy #>congrats
         jsr $ab1e ; print string
         lda #0
         sta $c6   ; clear keyb buffer
getkey
         jsr $ffe4 ; getin
         cmp #$20  ; wait for space key
         bne getkey
         brk
         .bend
;---------------------------------------
repair_left
         ; Repair a hole in the ground
         ; to the car's left.
         .block
         lda sprite0x
         jsr div8
         sbc #3
         tax
         lda spritexm
         lsr a     ; check MSB bit 0
         bcc repair
         txa
         clc
         adc #32   ; right half screen
         tax
repair
         lda $07c0,x
         ; Check for hole in the ground
         cmp #$20  ; space
         bne end

         lda #ground
         sta $07c0,x

         ; Increment the score
         clc
         lda score
         adc #1
         sta score
         bcc done
         lda score+1
         adc #0
         sta score+1
done

         jsr print_score
end
         rts
         .bend
;---------------------------------------
repair_right
         ; Repair a hole in the ground
         ; to the car's right.
         .block
         lda sprite0x
         jsr div8
         tax
         lda spritexm
         lsr a     ; check MSB bit 0
         bcc repair
         txa
         clc
         adc #32   ; right half screen
         tax
repair
         lda $07c0,x
         ; Check for hole in the ground
         cmp #$20  ; space
         bne end

         lda #ground
         sta $07c0,x

         ; Increment the score
         clc
         lda score
         adc #1
         sta score
         bcc done
         lda score+1
         adc #0
         sta score+1
done
         jsr print_score
end
         rts
         .bend
;---------------------------------------
init_irq
         ; Tell the CPU where to jump to
         ; when raster IRQ triggers:
         ; address rasterirq
         sei       ; disable interrupts
         lda #<rasterirq
         sta $0314 ; RAM IRQ vector
         lda #>rasterirq
         sta $0315 ; high byte
         lda #10   ; trigger if rast=10
         sta raster
         ; Clear bit 8 of raster reg
         lda intctrl
         and #%01111111
         sta intctrl
         ; Enable raster compare IRQ
         lda $d01a
         ora #%00000001
         sta $d01a
         cli       ; enable interrupts
         rts
;---------------------------------------
init_screen
         ; Set screen to text mode
         lda $d011
         and #%11011111
         sta $d011

         ; Set textcolor
         lda #1    ; white
         sta $0286 ; textcolor

         ; Make sure we are in default
         ; uppercase/graphics mode
         lda $d018
         and #%11111101
         sta $d018

         ; Set the background and
         ; border color to black, then
         ; clear the screen
         lda #$00  ; black
         sta $d021 ; background color
         sta $d020 ; border color

         ; Clear the screen
         lda #4
         sta $0288 ; set start of screen
         jsr $e544 ; init SLLT, clearscr

         lda #15
         sta $d019 ; clear interrupts

         lda #0    ; reset score
         sta score
         sta score+1

         lda #0    ; reset flag
         sta flag
         rts
;---------------------------------------
init_ground
         ; Draw the ground on the last
         ; screen line
         .block
groundpos = $fb    ; borrowed
         lda #$c0  ; last screen row LB
         sta groundpos
         lda #7    ; last screen row HB
         sta groundpos+1
         ldy #0
         lda #ground ; chr for ground
loop
         sta (groundpos),y
         iny
         cpy #41   ; last column
         bne loop
         lda #$c0  ; last col row LB
         sta groundpos
         lda #$db  ; last col row HB
         sta groundpos+1
         ldy #0
         lda #9    ; brown
loop2
         sta (groundpos),y
         iny
         cpy #41   ; last column
         bne loop2
         rts
         .bend
;---------------------------------------
wait
         ; Implement a wait func by
         ; counting VIC-II frames. 50
         ; PAL frames equal to 1s.

         ldy $0313
wait_1
         ; Copy bit 7 of $d011 into
         ; negative flag. Loop back
         ; if negative flag is cleared
         ; (0). Bit 7 is bit 8 of
         ; $d012 raster counter.
         bit $d011
         bpl wait_1
wait_2
         ; Copy bit 7 of $d011 into
         ; negative flag. Loop back
         ; if negative flag is set.
         bit $d011
         bmi wait_2
         dey
         bne wait_1
         rts
;---------------------------------------
init_random
         ; Get random value from 0-255
         ; by loading $d41b into accu.
         ; For this the SID has to be
         ; prepared first.

         lda #$ff  ; max freq value
         sta $d40e ; voice 3 freq lb
         sta $d40f ; voice 3 freq hb
         lda #$80  ; noise wave,gate off
         sta $d412 ; voice 3 control reg
         rts
;---------------------------------------
init_sid
         ; Set all SID registers to zero
         .block
         lda #0
         ldx #$00
loop
         sta sid,x
         inx
         cpx #29
         bne loop
         rts
         .bend
;---------------------------------------
init_keyb
         ; Set the keyboard repeat mode
         ; to off and the keyboard
         ; buffer size to 1. Then clear
         ; the buffer.
         ;lda #0
         ;sta $dc03 ; CIA port A r-only
         ;lda #$ff
         ;sta $dc02 ; CIA port B r/w
         lda #128
         sta $028a ; keyb repeat mode
         lda #1
         sta $0289 ; keyb buffer size
         lda #0
         sta $c6   ; clear keyb buffer
         rts
;---------------------------------------
init_sprite
         ; Initialize sprite 0, set its
         ; color, position it on the
         ; screen and switch it on.
         lda #5    ; green
         sta $d027 ; sprite 0 color
         lda #13   ; sprite block 13
         sta $07f8 ; sprite 0 pointer
         lda #172  ; cars middle positon
         sta sprite0x
         lda spritexm
         and #%01111110 ; MSB bit 0 off
         sta spritexm
         lda #221
         sta $d001 ; sprite 0 y pos
         lda $d015
         ora #%00000001
         sta $d015 ; switch sprite 0 on
         rts
;---------------------------------------
score    .byte 0,0 ; Counting repairs

str_score .null "score:"

flag     .byte 0   ; Flag for repairs

congrats .text "***********************"
         .byte $0d
         .text "         "
         .text "***    game won!    ***"
         .byte $0d
         .text "         "
         .text "* press space to exit *"
         .byte $0d
         .text "         "
         .null "***********************"

gameover .text "***********************"
         .byte $0d
         .text "        "
         .text "***    game over!   ***"
         .byte $0d
         .text "        "
         .text "* press space to exit *"
         .byte $0d
         .text "        "
         .null "***********************"

bstartable         ; order LSB, MSB!
         .word $bb04,$3504
         .word $5104,$7304
         .word $8904,$a804
         .word $d804,$e904
         .word $2205,$3805
         .word $4505,$5205
         .word $8c05,$9805
         .word $a405,$0a06
         .word $ffff

help_scr0
         .byte 158
         .text "         "
         .null "*** Shooting Stars ***"
help_scr1
         .byte 153,$0d,$0d
         .text "Shooting stars are "
         .text "coming down the sky, "
         .text "creating little "
         .text "craters on the street. "
         .byte $0d
         .text "Do not let the shooting"
         .null " stars hit your  car! "
help_scr2
         .byte $0d,$0d
         .text "When you reach a hole "
         .text "in the street, re-pair "
         .text "it quickly so that in "
         .text "the morning  other "
         .text "cars may pass without "
         .null "creating an accident."
help_scr3
         .byte $0d,$0d
         .text "Your goal is to repair "
         .text "at least 20 holes, "
         .text "after that you are "
         .text "free to take your  "
         .text "lunch break by driving "
         .text "off the screen tothe "
         .null "left or right."
help_scr4
         .byte $0d,$0d
         .text "Use H to drive the car "
         .text "to the left, K to"
         .text "drive to the right. "
         .text "When you approached a "
         .text "hole, use G to repair "
         .text "it on the left  side of"
         .text " your car and L if it "
         .text "is on the  right side."
         .byte $0d,$0d,$12
         .text "Press space to begin"
         .byte 146,0
;---------------------------------------
         .end

