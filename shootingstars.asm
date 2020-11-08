; Game (c) Jan Klingel 2020
; Version 25.08.2020;09:12
; Written for MOS 6510 Commodore 64
; using Turbo Macro Pro v1.2

         *= $0801
         .byte $0c,$08,$0a,$00,$9e,$20
         .byte $34,$30,$39,$36,$00,$00
         .byte $00

         *= $1000

starpos  = $fb     ; Position of star
startpos = $02a7   ; First pos of star
tankpos  = $fd     ; Position of tank
tank     = 209     ; Chr for tank
ground   = $66     ; Chr for the ground
sid      = $d400   ; SID-II voice 1
;---------------------------------------
         jsr init_screen
         jsr init_sid
         jsr init_keyb
         jsr init_random
         jsr init_ground
         jsr init_tank
main
         jsr read_keyb
         jsr new_star
         jsr starsound
         jsr print_star
         jsr delete_star
         jmp main

;---------------------------------------
read_keyb
         ; Read the keyboard using
         ; kernal function for pre-
         ; defined keys.
         .block
         jsr $ffe4 ; getin
         cmp #$48  ; key "H" pressed
         beq tank_left
         cmp #$4b  ; key "K" pressed
         beq tank_right
         cmp #$47  ; key "G" pressed
         beq rep_left
         cmp #$4c  ; key "L" pressed
         beq rep_right
         rts

tank_left
         jsr move_tank_left
         jmp main
tank_right
         jsr move_tank_right
         jmp main
rep_left
         jsr repair_left
         jmp main
rep_right
         jsr repair_right
         jmp main
         .bend
;---------------------------------------
new_star
         ; Define the start position of
         ; a new shooting star.
         .block
         clc
         lda $d41b  ; get random row no
         ; Make sure that random no is
         ; not greater than 39.
         lsr a      ; divide accu by 2
         lsr a      ; divide accu by 2
         tax        ; secure accu
         sbc #23    ; subtract 23
         bcs skip   ; accu was < 39
         txa        ; accu was >= 39
skip
         sta starpos
         sta startpos
         lda #$04   ; high byte of scree

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
         sta sid
         ldx #2
         sta sid+1
         lda #1+128
         sta sid+4  ; noise gen on
         lda #128
         sta sid+4  ; noise gen off
         rts
;---------------------------------------
print_star
         ; Draw the falling shooting
         ; star on the screen.
         .block
         ldy #$00  ; offset
         ldx #$19  ; 25 rows
loop
         lda #$2a  ; star chr
         sta (starpos),y
         lda starpos
         cmp tankpos
         bne no_hit
         lda starpos+1
         cmp tankpos+1
         beq game_over
no_hit
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
game_over
         ; The shooting star hit the
         ; tank... Display game over
         ; message and exit with next
         ; keystroke.
         .block
         clc
         ldx #15   ; y coordinate
         ldy #11   ; x coordinate
         jsr $e50a ; plot, pos cursor
         lda #2    ; red
         sta $0286 ; textcolor
         lda #<message
         ldy #>message
         jsr $ab1e ; print string
         lda #0
         sta $c6   ; clear keyb buffer
getkey
         jsr $ffe4 ; getin
         beq getkey
         brk
         .bend

message  .text "******************"
         .byte $0d
         .text "           "
         .text "*** game over! ***"
         .byte $0d
         .text "           "
         .null "******************"
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
         ldy #$00  ; offset
         ldx #$19  ; 25 rows
loop
         lda #$20  ; space chr
         sta (starpos),y
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
move_tank_left
         ; Move the tank one position
         ; to the left.
         .block
         ; First check if there is a
         ; hole in the ground to the
         ; left
         ldy #39   ; next row - 1
         lda (tankpos),y
         cmp #$20
         beq skip
         ; Replace tank with space
         lda #$20
         ldy #0
         sta (tankpos),y
         ; Draw new tank
         lda #tank
         dec tankpos
         sta (tankpos),y
         ; Is tank at column 0?
         lda tankpos
         cmp #$98  ; inverted "X"
         beq game_won
skip
         rts
         .bend
;---------------------------------------
move_tank_right
         ; Move the tank one position
         ; to the right.
         .block
         ; First check if there is a
         ; hole in the ground to the
         ; right
         ldy #41   ; next row + 1
         lda (tankpos),y
         cmp #$20
         beq skip
         lda #$20
         ldy #0
         sta (tankpos),y
         lda #tank
         inc tankpos
         sta (tankpos),y
         ; Is tank at column 0?
         lda tankpos
         cmp #$bf  ; inverted "?"
         beq game_won
skip
         rts
         .bend
;---------------------------------------
game_won
         ; The tank moved all the way
         ; to position 0 or 39 and the
         ; player won the game.
         .block
         clc
         ldx #15   ; y coordinate
         ldy #11   ; x coordinate
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
         beq getkey
         brk
         .bend

congrats .text "*****************"
         .byte $0d
         .text "           "
         .text "*** game won! ***"
         .byte $0d
         .text "           "
         .null "*****************"
;---------------------------------------
repair_left
         ; Repair a hole in the ground
         ; to the tank's left.
         ldy #39   ; next row - 1
         lda #ground
         sta (tankpos),y
         rts
;---------------------------------------
repair_right
         ; Repair a hole in the ground
         ; to the tank's right.
         ldy #41   ; next row + 1
         lda #ground
         sta (tankpos),y
         rts
;---------------------------------------
init_screen
         ; Set the background and
         ; border color to black, then
         ; clear the screen with spaces.
         lda #$00  ; black
         sta $d021 ; background color
         sta $d020 ; border color

         ldx #$fa
         lda #$20  ; space chr
clear_screen
         sta $0400,x
         sta $04fa,x
         sta $05f4,x
         sta $06ee,x
         dex
         bne clear_screen
         rts
;---------------------------------------
init_tank
         ; Print the tank in the middle
         ; of the last screen row
         lda #$ac  ; low byte
         sta tankpos
         lda #$07  ; high byte
         sta tankpos+1
         ldy #0
         lda #tank ; chr for tank
         sta (tankpos),y
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
         cpy #40   ; last column
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
         cpy #40   ; last column
         bne loop2
         rts
         .bend
;---------------------------------------
wait
         ; Implement a wait func by
         ; counting VIC-II frames. 50
         ; PAL frames equal to 1s.

         ldy #1; 1 frame
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

         .end
