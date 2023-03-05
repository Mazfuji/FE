;-----------------------------------
;
;  line_print routine for FE v1.05
;  for general
;
;-----------------------------------


_PRINT    EQU     1FF4H
_LOC      EQU     201EH


next_chr 	EQU     3069H

console_x	EQU     4591H
console_y	EQU     4592H
console_width	EQU     4593H
console_length	EQU	4594H

line_data_adr	EQU     45D2H
line_print_y	EQU     45D1H
view_offset	EQU     45A9H
tab_info_table	EQU     45FCH

nm_chr_atri	EQU     3016H
chr_atri 	EQU     45D4H


        OFFSET  0C000H-4400H
        ORG     4400H


line_print:
        PUSH    BC
        PUSH    DE
        PUSH    HL
        PUSH    IY
        LD      E,(IX)
        CALL    locate_init
        LD      A,(nm_chr_atri)
        LD      (chr_atri),A
        LD      HL,(line_data_adr)
        LD      IY,tab_info_table
;
        LD      A,(view_offset)
        LD      D,A
        INC     D
lp1:	DEC     D
        JP      Z,lp2
        CALL    next_chr
        JP      lp1
;
lp2:    LD      A,(console_width)
        LD      D,A
        DEC     D
lp3:	CALL    next_chr
;
        CALL    _PRINT
;
        DEC     D
        JP      NZ,lp3
        POP     IY
        POP     HL
        POP     DE
        POP     BC
        RET


locate_init:
        LD      A,(line_print_y)
        LD      H,A
        LD      A,(console_y)
        ADD     A,H
        LD      A,(console_x)
        LD      L,A
;
        CALL    _LOC
        RET

