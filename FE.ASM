;======================================
;
;     Screen Editor for S-OS SWORD
;         FE version 1.01
;      Programmed by H.Matsufuji
; Since May 4,1995.
;
;======================================


_PRINT	EQU	1FF4H
_PRNTS	EQU	1FF1H
_LTNL	EQU     1FEEH
_MSX	EQU     AFE5H
_BELL	EQU	1FC4H
_WOPEN	EQU	1FAFH
_WRD	EQU	1FACH
_RDD	EQU	1FA6H
_FILE	EQU	1FA3H
_POKE	EQU	1F9AH
_POKE@	EQU	1F97H
_PEEK	EQU	1F94H
_PEEK@	EQU	1F91H
_ROPEN	EQU	2009H
_LOC	EQU	201EH
_FLGET	EQU	2021H
_WIDCH	EQU	2030H
_ERROR	EQU	2033H
;
_KBFAD	EQU	1F76H
_IBFAD	EQU	1F74H
_SIZE	EQU	1F72H
_DTADR	EQU	1F70H
_EXADR	EQU	1F6EH
_MEMAX	EQU	1F6AH
_WKSIZ	EQU	1F68H
_DSK	EQU	1F5DH
_WIDTH	EQU	1F5CH
_MAXLN	EQU	1F5BH


__NULL	EQU     0
__TAB	EQU	9
__CLS	EQU	12
__CR	EQU	13
__EOF	EQU	26
__SPACE	EQU	32


line_print	EQU	4400H


        OFFSET	5000H-3000H
        ORG     3000H


;-------------------------------------
; Start


cold_start:
        JP      cold0


;-------------------------------------
; Configrations


MEMORY_MIN:	DW	04800H

inital_tab_width:
                DB	8
view_offset_w:	DB      20

chr_TAB:	DB	"-"
chr_CR:		DB	"」"
chr_SPACE:	DB	" "
chr_OTHER:	DB	"."
str_EOF:	DB	"[EOF]",__EOF,0,0

un_chr_atri:	DB	3	; unknown color
EOF_str_atri:	DB	5	; EOF string color
sp_chr_atri:	DB	6	; CR and TAB color
nm_chr_atri:	DB	7	; Normal color

untitle:        DB      "UNTITLED     .   ",0

key_asign_table:
;		08 19 2A 3B 4C 5D 6E 7F
        DB	 0,12, 0, 0, 1, 3,11, 0	; 00
        DB	14,13, 0, 0, 0,15, 0, 9	; 08
        DB	 0, 0, 9, 2, 0, 0, 0, 5	; 10
        DB	 4, 0, 6, 7, 1, 2, 3, 4	; 18
        DB	 0, 0, 0, 0, 0, 0, 0, 0	; 20
        DB	 0, 0, 0, 0,24, 0,23, 0	; 28
        DB	16,17,18,19,20, 0,22, 0	; 30
        DB	21, 8, 0, 0, 0, 0, 0, 0 ; 38


;-------------------------------------
; Subroutine for line_print


next_chr:
        LD      A,E
        OR	A
        JP	NZ,nxt_c1
nxt_c4:	LD	A,(HL)
        INC	HL
        INC	IY
        CP	32
        RET	NC
        CP	__TAB
        JP	Z,nxt_c5
        CP	__CR
        JP	Z,nxt_c6
        OR      A
        JP 	Z,nxt_c7
        CP	__EOF
        JP	Z,nxt_c8
        LD	A,(un_chr_atri)
        LD	(chr_atri),A
        LD	A,(chr_OTHER)
        RET
;
nxt_c5: LD	E,1
        LD	A,(sp_chr_atri)
        LD	(chr_atri),A
        LD	A,(chr_TAB)
        RET
;
nxt_c6:	LD	E,2
        LD	A,(sp_chr_atri)
        LD	(chr_atri),A
        LD	A,(chr_CR)
        RET
;
nxt_c7:	LD	HL,str_EOF
        LD	A,(EOF_str_atri)
        LD	(chr_atri),A
        JP	nxt_c4
;
nxt_c8:	LD	E,2
        LD	A,(nm_chr_atri)
        LD	(chr_atri),A
        LD	A,(chr_SPACE)
        RET
;
nxt_c1:	CP	1
        JP	Z,nxt_c2
        LD	A,(chr_SPACE)
        RET
;
nxt_c2: LD	A,(IY)
        OR	A
        JP	NZ,nxt_c3
        INC	IY
        LD	A,(chr_SPACE)
        RET
;
nxt_c3:	LD	E,0
        LD	A,(nm_chr_atri)
        LD	(chr_atri),A
        JP	nxt_c4


;-------------------------------------
; Main


cold0:	LD	DE,startup_mes
        CALL	_MSX
        LD	IX,local_work
        CALL	mem_workarea_initalize
        CALL	console_workarea_initalize
        CALL	screen_workarea_initalize
        CALL    key_initalize
        CALL	special_workarea_initalize
        LD	A,(inital_tab_width)
        DEC	A
        LD	C,A
        CALL	tab_table_initalize
        CALL	text_clear
;
        LD	DE,(_KBFAD)
        LD	A,(DE)
        CP      "#"
        JR	Z,cold15
cold1:	LD	A,(DE)
        INC	DE
        OR	A
        JR	Z,cold2
        CP	" "
        JR	NZ,cold1
        CALL    file_open_r
        JR	C,cold3
        CALL	file_read
        JP	C,f_err
        JP	cold5
;
cold15:	INC     DE
        CALL	skip_space
        CALL	skip_not_space
        CALL	skip_space
;
cold2:	LD	DE,untitle
        CALL	new_file
cold4:	LD	DE,mes_1
        CALL	_MSX
        JP	cold5
;
cold3:	CP	8
        JP	NZ,_ERROR
        JR	old4
;
cold5: CALL    pointer_drive
        LD	A,__CLS
        CALL	_PRINT
        RET


;-------------------------------------
; Carry frag opration


scf_ret:
        SCF
        RET

rcf_ret:
        OR      A
        RET


;-------------------------------------
; Work area initialize


mem_workarea_initalize:
        LD	HL,(_MEMAX)
        LD	(mem_max),HL
        LD	(text_max),HL
        LD	BC,(MEMORY_MIN)
        LD	(mem_min),BC
        LD	(text_start),BC
        SBC	HL,BC
        LD	(text_area),HL
        RET


console_workarea_initalize:
        XOR	A
        LD	(console_x),A
        LD	(console_y),A
        LD	(v_fnam_xy),A
        LD	(v_mode_xy),A
        LD	A,(_WIDTH)
        LD	(console_width),A
        SUB	7
        LD	(pointer_line_xy),A
        LD	(mark_line_xy),A
        SUB     4
        LD	(pointer_x_xy),A
        LD	(mark_x_xy),A
        SUB	6
        LD	(v_pointer_xy),A
        LD	(v_mark_xy),A
        SUB	6
        LD	(free_xy),A
        SUB	6
        LD	(v_free_xy),A
        LD	A,(_MAXLN)
        DEC	A
        LD	(v_mode_xy+1),A
        LD	(v_free_xy+1),A
        LD	(v_pointer_xy+1),A
        LD	(pointer_x_xy+1),A
        LD	(pointer_line_xy+1),A
        LD	(free_xy+1),A
        LD	(free_xy+1),A
        DEC	A
        LD	(console_length),A
        LD	(v_fnam_xy+1),A
        LD	(v_mark_xy+1),A
        LD	(mark_x_xy+1),A
        LD	(mark_line_xy+1),A
        RET


screen_workarea_initalize:
        XOR	A
        LD	(view_offset),A
        LD	(pointer_x),A
        LD	(cursor_x),A
        LD      HL,0
        LD	(view_line),HL
        LD	(pointer_line),HL
        LD	HL,(text_start)
        LD	(view_adr),HL
        CALL	calc_pointer_address
        CALL    set_mark_2
        CALL	save_cursor_x
        RET


key_initalize:
        XOR     A
        LD	(escape_mode),A
        LD	(type_mode),A
        RET


tab_table_initalize:
        LD	HL,tab_info_table
        LD      B,0
tti1:	LD	A,B
        AND	C
        JR	NZ,tti2
        LD	A,1
        JR	tti3
tti2:	XOR	A
tti3:	LD	(HL),A
        INC	HL
        INC	B
        JR	NZ,tti1
        RET


special_workarea_initalize:
        LD	HL,(_WKSIZ)
        LD	DE,300H
        OR	A
        SBC	HL,DE
        LD	(buffer_size),HL
        LD	HL,0
        LD	(copy_length),HL
        LD	(undo_1_b_adr),HL
        LD	DE,100H
        ADD	HL,DE
        LD	(find_b_adr),HL
        ADD	HL,DE
        LD	(replace_b_adr),HL
        ADD	HL,DE
        LD	(copy_b_adr),HL
        RET


;-------------------------------------
; EDITOR OP


pointer_drive:
        XOR	A
        LD	(flag_cmd_mode),A
        CALL	view_screen
pd09:	CALL	view_text
;
pd1:	CALL	get_line
pd11:	CALL	calc_view_line
        LD	(IX+1),0
        CALL	C,view_text
        CALL	view_pointer_line
        CALL	calc_locate_y
        CALL	load_cursor_x
        CALL	calc_pointer_x
        CALL	calc_cursor_x
        JR	pd3
Mpd2:	CALL	calc_cursor_x
        CALL	save_cursor_x
pd3:	LD	A,(flag_cmd_mode)
        OR	A
        CALL	Z,view_cursor_x
        CALL	calc_locate_x
        CALL	C,offset_review
        CALL	view_line_buffer
;
        CALL	keyin
        CP	20H
        JP	C,control_code
        LD      C,A
        LD	A,(escape_mode)
        OR	A
        LD	A,C
        JR	NZ,pd4
type:	LD	A,(type_mode)
        OR	A
        LD	A,C
        JR	NZ,type2
        CALL	insert_type
        JP	pd2
type2:	CALL	over_type
        JP	pd2
;
pd4:	CP	80H
        JP	NC,c_null
        CP	40H
        JR	C,control_code
        AND	1FH

;
control_code:
        LD      HL,key_assign_table
        LD	D,0
        LD	E,A
        ADD	HL,DE
        LD	A,(HL)
        PUSH	AF
        LD	A,(flag_cmd_mode)
        OR	A
        JR	Z,c_c1
        LD	HL,control_code_table_cmd
        JR	c_c2
c_c1:	LD	HL,control_code_table
c_c2:	POP	AF
        SLA	A
        LD	E,A
        ADD	HL,DE
        LD      E,(HL)
        INC     HL
        LD	D,(HL)
        LD	H,D
        LD	L,E
        JP	(HL)


offset_review:
        CALL	calc_view_offset
        CALL	calc_locate_x
        LD	A,(flag_cmd_mode)
        OR	A
        RET	NZ
        LD	(IX+1),1
        CALL	view_text
        RET


keyin:
        LD	HL,(locate_xy)
        CALL	_LOC
        CALL	_FLGET
        RET


c_null:
c_reserved:
        JP      pd2


c_quit:
        CALL    exit_escape_mode
        CALL    put_line
        JP      C,pd2
        CALL	close_file
        JP	C,pd2
        RET


c_up:
        CALL	put_line
        JP	C,pd2
        CALL	pointer_line_dec
        JP	C,c_r2
        JP	pd1


c_down:
        CALL	put_line
        JP	C,pd2
        CALL	pointer_line_inc
        JP	C,c_l2
        JP	pd1


c_cursor_top:
        CALL	top_cursor
        JP	pd2


c_cursor_botom:
        CALL	botom_cursor
        JP	pd2


c_up_page:
        CALL	put_line
        JP	C,pd2
        LD	A,(console_length)
        LD	B,A
up151:	CALL	pointer_line_dec
        DEC     B
        JR	NZ,up151
        JP      pd1


c_down_page:
        CALL    put_line
        JP	C,pd2
        LD	A,(console_length)
        LD	B,A
down151:CALL	pointer_line_inc
        DEC     B
        JR	NZ,down151
        JP	pd1


c_right:
        CALL	pointer_x_inc
        JP	NC,pd2
c_r1:	CALL	put_line
        JP	C,pd2
        CALL	pointer_line_inc
        JP      C,pd2
c_r2:	CALL	top_cursor
        CALL    save_cursor_x
        JP	pd1


c_right_cmd:
        CALL    pointer_x_inc
        JP	pd2


c_left:
        CALL	pointer_x_dec
        JP	NC,pd2
c_l1:	CALL	put_line
        JP	C,pd2
        CALL	pointer_line_dec
        JP	C,pd1
c_l2:	CALL	get_line
        CALL    botom_cursor
        CALL	calc_cursor_x
        CALL	save_cursor_x
        JP	pd11


c_left_cmd:
        CALL    pointer_x_dec
        JP	pd2


c_skip_foward:
        CALL    word_skip_foward
        JP	NC,pd2
        JP      c_r1


c_skip_back:
        CALL	word_skip_back
        JP	NC,pd2
        JP	c_l1


c_escape:
        CALL	put_line
        JP	C,pd2
        LD	A,(escape_mode)
        OR	A
        JR	Z,c_esc1
        CALL	exit_escape_mode
        JP	pd1
c_esc1:	DEC	A
        LD      (escape_mode),A
        CALL	set_mark
        CALL	view_type_mode
        JP	pd1


c_escape_cmd:
        LD	A,(escape_mode)
        OR	A
        JR	Z,c_ec1
        CALL	exit_escape_mode
        JP	pd2
c_ec1:	DEC	A
        LD	(escape_mode),A
        CALL	view_type_mode
        JP	pd2


c_change_typemode:
        LD	A,(type_mode)
        XOR	1
        LD	(type_mode),A
        CALL	exit_escape_mode
        CALL	view_type_mode
        JP	pd2


c_tab_hid:
        CALL	exit_escape_mode
        LD	A,(chr_TAB)
        LD	B,A
        LD	A,(chr_TAB_swap)
        LD	(chr_TAB),A
        LD	A,B
        LD	(chr_TAB_swap),A
        LD	(IX+1),1
        CALL    view_text
        JP	pd11


c_cr_hid:
        CALL	exit_escape_mode
        LD	A,(chr_CR)
        LD	B,A
        LD	A,(chr_CR_swap)
        LD	(chr_CR),A
        LD      A,B
        LD	(chr_CR_swap),A
        LD	(IX+1),1
        CALL	view_text
        JP	pd11


c_tab:
        CALL	delete_mark
        LD	C,__TAB
        JP	type


c_back_space:
        CALL	delete_mark
        LD	A,(pointer_x)
        OR	A
        JP	Z,c_delete_cr
        CALL	calc_pointer_inline
        LD	D,H
        LD	E,L
        DEC	DE
c_bs0:	LD	A,(HL)
        LD	(DE),A
        CP	__CR
        JP	Z,c_bs1
        OR	A
        JP	Z,c_bs1
        INC	HL
        INC	DE
        JR	c_bs0
;
c_bs1:	CALL	pointer_x_dec
        CALL	edited_line
        JP	pd2


c_back_space_cmd:
        LD      A,(pointer_x)
        OR	A
        JP	Z,pd2
        CALL	calc_pointer_inline
        LD	D,H
        LD	E,L
        DEC	DE
c_bsc0:	LD	A,(HL)
        LD	(DE),A
        CP	__CR
        JP	Z,c_bsc1
        OR	A
        JP	Z,c_bsc1
        INC     HL
        INC	DE
        JR	c_bsc0
c_bsc1:	CALL	pointer_x_dec
        JP	pd2


; Delete CR
;
c_delete_cr:
        CALL	delete_mark
        CALL	put_line
        JP	C,pd2
        CALL	pointer_line_dec
        JP	C,pd1
        CALL	get_line
        XOR	A
        DEC	A
        LD	(cursor_x),A
        CALL	calc_pointer_x
        CALL	calc_cursor_x
        CALL	save_cursor_x
        LD	HL,(pointer_adr)
        CALL	next_line
        LD	DE,1
        CALL	move_text_minus
c_dc1:	CALL	calc_text_free
        JP      pd09


; Insert CR
;
c_insert_cr:
        CALL	delete_mark
        CALL	put_line
        JP	C,pd2
        CALL	calc_pointer
        PUSH	HL
        LD	DE,1
        CALL	move_text_plus
        POP	HL
        JP	C,pd2
        LD	(HL),__CR
        CALL	get_line
        LD	(IX+1),0
        CALL	view_text
        JP	c_right


; CR
;
c_cr:
        LD	A,(type_mode)
        OR	A
        JR	Z,c_insert_cr
c_cr1:	CALL	botom_cursor
        JP	c_right


; Block delete
;
c_block_delete:
        CALL	put_line
        JP	C,pd2
        CALL	set_mark_2
        CALL	calc_block_length
        JP	C,pd2
        ADD	HL,DE
        CALL	move_text_minus
        CALL	get_mark_2
        CALL	save_cursor_x
        LD	(IX+1),0
        CALL	view_text
        CALL	exit_escape_mode
        JP	pd1


; Block cut
;
c_block_cut:
        CALL	put_line
        JP	C,pd2
        CALL	set_mark_2
        CALL	calc_block_length
        JP	C,pd2
        CALL	save_copy
        JP	C,pd2
        ADD	HL,DE
        CALL	move_text_minus
        CALL	get_mark_2
        CALL	save_cursor_x
        LD	(IX+1),0
        CALL	view_text
        CALL	exit_escape_mode
        JP	pd1


; Block copy
;
c_block_copy:
        CALL	put_line
        JP	C,pd2
        CALL	set_mark_2
        CALL	calc_block_length
        JP	C,pd2
        CALL	save_copy
        JP      C,pd2
        LD      (IX+1),0
        CALL    view_text
        CALL    exit_escape_mode
        JP      pd1
; Block paste
;
c_block_paste:
        CALL    put_line
        JP      C,pd2
        LD      HL,(copy_length)
        LD      H,A
        OR      L
        JP      Z,pd2
        CALL    exit_escape_mode
        CALL    calc_pointer
        PUSH    HL
        CALL    load_copy
        POP     DE
        JP      C,pd2
        LD      HL,(copy_length)
        ADD     HL,DE
        CALL    calc_pointer_line_x_add
        CALL    get_line
        CALL    calc_cursor_x
        CALL    save_cursor_x
        LD      (IX+1),0
        CALL    view_text
        JP      pd11


; Block length calcuration
;
calc_block_length:
        CALL    swap_mark_pointer
        LD      HL,(mark_2_adr)
        LD      A,(mark_2_x)
        LD      D,0
        LD      E,A
        ADD     HL,DE
        LD      B,H
        LD      C,L
        LD      HL,(mark_1_adr)
        LD      A,(mark_1_x)
        LD      D,0
        LD      E,A
        ADD     HL,DE
        LD      D,B
        LD      E,C
        OR      A
        SBC     HL,DE
        JP      Z,scf_ret
        LD	D,H
        LD      E,L
        LD      H,B
        LD      L,C
        RET


c_tab_width_change:
        CALL    put_line
        JP      C,pd2
        CALL    exit_escape_mode
        LD      A,(tab_width)^
        CP      8
        JR      NZ,t_wc1
        LD      A,4
        JR      t_wc2
t_wc1:	LD      A,8
t_wc2:	LD	(tab_width),A
        DEC	A
        LD	C,A
        CALL    tab_table_initalize
        LD      (IX+1),0
        CALL view_text
        CALL    get_line
        JP      pd2


c_command_mode:
        CALL    put_line
        JP      C,pd2
        CALL    exit_escape_mode
        CALL    set_mark_2
        CALL    clr_botom
c_cmde:	XOR	A
        DEC     A
        LD      (flag_cmd_mode),A
        LD      A,(console_x)
        ADD     A,10
        LD      (console_x),A
        LD      A,(console_width)
        SUB     10
        LD	(console_width),A
        LD      A,(v_mode_xy+1)
        LD      (locate_xy+1),A
        LD      HL,(v_mode_xy)
        CALL    _LOC
        LD      DE,s_command
        CALL          _MSX
        LD      A,__CR
        LD      (line_buffer),A
        XOR     A
        LD      (pointer_x),A
        JP      pd2


;-------------------------------------
; Command execute


c_cr_cmd:
        XOR	A
        LD      (flag_cmd_mode),A
        CALL    view_botom
        LD      A,(console_x)
        SUB     10
        LD      (console_x),A
        LD      A,(console_width)
        ADD     A,10
        LD	(console_width),A
        LD      DE,line_buffer
ccc1:	CALL    skip_space
        INC     DE
        AND     0DFH
        CP      "E"
        JP      Z,x_edit
        CP      "Q"
        JP      Z,x_quit
        CP      "L"
        JP      Z,x_load
         CP      "S"
        JP      Z,x_save
        CP      "N"
        JP      Z,x_new
        CP      "B"
        JP      Z,x_first
        CP      "F"
        JP      Z,x_find
        CP      "C"
        JP      Z,x_replace
        CP      "W"
        JP      Z,x_width
        JP      c_cmde


skip_space:
        LD      A,(DE)
        CP      __SPACE
        RET     NZ
        CP      __TAB
        RET     NZ
        INC     DE
        JR      skip_space


skip_not_space:
        LD      A,(DE)
        CP      __SPACE
        RET     Z
        CP      __TAB
        RET     Z
        INC     DE
        JR            skip_not_space


x_edit:
        CALL    skip_space
        CP      __CR
        JR      Z,x_ed1
        CALL    get_number
        DEC     HL
        LD      (pointer_line),HL
        CALL    calc_pointer_address
x_ed2:	CALL    set_mark_2
x_ed1:	CALL    get_mark_2
        CALL    save_cursor_x
        JP      pd1


x_width:
        LD      A,(_WIDTH)
        CP      40
        JR      Z,x_w1
        LD      A,40
x_w0:	CALL    _WIDCH
        CALL    console_workarea_initalize
        CALL    view_colums
        LD      (IX+1),0
        CALL    view_text
        JP      c_cmde
x_w1:	LD      A,80
        JR	x_w0


x_first:
        PUSH    DE
        XOR     A
        LD      (pointer_x),A
        LD      (cursor_x),A
        LD      HL,0
        LD      (pointer_line),HL
        CALL    calc_pointer_address
        CALL    set_mark_2
        POP     DE
        JP      ccc1


x_quit:
        CALL    close_file
        JP      C,c_cmde
        RET


x_load:
        PUSH    DE
        CALL    close_file
        POP     DE
        JP      C,c_cmde
        CALL    skip_space
        LD      A,__CLS
        CALL    _PRINT
        CALL    load_file
        JP	C,x_ld1
        CALL    screen_workarea_initalize
x_ld0:	CALL    view_screen
        LD      (IX+1),0
        CALL    view_text
        JP      c_cmde
x_ld1:	CALL    _ERROR
        CALL          pause
        JR      x_ld0


x_save:
        CALL    skip_space
        LD      A,(DE)
        CP      __CR
        JR      NZ,x_s1
        LD      DE,filename
x_s1:	LD      A,__CLS
        CALL    _PRINT
        CALL    save_file
        JP      x_ld0


x_new:
        PUSH    DE
        CALL    close_file
        POP     DE
        CALL    skip_space
        CP      __CR
        JR      Z,x_n1
x_n0:	CALL    new_file
        JP      C,x_n2
        CALL    screen_workarea_initalize
        JP      x_ld0
x_n1:	LD	DE,untitle
        JR      x_n0
x_n2:	LD	A,__CLS
        CALL    _PRINT
        JP      x_ld1


; Find
;
x_find:
        CALL    skip_space
        CP      __CR
        JP      Z,c_cmde
        LD      B,A
        AND     0DFH
        CP      "M"
        JR      Z,x_fn0
        LD      A,B
        INC     DE
        LD	HL,(find_b_adr)
        LD      A,(DE)
        CP      B
        JP      Z,c_cmde
;
x_fn1:	LD      A,(DE)
        CP      __CR
        JP      Z,c_cmde
        CP      B
        JR      Z,x_fn2
        CALL          _POKE
        INC     HL
        INC     DE
        JR      x_fn1
x_fn2:	XOR	A
        CALL    _POKE
;
x_fn0:	CALL    find_str
        JP      C,c_cmde
        CALL    calc_flash_locate
        CALL    clr_botom
        LD      HL,(v_mode_xy)
        CALL	_LOC
        LD      DE,mes_7
        CALL    _MSX
        LD      HL,(locate_xy)
        CALL    _LOC
x_fn4:	CALL    _FLGET
        AND     0DFH
        CP      "E"
        JP      Z,x_fn5
        CP      "M"
        JR	Z,x_fn6
        CP      "C"
        JP      Z,c_cmde
        JR      x_fn4
;
x_fn5:	CALL    view_botom
        JP	x_ed2
;
x_fn6:	CALL    calc_pointer
        INC     HL
        CALL    calc_pointer_line_x_add
        JR            x_fn0


; Find and replace
;
x_replace:
        XOR     A
        LD      (flag_replace_all),A
        CALL    skip_space
        CP      __CR
        JP      Z,c_cmde
        LD      B,A
        INC     DE
        LD      HL,(find_b_adr)
        LD      A,(DE)
        CP      B
        JP      Z,c_cmde
        LD      C,0
;
x_lp1:  LD      A,(DE)
        CP      __CR
        JP      Z,c_cmde
        CP      B
        JR      Z,x_lp2
        CALL    _POKE
        INC     C
        INC     HL
        INC     DE
        JR      x_lp1
x_lp2:   XOR     A
        CALL    _POKE
        LD      A,C
        LD      (find_str_len),A
;
        LD      HL,(replace_b_adr)
        INC     DE
        LD      C,0
x_lp6:
        LD      A,(DE)
        CP      __CR
        JP      Z,c_cmde
        CP      B
        JR      Z,x_lp7
        CALL    _POKE
        INC     C
        INC     HL
        INC     DE
        JR      x_lp6
x_lp7:	XOR	A
        CALL    _POKE
        LD      A,C
        LD      (replace_str_len),A
;
x_lp0:  CALL    find_str
        JP      C,x_lp9
        LD      A,(flag_replace_all)
        OR      A
        JR      NZ,x_lp5
        CALL    calc_flash_locate
        CALL    clr_botom
        LD      HL,(v_mode_xy)
        CALL    _LOC
        LD      DE,mes_8
        CALL    _MSX
        LD      HL,(locate_xy)
        CALL    _LOC
x_lp4:	CALL	_FLGET
        AND     0DFH
        CP      "R"
        JP      Z,x_lp5
        CP      "S"
        JR      Z,x_lp55
        CP      "C"
        JP      Z,c_cmde
        CP      "A"
        JP      Z,x_lp8
        JR      x_lp0
;
x_lp5:	CALL    replace
        JP      C,x_lp9       
        CALL  calc_pointer
        LD      A,(replace_str_len)
        LD      D,0
        LD      E,A
        ADD     HL,DE
        CALL    calc_pointer_line_x_add
        JP      x_lp0
;
x_lp55:	CALL	calc_pointer
        INC     HL
        CALL    calc_pointer_line_x_add
        JP      x_lp0
;
x_lp8:	CALL    clr_botom
        CALL    view_free_colum
        XOR     A
        DEC     A
        LD      (flag_replace_all),A
        JP      x_lp5
;
x_lp9:	LD      (IX+1),0
        CALL    view_text
        JP      c_cmde
calc_flash_locate:
        CALL    calc_view_line
        CALL    get_line
        CALL    calc_cursor_x
        CALL    calc_view_offset
        LD      (IX+1),0
        CALL    view_text
        CALL    calc_locate_x
        CALL    calc_locate_y
        RET


;-------------------------------------
; TEXT OP


top_cursor:
        XOR     A
        LD      (pointer_x),A
        CALL    calc_cursor_x
        RET
botom_cursor:
        XOR     A
        DEC     A
        LD	(cursor_x),A
        CALL    calc_pointer_x
        RET


; Find strings
;
find_str:
        CALL    calc_pointer
        LD      DE,(find_b_adr)
        EX      DE,HL
        CALL    _PEEK
        INC     HL
        LD      B,A
f_str1:	LD      A,(DE)
        INC     DE
        OR      A
        JP      Z,scf_ret
        CP      B
        JR      NZ,f_str1
        PUSH          HL
        PUSH    DE
f_str3:	CALL    _PEEK
        OR      A
        JR      Z,f_str2
        LD      C,A
        LD      A,(DE)
        INC     DE
        INC     HL
        CP      C
        JR      Z,f_str3
        POP           DE
        POP     HL
        JR      f_str1
f_str2: POP     HL
        POP     DE
        DEC	HL
        CALL    calc_pointer_line_x_add
        OR      A
        RET


; Replace strings
;
replace:
        LD      A,(replace_str_len)
        LD      B,A
        LD      A,(find_str_len)
        SUB     B
        JR      Z,rep0
        JR      C,rep2
        JR      rep3
;
rep0:	CALL    calc_pointer
        LD      DE,(replace_b_adr)
        EX      DE,HL
rep1:	CALL    _PEEK
        OR      A
        RET	Z
        LD      (DE),A
        INC     HL
        INC     DE
        JR      rep1
;
rep2:	NEG
        LD      B,A
        CALL    calc_pointer
        LD      D,0
        LD      E,B
        CALL    move_text_plus
        RET     C
        JR      rep0
;
rep3:	LD      B,A
        CALL    calc_pointer
        LD      A,(find_str_len)
        LD      D,0
        LD      E,A
        ADD     HL,DE
        LD      E,B
        CALL    move_text_minus
        JR      rep0


; Calcurate pointer
;
calc_pointer:
        LD      HL,(pointer_adr)
        LD      A,(pointer_x)
        LD      D,0
        LD      E,A
        ADD     HL,DE
        RET


; Clear text.
;
text_clear:
        LD      HL,(text_start)
        XOR     A
        LD      (edited_file),A
        LD      (HL),A
        CALL    calc_text_size
        RET     


; Calcurate text size.
;
calc_text_size:
        LD      HL,(text_start)
cts1:	CALL    next_line
        JR      NC,cts1
        LD      (text_end),HL
        LD      DE,(text_start)
        OR      A
        SBC     HL,DE
        INC	HL
        LD      (text_size),HL
        CALL    calc_text_free
        RET


; Calucurate free size.
;
calc_text_free:
        LD      HL,(text_max)
        LD      DE,(text_end)
        OR      A
        SBC	HL,DE
        LD      (text_free),HL
        RET


calc_view_offset:
        LD      A,(view_offset)
        LD      H,A
        LD      A,(console_width)
        DEC     A
        LD      L,A
        LD      A,(view_offset_w)
        LD      D,A
        LD      A,(cursor_x)
        LD      E,A
        SUB     H
        JR      C,cvo1
        SUB     L
        JR      NC,cvo3
        OR      A
        RET
;
cvo1:   LD	A,H
        SUB     D
        JR      C,cvo2
        LD	(view_offset),A
        LD      H,A
        LD      A,E
        SUB     H
        JR      C,cvo1
        JP      scf_ret
cvo2:	XOR     A
        LD      (view_offset),A
        JP      scf_ret
;    
cvo3:	LD      A,H
        ADD     A,D
        LD      (view_offset),A
        LD      H,A
        LD      A,E
        SUB     H
        SUB     L
        JR      NC,cvo3
        RET


; Calcurate line number of start of text viewer.
;
calc_view_line:
        LD      HL,(pointer_line)
        LD      DE,(view_line)
        OR      A
        PUSH    HL
        SBC     HL,DE
        POP     HL
        JR      C,cvl1
        LD      B,0
        LD      A,(console_length)
        LD      C,A
        DEC     C
        PUSH    HL
        EX      DE,HL
        ADD     HL,BC
        OR      A
        SBC     HL,DE
        POP     HL
        JP      NC,rcf_ret
;
        OR      A
        SBC	HL,BC
        LD      DE,(view_line)
        LD	view_line),HL
        SBC     HL,DE
        LD      B,H
        LD      C,L
        LD      HL,(view_adr)
cvl3:	CALL    next_line
        DEC     BC
        LD      A,B
        OR      C
        JR      NZ,cvl3
        LD      (view_adr),HL
        SCF
        RET
;
cvl1:   LD      (view_line),HL
        LD      HL,(pointer_adr)
        LD      (view_adr),HL
        SCF
        RET


calc_pointer_address:
        LD      BC,(pointer_line)
        CALL    calc_address
        LD      (pointer_adr),HL
        LD      (pointer_line),DE
        RET


calc_address:
        LD      HL,(text_start)
        LD      DE,0
ctp2:	PUSH	DE
        EX      DE,HL
        OR      A
        SBC     HL,BC
        LD      A,H
        OR      L
        EX      DE,HL
        POP     DE
        RET     Z
        CALL    next_line
        JP      C,scf_ret
        INC     DE
        JR	ctp2


; Move pointer to the right.
;
pointer_x_inc:
        CALL    calc_pointer_inline
        LD      A,(HL)
        CP      __CR
        JP      Z,scf_ret
        OR      A
        JP      Z,scf_ret
        LD      A,C
        INC     A
        LD      (pointer_x),A
        RET


; Move pointer to the left.
;
pointer_x_dec:
        LD      A,(pointer_x)
        OR      A
        JP      Z,scf_ret
        DEC     A
        LD      (pointer_x),A
        RET


; Move pointer to the next word.
;
word_skip_foward:
        CALL    calc_pointer_inline
        LD      A,(HL)
        CP      __CR
        JP      Z,scf_ret
wsf1:	LD	A,(HL)
        INC     HL
        CP      __CR
        JR      Z,wsf3
        OR      A
        JR      Z,wsf3
        INC     C
        CALL    skip_character
        JR      NZ,wsf1
wsf2:	LD      A,(HL)
        INC     HL
        CP      __CR
        JP      Z,wsf3
        OR      A
        JP      Z,wsf3
        INC     C
        CALL    skip_character
        JR      Z,wsf2
        DEC     C
wsf3:	LD      A,C
        LD      (pointer_x),A
        OR      A
        RET


; Move pointer to the back word.
;
word_skip_back:
        CALL    calc_pointer_inline
        LD      A,C
        OR      A
        JP      Z,scf_ret
wsb1:	DEC     HL
        DEC     C
        LD      A,C
        OR      A
        JR      Z,wsb2
        LD      A,(HL)
        CALL    skip_character
        JR      Z,wsb1
wsb2:   DEC     HL
        DEC     C
        LD      A,(HL)
        CALL	skip_character
        JR      Z,wsb5
        LD      A,C
        OR      A
        JR      Z,wsb3
        JR      wsb2
wsb5:	INC     C
wsb3:	LD	A,C
        LD      (pointer_x),A
        RET


; Check if skip letter.
;
skip_character:
        PUSH	BC
        PUSH    HL
        PUSH    AF
        LD      HL,skip_character_table
        LD      B,0
        LD      A,(skip_character_number)
        LD      C,A
        POP     AF
        CPIR
        POP     HL
        POP     BC
        RET


; Move pointer to the next line.
;
pointer_line_inc:
        LD      HL,(pointer_adr)
        CALL    next_line
        RET     C
        LD      (pointer_adr),HL
        LD	HL,(pointer_line)
             INC     HL
        LD      (pointer_line),HL
        OR      A
        RET


; Move pointer to the back line.
;
pointer_line_dec:
        LD      HL,(pointer_line)
        LD      A,H
        OR      L
        JP      Z,scf_ret
        DEC     HL
        LD      (pointer_line),HL
        LD      HL,(pointer_adr)
        CALL    back_line
        RET     C
        LD      (pointer_adr),HL
        RET


next_line:
        LD      A,(HL)
        OR      A
        JP      Z,scf_ret
        INC     HL
        CP      __CR
        RET     Z 
        JP      next_line


back_line:
        LD	DE,(text_start)
        PUSH    HL
        OR      A
        SBC     HL,DE
        LD      A,H
        OR      L
        POP     HL
        JP      Z,scf_ret
        DEC     DE
        DEC     HL
bk_l1:	PUSH    HL
        OR	A
        SBC     HL,DE
        LD      A,H
        OR      L
        POP     HL
        JP      Z,bk_l2
        DEC     HL
        LD      A,(HL)
        CP      __CR    
        JR      NZ,bk_l1
bk_l2:	INC     HL
        RET


save_cursor_x:
        LD      A,(cursor_x)
        LD      (cursor_x_keep),A
        RET


load_cursor_x:
        LD      A,(cursor_x_keep)
        LD      (cursor_x),A
        RET
        

; Calcurate colum by pointer.
;
calc_cursor_x:
        LD      HL,line_buffer
        LD      A,(pointer_x)
        LD      C,A
        LD      B,0
        LD      DE,tab_info_table
;    
ccx1:	LD      A,C
        OR      A
        JR      Z,ccx3
        LD      A,(HL)
        CP      __TAB
        JR      Z,ccx2
        CP      __CR
        JR      Z,ccx3
        OR      A
        JR      Z,ccx3
        INC     B
        INC     DE
ccx4:	DEC     C
        INC     HL
        JR      ccx1
;
ccx2:	INC     DE
        INC     B
        LD      A,(DE)
        OR      A
        JR      Z,ccx2
        JR      ccx4
;
ccx3:	LD      A,B
        LD      (cursor_x),A
        RET


; Calculate position of pointer on line buffer.
;
calc_pointer_x:
        LD      HL,line_buffer
        LD      A,(cursor_x)
        LD      C,A
        LD      B,0
        LD      DE,tab_info_table
;
cpx1:	LD      A,C
        OR      A
             JR      Z,cpx3
        LD      A,(HL)
        CP      __TAB
        JR      Z,cpx2
        CP      __CR
        JR      Z,cpx3
        OR      A
        JR      Z,cpx3
        INC     DE
        DEC     C
cpx4:	INC     B
        INC     HL
        JR      cpx1
;
cpx2:	DEC     C
        INC     DE
        LD      A,(DE)
        OR      A
        JR      NZ,cpx4
        LD      A,C
        OR      A
        JR      Z,cpx3
        JR      cpx2
;
cpx3:	LD      A,B
        LD      (pointer_x),A
        RET


; Calcutate cursor position: x on screen.
;
calc_locate_x:
        LD      A,(view_offset)
        LD      L,A
        LD      A,(console_x)
        LD      H,A
        LD	A,(console_width)
        DEC     A
        LD      D,A
        LD      A,(cursor_x)
        SUB     L
        LD      E,A
        RET     C
        SUB     D
        JP      NC,scf_ret
        LD      A,E
        ADD     A,H
        LD            (locate_xy),A
        RET


; Calcurate cursor position: y on scrren.
;
calc_locate_y:
        LD      HL,(pointer_line)
        LD      BC,(view_line)
        OR      A
        SBC           HL,BC
        LD      A,(console_y)
        ADD     A,L
        LD      (locate_xy+1),A
        RET


; Get line from text to line buffer.
;
get_line:
        CALL    get_l0
        LD      A,C
        LD      (line_length),A
        XOR     A
        LD      (flag_edited),A
        RET
;
get_l0: LD      HL,(pointer_adr)
        LD      DE,line_buffer
        LD      IY,tab_info_table
        LD      B,1
        LD      C,1
get_l1:	LD      A,(HL)
        LD      (DE),A
        CP      __CR
        RET     Z
        OR      A
        RET     Z
        CP      __TAB
        JR      Z,get_l3
        INC     B
        JR      Z,get_l2
        INC     IY
get_l4:	INC     HL
        INC     DE
            INC     C
        JR      get_l1
;
get_l2:	LD      A,__CR
        LD      (DE),A
        LD      DE,1
        PUSH	HL
        CALL    move_text_plus
        POP     HL
        RET     C
        LD      (HL),__CR
        LD      (IX+1),0
        CALL    view_text
        RET
;
get_l3: INC     B
        JP      Z,get_l2
        INC	IY
        LD      A,(IY)
        OR      A
        JR      Z,get_l3
        JR      get_l4


; Put line from line buffer to text.
;
put_line:
        LD      A,(flag_edited)
        OR      A
        RET	Z
        CALL    calc_line_length
        LD      A,(line_length)
        SUB     B
        JR      Z,put_l0
        JR      C,put_l2
        JR      put_l3
;
put_l0:	LD      HL,(pointer_adr)
        LD      DE,line_buffer
put_l1: LD      A,(DE)
        LD      (HL),A
        CP      __CR
        JR      Z,put_l4
        OR      A
        JR      Z,put_l4
        INC     HL
        INC     DE
        JR      put_l1
;
put_l2:	NEG
        LD      D,0
        LD      E,A
        LD      HL,(pointer_adr)
        CALL    next_line
        CALL    move_text_plus
        RET     C
        JR      put_l0
;
put_l3:	LD      D,0
        LD      E,A
        LD      HL,(pointer_adr)
        CALL    next_line
        CALL    move_text_minus
        JR      put_l0
;
put_l4:      CALL    edited_text
        OR      A
        RET


; Text move form HL to HL+DE.
;
move_text_plus:
        PUSH    HL
        LD      HL,(text_free)
        OR      A
        SBC     HL,DE
        POP     HL
        JR      C,mtp1
        PUSH    DE
        LD      DE,(text_end)
        EX      DE,HL
        OR      A
        SBC     HL,DE
        LD      B,H
        LD      C,L
        INC     BC
        POP     HL
        LD      DE,(text_end)
        ADD     HL,DE
        EX      DE,HL
        LD      (text_end),DE
        LDDR
mtp0:	CALL    edited_text
        CALL    calc_text_free
        CALL    view_free
        OR      A
        RET
mtp1:	CALL    warn_mem_over
        SCF
        RET


; Text move from HL to HL-DE.
;
move_text_minus:
        PUSH    HL
        PUSH    DE
        LD      D,H
        LD      E,L
        LD      HL,(text_end)
        OR      A
        SBC     HL,DE
        LD      B,H
        LD      C,L
        INC           BC
        POP     DE
        POP     HL
        PUSH    HL
        SBC     HL,DE
        LD      D,H
        LD      E,L
        POP     HL
        LDIR
        DEC     DE
        LD      (text_end),DE
        JP      mtp0


; Calcurate line length on line buffer.
;
calc_line_length:
        LD            HL,line_buffer
        LD      B,0
cll1:	INC     B
        LD      A,(HL)
        INC     HL
        CP      __CR
        JR      Z,cll2
        OR      A
        JR      Z,cll2
        JR      cll1
cll2:	LD      A,B
        RET


; Check if memory over: (text_end)+DE
;
check_mem_over:
        PUSH    DE
        PUSH    HL
        LD      HL,(text_end)
        ADD     HL,DE
        LD      DE,(text_max)
        OR      A
        SBC     HL,DE
        POP     HL
        POP     DE
        JP      NC,scf_ret
        OR      A
        RET


; Check if colum is over than 255.
;
line_over_check:
        LD      HL,line_buffer
        
        LD      B,1
        LD      DE,tab_info_table
;
loc1:	LD      A,(HL)
        CP      __TAB
        JR      Z,loc2
        CP      __CR
        RET     Z
        OR      A
        RET	Z
        INC     B
        JP      Z,scf_ret
        INC     DE
loc4:	INC     HL
        JR      loc1
;
loc2:  INC     B
        JP      Z,scf_ret
        INC     DE
        LD      A,(DE)
        OR      A
        JR      Z,loc2
        JR      loc4


; Calcurate pointer on line buffer to HL.
;
calc_pointer_inline:
        LD      HL,line_buffer
        LD      B,0
        LD      A,(pointer_x)
        LD      C,A
        ADD     HL,BC
        RET


; Exit out of escape mode.
;
exit_escape_mode:
        XOR     A
        LD      (escape_mode),A
        CALL    delete_mark
        CALL    view_type_mode
        RET


; Delete mark
;
delete_mark:
        XOR     A
        LD      (flag_mark),A
        CALL    clr_mark_colum
        RET


; Do mark.
;
set_mark:
        LD      HL,(pointer_line)
        LD      (mark_1_line),HL
        LD      A,(pointer_x)
        LD      (mark_1_x),A
        LD      HL,(pointer_adr)
        LD      (mark_1_adr),HL
        LD      A,(cursor_x)
        LD      (mark_1_cr_x),A
        XOR     A
        DEC     A
        LD      (flag_mark),A
        CALL    view_mark_colum
        CALL    view_mark_x
        CALL    view_mark_line
        RET
set_mark_2:
        LD      HL,(pointer_line)
        LD	(mark_2_line),HL
        LD      A,(pointer_x)
        LD      (mark_2_x),A
        LD      HL,(pointer_adr)
        LD      (mark_2_adr),HL
        LD      A,(cursor_x)
        LD      (mark_2_cr_x),A
        RET
get_mark_1:
        LD      HL,(mark_1_line)
        LD      (pointer_line),HL
        LD      A,(mark_1_x)
        LD      (pointer_x),A
        LD      HL,(mark_1_adr)
        LD      (pointer_adr),HL
        LD      A,(mark_1_cr_x)
        LD      (cursor_x),A
        RET
get_mark_2:
        LD      HL,(mark_2_line)
        LD      (pointer_line),HL
        LD      A,(mark_2_x)
        LD      (pointer_x),A
        LD      HL,(mark_2_adr)
        LD      (pointer_adr),HL
        LD      A,(mark_2_cr_x)
        LD      (cursor_x),A
        RET


; This line has edited.
;
edited_line:
        XOR     A
        DEC     A
        LD      (flag_edited),A
        RET
        

; This text has edited.
;
edited_text:
        XOR     A
        DEC     A
        LD      (edited_file),A
        RET


; Insert letter in line.
;
insert_type:
        PUSH    AF
        CALL    save_line_1
it3:	LD      HL,line_buffer
        INC     H
             LD      D,H
        LD      E,L
        DEC     HL
        LD      A,(pointer_x)
        PUSH    HL
        LD	HL,101H
        LD      B,0
        LD      C,A
        OR      A
        SBC     HL,BC
        LD      B,H
        LD      C,L
        POP     HL
        LDDR
        CALL    calc_pointer_inline
it2:	POP     AF
        LD      (HL),A
        CALL    line_over_check
        JR      C,it1
        INC     C
        LD      A,C
        LD      (pointer_x),A
        CALL    edited_line
        RET
it1:	CALL    load_line_1
        CALL	warn_line_over
        SCF
        RET


; Change letter.
;
over_type:
        PUSH    AF
        CALL    save_line_1
        CALL    calc_pointer_inline
        LD      A,(HL)
        CP      13
        JP      Z,it3
        OR    A
        JP      Z,it3
        JP      it2


; Calcurate pointer_line and pointer_x by HL
;
calc_pointer_line_x_add:
        LD      BC,(pointer_line)
        DEC     BC
        LD      D,H
        LD      E,L
        LD      HL,(pointer_adr)
cplx0:	PUSH    HL
        OR      A
        SBC     HL,DE
        PUSH    AF
        LD      A,H
        OR      L
        JR      Z,cplx2
        POP     AF
        POP     HL
        JR      NC,cplx1
        CALL    next_line
        INC     BC
        JR      C,cplx1
        JR      cplx0
cplx1:	PUSH    DE
            CALL    back_line
        POP     DE
cplx3:	LD      (pointer_line),BC
        LD      (pointer_adr),HL
        EX      DE,HL
        OR      A
        SBC     HL,DE
        LD      A,L
        LD      (pointer_x),A
        RET
cplx2:	POP     AF
        POP     HL
        INC	BC
        JR      cplx3


;-------------------------------------
; Undo/Copy buffer operation


save_line_1:
        LD      HL,line_buffer
        LD      DE,(undo_1_b_adr)
        
        LD      BC,100H
        CALL    _POKE@
        RET
load_line_1:
        LD      HL,line_buffer
        LD      DE,(undo_1_b_adr)
        LD      BC,100H
        CALL    _PEEK@
        RET


; Save to copy buffer from HL to HL+DE
;
save_copy:
        PUSH    HL
        PUSH    DE
        CALL    check_copy_size
        JR      C,sc1
        LD      (copy_length),DE
        LD      B,D
        LD      C,E
        LD      DE,(copy_b_adr)
        CALL    _POKE@
sc0:    POP     DE
        POP     HL
        RET
sc1:	CALL    warn_mem_over
        SCF
        JR      sc0


; Load from copy buffer to HL
;
load_copy:
        PUSH	HL
        PUSH    DE
        LD      DE,(copy_length)
        PUSH    HL
        PUSH    DE
        CALL    move_text_plus
        POP     BC
        POP     HL
        JR      C,l_c1
        LD      DE,(copy_b_adr)
        CALL    _PEEK@
        OR      A
l_c1:        POP     DE
        POP     HL
        RET


; Check if over than buffer size
;
check_copy_size:
        PUSH    HL
        LD      HL,(buffer_size)
        OR      A
        SBC	HL,DE
        POP     HL
        RET


swap_mark_pointer:
               LD      HL,(mark_2_line)
        LD      DE,(mark_1_line)
        OR      A
        SBC     HL,DE
        JR      Z,smp1
        RET     C
        CALL    swap_mark_pointer_line
        CALL    swap_mark_pointer_x
        CALL    save_pointer
        RET
smp1:	LD      A,(mark_1_x)
        LD      B,A
        LD      A,(mark_2_x)
        CP      B
        RET     C
        CALL    swap_mark_pointer_x
        CALL    save_pointer
        RET


swap_mark_pointer_x:
        LD      A,(mark_1_x)
               LD      B,A
        LD      A,(mark_2_x)
        LD      (mark_1_x),A
        LD	A,B
        LD      (mark_2_x),A
        LD      A,(mark_1_cr_x)
        LD      B,A
        LD      A,(mark_2_cr_x)
        LD      (mark_1_cr_x),A
        LD      A,B
        LD      (mark_2_cr_x),A
        RET


swap_mark_pointer_line:
        LD      HL,(mark_1_line)
        LD      DE,(mark_2_line)
        LD      (mark_1_line),DE
        LD      (mark_2_line),HL
        LD      HL,(mark_1_adr)
        LD      DE,(mark_2_adr)
        LD      (mark_1_adr),DE
        LD      (mark_2_adr),HL 
        RET


save_pointer:
        LD      A,(pointer_x)
        LD      (u_pointer_x),A
        LD      A,(cursor_x)
        LD      (u_cursor_x),A
        LD      HL,(pointer_line)
        LD      (u_pointer_line),HL
        LD      HL,(pointer_adr)
        LD      (u_pointer_adr),HL
        RET


load_pointer:
        LD      A,(u_pointer_x)
        LD      (pointer_x),A
        LD      A,(u_cursor_x)
        LD      (cursor_x),A
        LD      HL,(u_pointer_line)
        LD      (pointer_line),HL
        LD      HL,(u_pointer_adr)
        LD      (pointer_adr),HL
        CALL    save_cursor_x
        RET


;-------------------------------------
; SCREEN OPE


view_screen:
               LD      A,__CLS
        CALL    _PRINT
        CALL    view_colums
        RET


view_text:
        LD      HL,(view_adr)
        LD      A,(console_length)
        LD      C,A
        XOR     A
        LD      D,A
        LD      B,A
        LD	(line_print_y),A
vw_t1:	LD      (line_data_adr),HL
;
         LD      A,B
            LD      (line_print_y),A
        LD      (IX),D
        LD      A,(IX+1)
        OR      A
        JR      Z,vw_t4
        PUSH	BC
        PUSH    HL
        LD      BC,(pointer_adr)
        OR      A
        SBC     HL,BC
        LD      A,H
        OR      L
        POP     HL
        POP     BC
        CALL    NZ,line_print
        JR      vw_t5
vw_t4:	CALL    line_print
vw_t5:	INC     B
        CALL    next_line
        JR      C,vw_t2
vw_t3: 	DEC     C
        JR      NZ,vw_t1
        RET
;
vw_t2:  LD      D,2
        JR      vw_t3


view_line_buffer:
        LD      HL,line_buffer
        LD      (line_data_adr),HL
        LD      A,(locate_xy+1)
        LD      (line_print_y),A
        XOR     A
        LD      (IX),A
        CALL    line_print
        RET
        

view_colums:
        CALL    view_filename
        CALL    view_free_colum
        CALL    view_pointer_colum
        CALL    view_type_mode
        CALL    view_free
        RET


view_filename:
        LD      HL,(v_fnam_xy)
        CALL    _LOC
        LD      A,"["
        CALL    _PRINT
        LD      DE,filename
        CALL    _MSX
        LD      A,"]"
        CALL    _PRINT
        RET


view_free_colum:
        LD      HL,(v_free_xy)
        CALL    _LOC
        LD      DE,free_colum
        CALL    _MSX
        RET


view_pointer_colum:
        LD      HL,(v_pointer_xy)
        CALL    _LOC
        LD      DE,pointer_colum
        CALL    _MSX
        RET


view_mark_colum:
        LD      HL,(v_mark_xy)
        CALL    _LOC
        LD      DE,mark_colum
        CALL    _MSX
        RET


clr_mark_colum:
        LD      HL,(v_mark_xy)
        CALL    _LOC
        LD      DE,colum_clr
        CALL    _MSX
        RET


view_type_mode:
        LD      HL,(v_mode_xy)
        CALL    _LOC
        LD      A,(escape_mode)
        OR      A
        JR      Z,v_m1
        LD	DE,s_escape
v_m0:	CALL    _MSX
        RET
v_m1:	LD      A,(type_mode)
        OR      A
        JR      Z,v_m2
        LD      DE,s_overtype
        JR      v_m0
v_m2:	LD	DE,s_insert
        JR      v_m0


view_free:
        LD      HL,(free_xy)
        CALL    _LOC
        LD      HL,(text_free)
        CALL    print_HL
        RET


view_cursor_x:
        LD      HL,(pointer_x_xy)
        CALL	_LOC
        LD      A,(cursor_x)
        INC     A
        CALL    print_A
        RET


view_pointer_line:
        LD      HL,(pointer_line_xy)
        CALL    _LOC
        LD      HL,(pointer_line)
        INC     HL
        CALL    print_HL
        RET


view_mark_x:
        LD      HL,(mark_x_xy)
        CALL    _LOC
        LD      A,(mark_1_cr_x)
        INC     A
        CALL    print_A
        RET


view_mark_line:
        LD      HL,(mark_line_xy)
        CALL    _LOC
        LD      HL,(mark_1_line)
        INC     HL
        CALL    print_HL
        RET


warn_line_over:
        LD      HL,(v_mode_xy)
        CALL    _LOC
        LD      DE,s_line_over
        CALL    _MSX
        CALL    _BELL
        RET


warn_mem_over:
        LD      HL,(v_mode_xy)
        CALL    _LOC
        LD      DE,s_mem_over
        CALL    _MSX
        CALL    _BELL
        RET


clr_botom:
        LD      HL,(v_mode_xy)
        CALL    _LOC
        LD      A,(console_width)
        DEC     A
        LD      B,A
cb1:	CALL    _PRNTS
        DJNZ	cb1
        RET


view_botom:
        CALL    clr_botom
        CALL    view_type_mode
        CALL    view_free_colum
        CALL    view_pointer_colum
        CALL    view_pointer_line
        CALL    view_free
        RET


mes_file_open:
        LD      DE,mes_2
        CALL    _MSX
        LD      DE,filename
        CALL    _MSX
        CALL    _LTNL
        RET


mes_file_close:
        LD      DE,mes_3
        CALL	_MSX
        LD      DE,filename
        CALL    _MSX
        CALL    _LTNL
        RET
        

;-------------------------------------
; Asks


ask_save:
        CALL    clr_botom
        LD      HL,(v_mode_xy)
        CALL    _LOC
        LD      DE,mes_4
        CALL    _MSX
        CALL    _FLGET
        PUSH    AF
        CALL    view_botom
        POP     AF
        AND     0DFH
        CP      "C"
        JP      Z,scf_ret
        CP      "N"
        JR      Z,a_s2
        CP      "S"
        JR      Z,a_s3
        JR      ask_save
;
a_s2:	XOR     A
        DEC     A
        OR      A
        RET
;
a_s3:   XOR     A
        RET


pause:
        LD      DE,mes_5
        CALL    _MSX
        CALL    _FLGET
        RET


;-------------------------------------
; FILE OPE


new_file:
        LD      A,4             ; entry : DE
n_f1:	CALL    _FILE
        CALL    get_filename
          CALL    text_clear
        RET


file_open_r:
        LD      A,4             ; entry : DE
        CALL    _FILE
        CALL    get_filename
        CALL    mes_file_open
        CALL    _ROPEN
        RET


file_open_w:
        LD      A,4             ; entry : DE
        CALL    FILE
        CALL    get_filename
        CALL    mes_file_close
        LD      HL,0
        LD      (_DTADR),HL
        LD      (_EXADR),HL
        CALL    calc_text_size
        LD      HL,(text_size)
        LD      (_SIZE),HL
        CALL    _WOPEN
        RET


file_read:
        LD      DE,(_SIZE)
        LD      HL,(text_area)
        SBC     HL,DE
        JR      NZ,f_r1
        LD      A,15
        RET
f_r1:	LD	HL,(text_start)
        LD      (_DTADR),HL
        CALL    _RDD
        CALL    calc_text_size
        RET


file_write:
        LD      HL,(text_start)
        LD      (_DTADR),HL
        LD      (_EXADR),HL
        LD      HL,(text_size)
        LD      (_SIZE),HL
        CALL    _WRD
        RET


get_filename:
        LD      HL,filename
        LD      A,(_DSK)
        LD      (HL),A
        INC     HL
        LD      (HL),":"
        INC     HL
        LD      DE,(_IBFAD)
        LD      B,__CR
        CALL    g_f1
        LD      (HL),"."
        INC     HL
        LD      B,3
        CALL    g_f1
        LD      (HL),0
        RET
g_f1:	INC     DE
        LD      A,(DE)
        LD      (HL),A
        INC     HL
        DEC     B
        JR      NZ,g_f1
        RET


save_file:
        CALL    file_open_w
        JP      C,f_err
        CALL    file_write
        JP      C,f_err
        XOR     A
        LD      (edited_file),A
        RET


close_file:
        LD      A,(edited_file)
        OR      A
        RET     Z
        PUSH    DE
        CALL    ask_save
        POP     DE
        RET     C
        RET     NZ
        LD      A,__CLS
        CALL    _PRINT
        LD      DE,filename
        CALL    save_file
        RET


load_file:
        CALL    file_open_r
        JP      C,f_err
        CALL    file_read
        JP      C,f_err
        XOR     A
        LD	(edited_file),A
        RET


f_err:
        CP      15
        JR      Z,f_err1
        CALL    _ERROR
f_err0: CALL    pause
        RET
f_err1:	LD      DE,mes_6
        CALL    _MSX
        CALL    _BELL
        JR      f_err0


;-------------------------------------
; SUBROUTINES


division16:
        LD      HL,0            ; DE <= DE / BC
        LD      A,16            ; HL <= DE MOD BC
div161: SLA	E
        RL      D
        ADC     HL,HL
        SBC	HL,BC
        JR      C,div162
        INC     E
        JR      div163
div162: ADD     HL,BC
div163: DEC      A
        JR      NZ,div161
        RET


division8:
        LD      A,0             ; D <= D / E
        LD            B,8             ; A <= D MOD E
div81:  SLA     D
        ADC     A,A
        SBC     A,E
        JR      C,div82
        INC     D
        JR      div83
div82:	ADD     A,E
div83:	DJNZ	div81
        RET


print_HL:
        PUSH    HL
        PUSH    DE
        PUSH    BC
        PUSH    AF
        XOR     A
        LD      (IX),A
        LD      BC,10000
        EX      DE,HL
        CALL    division16
        LD      A,E
        CALL    print_number
        LD      BC,1000
        EX      DE,HL
        CALL    division16
        LD      A,E
        CALL    print_number
        LD      BC,100
        EX      DE,HL
        CALL division16
        LD      A,E
        CALL    print_number
        LD      BC,10
        EX      DE,HL
        CALL    division16
        LD      A,E
        CALL    print_number
        LD      A,L
        ADD     A,30H
        CALL    _PRINT
        POP     AF
        POP     BC
        POP     DE
        POP     HL
        RET


print_A:
        PUSH    DE
        PUSH    AF
        LD      D,A
        XOR     A
        LD      (IX),A
        LD      E,100
        CALL    division8
        LD      E,A
        LD      A,D
        CALL    print_number
        LD      D,E
        LD      E,10
        CALL    division8
        LD      E,A
        LD      A,D
        CALL    print_number
        LD      A,E
        ADD     A,30H
        CALL    _PRINT
        POP     AF
        POP     DE
        RET


print_number:
        PUSH    BC
        LD      B,A
        CP      0
        JR      NZ,prt_n1
        LD      A,(IX)
        CP      0
        JR      NZ,prt_n1
        LD      A," "
        CALL    _PRINT
        POP     BC
        RET
prt_n1: LD A,B
        ADD     A,30H
        CALL    _PRINT 
        LD      A,1
        LD      (IX),A
        POP     BC
        RET


; HEXCUL
;
get_number:
        LD      HL,0
g_n1:	LD      A,(DE)
        SUB     30H
        CP      0AH
        RET     NC
        INC     DE
        ADD     HL,HL
        RET     C
        LD      B,H
        LD      C,L
        ADD     HL,HL
        RET     C
        ADD     HL,HL
        RET     C
        ADD     HL,BC
        RET     C
        LD      B,0
        LD      C,A
        ADD     HL,BC
        JR      NC,g_n1
        RET


;-------------------------------------
; Data area

startup_mes:	DB      "Screen Editor for S-OS SWORD",__CR
                DB      "FE version "
version: 	DB      "1.01 "
                DB      __CR,__CR,0
mes_1:		DB      "New file.",__CR,0
mes_2:		DB      "Now loading ",0
mes_3:		DB      "Now saving ",0
mes_4:		DB      "(S)ave / (N)ot save / (C)ancel ? ",0
mes_5:		DB      "Hit any key. ",0
mes_6:		DB      "Memory is full.",__CR,0
mes_7:		DB      "(E)dit / (M)ore find / (C)ommand",0
mes_8:		DB      "(R)eplace / (S)kip / (A)ll / (C)ommand",0
free_colum:	DB      "[FREE:     ]",0
pointer_colum:	DB      "[PNTR:   :     ]",0
mark_colum:	DB      "[MARK:   :     ]",0
colum_clr:	DB      "                ",0
s_overtype:	DB      "OVERTYPE  ",0
s_insert:       DB      "INSERT    ",0
s_escape:       DB      "ESC       ",0
s_line_over:    DB      "LINE OVER!",0
s_mem_over:	DB      "MEM OVER!!",0
s_command:      DB      "COMMAND >>",0
tab_width:      DB      8
chr_TAB_swap:	DB      " "
chr_CR_swap:	DB      " "


skip_character_number:
                DB      25
skip_character_table:
                DB      009H,020H,022H,027H,028H,029H,02AH,02BH
                DB      02CH,02DH,02FH,03AH,03BH,03H,03DH,03EH
                DB      05BH,05DH,07BH,07EH,0A1H,0A2H,0A3H,0A4H
                DB      0A5H

control_code_table:
        DW      c_null                  ; 0
        DW      c_right                 ; 1
        DW      c_left                  ; 2
        DW      c_up			; 3
        DW      c_down                  ; 4
        DW      c_up_page               ; 5
        DW      c_down_page             ; 6
        DW      c_escape                ; 7
        DW      c_quit			; 8
        DW      c_change_typemode	; 9
        DW      c_tab_hid               ; 10
        DW      c_skip_foward           ; 11
        DW      c_skip_back             ; 12
        DW      c_tab                   ; 13
        DW      c_back_space            ; 14
        DW      c_cr                    ; 15
        DW      c_block_delete          ; 16
        DW      c_block_cut             ; 17
        DW	c_block_copy            ; 18
        DW      c_block_paste           ; 19
        DW      c_cr_hid                ; 20
        DW      c_command_mode		; 21
        DW      c_tab_width_change      ; 22
        DW      c_cursor_top            ; 23
        DW      c_cursor_botom          ; 24


control_code_table_cmd:
        DW      c_null			; 0
        DW      c_right_cmd             ; 1
        DW      c_left_cmd              ; 2
        DW      c_null                  ; 3
        DW      c_null                  ; 4
        DW      c_null			; 5
        DW      c_null                  ; 6
        DW      c_escape_cmd            ; 7
        DW      c_null                  ; 8
        DW      c_change_typemode       ; 9
        DW      c_null                  ; 10
        DW      c_null                  ; 11
        DW      c_null                  ; 12
        DW      c_tab                   ; 13
        DW      c_back_space_cmd        ; 14
        DW	c_cr_cmd                ; 15
        DW      c_null                  ; 16
        DW      c_null                  ; 17
        DW      c_null                  ; 18
        DW      c_null                  ; 19
        DW      c_null			; 20
        DW      c_reserved              ; 21
        DW      c_reserved              ; 22
        DW      c_reserved              ; 23
        DW      c_reserved		; 24

END_OF_PROGRAM:


        DS      WORK_AREA - END_OF_PROGRAM


;-------------------------------------
; Work area


        ORG     4580H


WORK_AREA:


mem_min:     	DS      2
mem_max:     	DS      2
text_start:	DS      2
text_end:    	DS      2
text_max:    	DS      2
text_size:   	DS      2
text_free:	DS      2
text_area:	DS      2
;
edited_file:	DS      1
;
console_x:	DS      1
console_y:	DS      1
console_width:	DS      1
console_length:	DS      1
;
v_free_xy:	DS      2
v_pointer_xy:	DS      2
v_mark_xy:	DS      2
v_fnam_xy:	DS	2
v_mode_xy:	DS      2
;
free_xy:	DS      2
pointer_x_xy:	DS      2
pointer_line_xy:
        	DS	2
mark_x_xy:	DS      2
mark_line_xy:	DS      2
;
view_offset:	DS      1
view_line:	DS      2
view_adr:	DS      2
pointer_x:	DS      1
pointer_line:	DS      2
pointer_adr:	DS      2
cursor_x:	DS      1
cursor_x_keep:	DS      1
locate_xy:	DS      2
;
u_pointer_x:	DS      1
u_pointer_line:	DS      2
u_pointer_adr:	DS      2
u_cursor_x:	DS      1
;
flag_mark:	DS      1
mark_1_x:	DS      1
mark_1_cr_x:	DS      1
mark_1_line: 	DS      2
mark_1_adr:  	DS      2
mark_2_x:    	DS      1
mark_2_cr_x: 	DS      1
mark_2_line: 	DS      2
mark_2_adr:  	DS      2
;
flag_cmd_mode:	DS	1
;
copy_length:	DS	2
DS      1
;
line_length:	DS      1
flag_edited:	DS	1
edited_length:	DS      1
;
line_print_y:	DS	1
line_data_adr:	DS      2
chr_atri:	DS      1
;
type_mode:	DS      1
escape_mode: 	DS	1
;
undo_1_b_adr:	DS	2
find_b_adr: 	DS      2
replace_b_adr:	DS      2
copy_b_adr:	DS	2
buffer_size     DS      2
;
flag_replace_all:
                DS      1
find_str_len:   DS      1
replace_str_len:DS      1
;
local_work:     DS      4
filename:       DS      20
tab_info_table: DS      256
line_buffer:    DS      256
                DS      4



;-----------------------------------
;
;  line_print routine for FE v1.05
;  for X1/X1turbo non Kanji
;
;-----------------------------------


_WIDTH		EQU     1F5CH


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
lp2:	LD      A,(console_width)
        LD      D,A
        DEC     D
lp3:	CALL    next_chr
;
        OUT     (C),A
        RES     4,B
        LD      A,(chr_atri)
        OUT     (C),A
        SET     4,B
        SET     3,B
        XOR     A
        OUT     (C),A
        RES     3,B
        INC     BC
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
        LD      C,L
        LD      A,H
        ADD           A,A
        ADD     A,A
        ADD     A,H
        LD      H,0
        LD      L,A
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        LD      A,(_WIDTH)
        CP      80
        JR      NZ,loc_i1
        ADD     HL,HL
loc_i1:	LD      B,30H
        ADD     HL,BC
        LD      B,H
        LD      C,L
        RET

