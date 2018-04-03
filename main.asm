;
; game_proj_2.asm
;
; Created: 3/17/2018 07:29:29
; Author : SHADOW
;

;	r28 and r29 will be used as pointers into memory (yHigh and yLow)
;	r26 will be used for incrementing the level
;	r25 will have the leds output
;	r24 will be used by the game_manager to count the current displaying pattern
;	r23 will be used for reading player input
;	r22 will be used for player press assertion
;	r21 will be used for counting correct guessed patterns
;	r20, r19, r18 will be used for the delay loop
;	r17 will be used to track the random seed
;	r1 will always be used to compare if a value is 0


	.dseg								;	Data segment
	.org $420							;	Start storing at 0x420
	storage: .byte 1					;	Allocate 1 byte for storage (the pattern only has 8 bits - for 8 leds)

	.cseg								;	Start code segment

	ldi yH, high(storage)				;	y High byte pointer
	ldi yL, low(storage)				;	y Low byte pointer

;	stack setup
	ldi r16, high(RAMEND)				;	0x21
	out sph, r16
	ldi r16, low(RAMEND)				;	0xff
	out spl, r16

;	configuration of port
	ldi r16, 0b11111111
	out ddra, r16
	out porta, r16
	ldi r16, 0b00000000
	out ddrc, r16

;	fill data registers
	ldi r16, 2							;	current level
	sts $200, r16						;	data space for current level

.macro show								;	display on the leds whatever data is in r25
	out porta, r25
.endmacro

.macro lights_off						;	turn all the leds off
	ldi r25, 0b11111111
	out porta, r25
.endmacro

.macro store_pattern					;	stores the pattern and increments the pointer					
	st y+, @0
.endmacro

.macro quick_flash						;	display if the current level was passed
	ldi r16, 0b00000000
	out porta, r16
	call delay3
	ldi r16, 0b11111111
	out porta, r16
	call delay3
	ldi r16, 0b00000000
	out porta, r16
	call delay3
	ldi r16, 0b11111111
	out porta, r16
	call delay3
.endmacro

.macro increment_level					;	adds one to the current level
	lds r26, $200						;	load previous value of the level
	add yL, r26							;	reset the pointer to the end of the pattern
	inc r26								;	increment r26
	sts $200, r26						;	store incremented level
	store_pattern r16					;	store the new pattern from r16 (calculated in next_level)
.endmacro


load_first_patterns:					;	first 2 patterns are loaded by hand and will always be the same
    ldi r16, 0b1111_1110
	store_pattern r16
	ldi r16, 0b1111_1101
	store_pattern r16

game_manager:
	ldi r17, 255						;	load 255 to seed register
	lds r24, $200						;	load current game level
	call display						;	display current game level, the pointer will be shifted to the end of the pattern memory
	lds r24, $200
	lds r21, $200						;	load current game level
	add yL, r24							;	add the game level to the pattern pointer (reset the pointer to the start of the level)
	lights_off
	call player_turn



display:								;	displays all remaining patterns for the current level
	ld r25, -y							;	loads into r25 the current pattern to dispaly
	show								;	shows the pattern
	call delay							;	calls a delay so the pattern can be seen
	dec r24								;	decrements the pattern counter since one was displayed already
	cp r24, r1							;	compare the pattern counter with 0 (are there more patterns to display?)
	brne display						;	if there are more patterns call display again
	ret									;	done, return to caller

player_turn:

	dec r17								;	decrement the seed number
	cp r17, r1							;	if the seed reaches 0, reset the seed to 255
	breq reset_seed						;	brach into reset

	ldi r23, 0b1111_1111				;	Fill r23 with ones	
	in r25, pinc						;	Load data from pinc to r25 register
	cp r23, r25							;	Compare if the player input is full of ones (no player input)
	brne assert_player_press			;	If there is input, jump to assertion
	rjmp player_turn					;	No input, keep waiting, ToDo: maybe implement a counter ???

assert_player_press:
	show								;	Shows the led corresponding to the press
	ld r22, -y							;	Load the coresponding pattern into r22
	cp r25, r22							;	Compare if the player input matches the coresponding pattern
	brne lost_lel						;	No match, jump to lost
	call delay

	dec r21								;	decrease guessed patterns counter
	cp r21, r1							;	compare if guessed pattern counter has reached level number
	breq next_level						;	go to next level if all patterns were guessed

	lights_off
	call player_turn					;	Pattern matched and there are more patterns in this level

lost_lel:								;	Noob
	ldi r16, 0b01010101
	out porta, r16
	call inf

next_level:
	quick_flash							;	Level complete led flash

	ldi r16, 7							;	prepare for modulo operation (a % 8 = a AND (8 - 1) = a AND 7), load 7 into r16
	and r17, r16						;	the value in r17 will be mod-ed with 8, resulting in a number between 0 and 7
										;	the number represents the bit that will be shifted to 0 (led on) in the next pattern
	ldi r16, 0b1000_0000				;	load 128 to r16, the 1 bit will be shifted to the right 'mod_result' times
	call shift_right
	ldi r17, 0b11111111					;	since r16 only has one 1 but one 0 is instead needed, r16 will be XOR-ed
	eor r16, r17						;	XOR-ing r16 will result in a flipped pattern ex -> 00010000 = 11101111 (since led is on for 0)

	increment_level						;	call for next level, the value in r16 will be added to the pattern memory
	call game_manager					;	start next level

shift_right:							;	shifts the 1 bit r17 times to the right
	LSR r16								;	r16 will initially have a value of 1000_0000
	dec r17								;	r17 contains the remaining number of shifts to apply
	cp r17, r1							;	compare if there are no more shifts	
	brne shift_right					;	loop if there are 
	ret									;	shift done

reset_seed:
	ldi r17, 255
	rjmp player_turn
	
	

delay:
	ldi r18, 255
loop_2:
	ldi r19, 255
innerloop_2:
	ldi r20, 30
mostinnerloop_2:
	dec r20
	brne mostinnerloop_2
	dec r19
	brne innerloop_2
	dec r18
	brne loop_2
	ret

delay3:
	ldi r18, 255
loop_3:
	ldi r19, 255
innerloop_3:
	ldi r20, 10
mostinnerloop_3:
	dec r20
	brne mostinnerloop_3
	dec r19
	brne innerloop_3
	dec r18
	brne loop_3
	ret

inf:
	call inf



