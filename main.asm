;
; rc5.asm
;
; Created: 5/7/2021 2:16:26 PM
; Author : Omar Bahaa
;

; setting up the stack

LDI R16, HIGH(RAMEND)
OUT SPH, R16
LDI R16, LOW(RAMEND)
OUT SPL, R16

; setting up directives

; constants:

.EQU NO_OF_ROUNDS = 8						; r
.EQU EXP_KEY_TABLE = 18						; t
.EQU WORD_SIZE_BITS = 16					; w
.EQU WORD_SIZE_BYTES = 2					; u
.EQU KEY_SIZE_BYTES = 12					; b
.EQU KEY_SIZE_WORDS = 6						; c
.EQU KEY_EXP_ROUNDS = 3 * EXP_KEY_TABLE		; n
.EQU P = 0xB7E1								; P
.EQU Q = 0x9E37								; Q

.EQU INPUT_SIZE_VALUE = 0x005				; variable input size (in terms of 2 words = 8 Bytes)
.EQU INPUT_START_LOC = 0x0180
.EQU SECKEY_START_LOC = 0x0100				; start location of K and L
.EQU KEY_START_LOC = 0x010C					; start location of S
.EQU KEY_END_LOC = (KEY_START_LOC + (EXP_KEY_TABLE * WORD_SIZE_BYTES)) - 1 + 1	; + 1 to use predecrement in decryption


; Register names:

.DEF KEY_COUNTER = R2
.DEF ROUNDS = R3
.DEF INPUT_SIZE = R7
.DEF INPUT_LOC = R28
.DEF KEY_LOC = R26

.DEF A_L = R17				; lower 8-bits of first input A
.DEF A_H = R18				; higher 8-bits of first input A
.DEF B_L = R19				; lower 8-bits of first input B
.DEF B_H = R20				; higher 8-bits of first input B

.DEF TEMP = R16				; used as temporary register for different operations

.DEF ROT_H = R22			; used in ROL and ROR
.DEF ROT_L = R23			; used in ROL and ROR
.DEF NO_OF_ROT = R24		; used in ROL and ROR

.DEF S_L = R4				; Expanded Key content at index i
.DEF S_H = R5				; Expanded Key content at index i+1
.DEF L_L = R0				; Secret Key content at index j
.DEF L_H = R1				; Secret Key content at index j+1

.DEF DEC_L = R8				; used in decrementing
.DEF DEC_H = R9				; used in decrementing

.DEF KEY_EXT_A_L = R10		; constant A in key extension algorithm
.DEF KEY_EXT_A_H = R11		
.DEF KEY_EXT_B_L = R12		; constant B in key extension algorithm
.DEF KEY_EXT_B_H = R13
.DEF KEY_EXT_i = R14		; iterator i in key extension algorithm		
.DEF KEY_EXT_j = R15		; iterator j in key extension algorithm

.DEF NUM = R21
.DEF DENOM = R25
.DEF QUOTIENT = R6

; for the secret key, K, its size is of 12 Bytes. L array, representing the secrey key, is in M[0x0100] to M[0x010B] (0x0100 + 0xC - 1) (where 0xC = 12)

; for the key array, S, its size is of 18 words = 36 Bytes. The array is from M[0x010C] to M[0x012F] (0x010C + 0x24 - 1) (where 0x24 = 36)

; for the input, its size is undefined, however stored in RX, where, it's stored from M[0x0142]

//---------------------------------------------------------------------------------------------------------------------------------------------------------

; putting key in memory
LDI TEMP,0xF0
LDI XL, LOW(SECKEY_START_LOC)
LDI XH, HIGH(SECKEY_START_LOC)
ST X+, TEMP
ST X+, TEMP
ST X+, TEMP
ST X+, TEMP
ST X+, TEMP
ST X+, TEMP
ST X+, TEMP
ST X+, TEMP
ST X+, TEMP
ST X+, TEMP
ST X+, TEMP
ST X+, TEMP

	

; putting input in memory
// 54 68 69 73 20 69 73 20 61 20 74 65 73 74 20 74 65 78 74 -> This is a test text
LDI YL, LOW(INPUT_START_LOC)
LDI YH, HIGH(INPUT_START_LOC)
LDI TEMP,0x54
ST Y+, TEMP
LDI TEMP,0x68
ST Y+, TEMP
LDI TEMP,0x69
ST Y+, TEMP
LDI TEMP,0x73
ST Y+, TEMP
LDI TEMP,0x20
ST Y+, TEMP
LDI TEMP,0x69
ST Y+, TEMP
LDI TEMP,0x73
ST Y+, TEMP
LDI TEMP,0x20
ST Y+, TEMP
LDI TEMP,0x61
ST Y+, TEMP
LDI TEMP,0x20
ST Y+, TEMP
LDI TEMP,0x74
ST Y+, TEMP
LDI TEMP,0x65
ST Y+, TEMP
LDI TEMP,0x73
ST Y+, TEMP
LDI TEMP,0x74
ST Y+, TEMP
LDI TEMP,0x20
ST Y+, TEMP
LDI TEMP,0x74
ST Y+, TEMP
LDI TEMP,0x65
ST Y+, TEMP
LDI TEMP,0x78
ST Y+, TEMP
LDI TEMP,0x74
ST Y+, TEMP


//---------------------------------------------------------------------------------------------------------------------------------------------------------



main:
	
	CALL Key_Expansion_Algorithm
	
	CALL Encryption_Algorithm

	CALL Decryption_Algorithm

End: RJMP End

//---------------------------------------------------------------------------------------------------------------------------------------------------------

Encryption_Algorithm:

LDI YL, LOW(INPUT_START_LOC)
LDI YH, HIGH(INPUT_START_LOC)

LDI TEMP, INPUT_SIZE_VALUE
MOV INPUT_SIZE, TEMP
Encryption:

	; loading input
	// A_L, A_H, B_L, B_H are the inputs and S_L and S_H are the S[i]
	// S array starts from M[0x010C] to M[0x0141]
	
	// loading A
	LD A_L, Y+
	LD A_H, Y+
	// loading B
	LD B_L, Y+
	LD B_H, Y+

	; encrypting first round
	// S <- S[0]
	LDI XL, LOW(KEY_START_LOC)
	LDI XH, HIGH(KEY_START_LOC)
	LD S_L, X+
	LD S_H, X+

	// A[0] = A[0] + S[0]
	ADD A_L, S_L
	ADC A_H, S_H

	// S <- S[1]	
	LD S_L, X+
	LD S_H, X+
	
	// B[0] = B[0] + S[1]
	ADD B_L, S_L
	ADC B_H, S_H

	;begin repeated encryption cycle 
	LDI TEMP, NO_OF_ROUNDS
	MOV ROUNDS, TEMP
	
	Encryption_loop: // i
		// Working on A
		// S <- S[2*i]
		LD S_L, X+
		LD S_H, X+

		; A[i] = A[i-1] XOR B[i-1]
		EOR A_L, B_L
		EOR A_H, B_H
		
		; A[i] = (A[i-1] XOR B[i-1]) <<< B[i-1]
		MOV ROT_L, A_L
		MOV ROT_H, A_H
		MOV NO_OF_ROT, B_L
		ANDI NO_OF_ROT, 0x0F
		CALL Rotate_Left
		MOV A_L, ROT_L
		MOV A_H, ROT_H

		; A[i] = ((A[i-1] XOR B[i-1]) <<< B[i-1]) + S[2*i]
		ADD A_L, S_L
		ADC A_H, S_H

		// Working on B
		// S <- S[2*i + 1]
		LD S_L, X+
		LD S_H, X+

		; B[i] = B[i-1] XOR A[i]
		EOR B_L, A_L
		EOR B_H, A_H

		; B[i] = (B[i-1] XOR A[i]) <<< A[i]
		MOV ROT_L, B_L
		MOV ROT_H, B_H
		MOV NO_OF_ROT, A_L
		ANDI NO_OF_ROT, 0x0F
		CALL Rotate_Left
		MOV B_L, ROT_L
		MOV B_H, ROT_H

		; B[i] = ((B[i-1] XOR A[i]) <<< A[i]) + S[2*i + 1]
		ADD B_L, S_L
		ADC B_H, S_H

		DEC ROUNDS
		BRNE Encryption_loop
	
	; storing result
	ST -Y, B_H
	ST -Y, B_L
	ST -Y, A_H
	ST -Y, A_L

	ADIW YH: YL, 4

	DEC INPUT_SIZE
	BRNE Encryption
	
RET

//---------------------------------------------------------------------------------------------------------------------------------------------------------


Decryption_Algorithm:

LDI YL, LOW(INPUT_START_LOC)
LDI YH, HIGH(INPUT_START_LOC)

LDI TEMP, INPUT_SIZE_VALUE
MOV INPUT_SIZE, TEMP
Decryption:

	; loading input
	// A_L, A_H, B_L, B_H are the inputs and S_L and S_H are the S[i]

	LD A_L, Y+
	LD A_H, Y+
	LD B_L, Y+
	LD B_H, Y+

	// S <- S[t-1]
	LDI XL, LOW(KEY_END_LOC)
	LDI XH, HIGH(KEY_END_LOC)
	
	;begin repeated decryption cycle 
	LDI TEMP, NO_OF_ROUNDS
	MOV ROUNDS, TEMP
	Decryption_loop: // i
		// Working on B
		// S <- S[2*i + 1]
		LD S_H, -X
		LD S_L, -X

		; B[i-1] = B[i] - S[2*i+1]
		SUB B_L, S_L
		SBC B_H, S_H
		
		; B[i-1] = (B[i] - S[2*i+1]) >>> A[i]
		MOV ROT_L, B_L
		MOV ROT_H, B_H
		MOV NO_OF_ROT, A_L
		ANDI NO_OF_ROT, 0x0F
		CALL Rotate_Right
		MOV B_L, ROT_L
		MOV B_H, ROT_H

		; B[i-1] = ((B[i] - S[2*i+1]) >>> A[i]) XOR A[i]
		EOR B_L, A_L
		EOR B_H, A_H

		// Working on A
		// S <- S[2*i]
		LD S_H, -X
		LD S_L, -X

		; A[i-1] = A[i] - S[2*i]
		SUB A_L, S_L
		SBC A_H, S_H
		
		; A[i-1] = (A[i] - S[2*i]) >>> B[i-1]
		MOV ROT_L, A_L
		MOV ROT_H, A_H
		MOV NO_OF_ROT, B_L
		ANDI NO_OF_ROT, 0x0F
		CALL Rotate_Right
		MOV A_L, ROT_L
		MOV A_H, ROT_H

		; A[i-1] = ((A[i] - S[2*i]) >>> B[i-1]) XOR B[i-1]
		EOR A_L, B_L
		EOR A_H, B_H

		DEC ROUNDS
		BRNE Decryption_loop
	
	; decryption last round
	// loading S[1]
	LD S_H, -X
	LD S_L, -X
	
	// B[0] = B[0] + S[1]
	SUB B_L, S_L
	SBC B_H, S_H

	// S <- S[0]	
	LD S_H, -X
	LD S_L, -X
	
	// A[0] = A[0] + S[0]
	SUB A_L, S_L
	SUB A_H, S_H

	; storing result
	ST -Y, B_H
	ST -Y, B_L
	ST -Y, A_H
	ST -Y, A_L


	ADIW YH: YL, 4

	DEC INPUT_SIZE
	BRNE Decryption
	RJMP END

RET


//---------------------------------------------------------------------------------------------------------------------------------------------------------



; for the secret key, K, its size is of 12 Bytes. L array, representing the secrey key, is in M[0x0100] to M[0x010B] (0x0100 + 0xC - 1) (where 0xC = 12)
; for the key array, S, its size is of 18 words = 36 Bytes. The array is from M[0x010C] to M[0x012F] (0x010C + 0x24 - 1) (where 0x24 = 36)

Key_Expansion_Algorithm:

LDI XL, LOW(KEY_START_LOC)
LDI XH, HIGH(KEY_START_LOC)

LDI TEMP, LOW(P)
MOV S_L, TEMP
LDI TEMP, HIGH(P)
MOV S_H, TEMP

ST X+, S_L
ST X+, S_H

LDI R22, LOW(Q)
LDI R23, HIGH(Q)

LDI TEMP, EXP_KEY_TABLE - 1
MOV ROUNDS, TEMP

Key_exp_loop1:	
	ADD S_L, R22
	ADC S_H, R23
	ST X+, S_L
	ST X+, S_H
	DEC ROUNDS
	BRNE Key_exp_loop1


LDI TEMP, 0
MOV KEY_EXT_A_L, TEMP
MOV KEY_EXT_A_H, TEMP
MOV KEY_EXT_B_L, TEMP
MOV KEY_EXT_B_H, TEMP
MOV KEY_EXT_i, TEMP
MOV KEY_EXT_j, TEMP
LDI TEMP, KEY_EXP_ROUNDS
MOV ROUNDS, TEMP

LDI XH, HIGH(KEY_START_LOC)
LDI YH, HIGH(SECKEY_START_LOC)
Key_exp_loop2:
	; loading S[i], and L[j]
	LDI XL, LOW(KEY_START_LOC)
	LDI YL, LOW(SECKEY_START_LOC)

	ADD XL, KEY_EXT_i
	ADD YL, KEY_EXT_j

	LD S_L, X+
	LD S_H, X+
	LD L_L, Y+
	LD L_H, Y+

	; A = S[i] = (S[i] + A + B) <<< 3
	ADD KEY_EXT_A_L, S_L
	ADC KEY_EXT_A_H, S_H

	ADD KEY_EXT_A_L, KEY_EXT_B_L
	ADC KEY_EXT_A_H, KEY_EXT_B_H

	MOV ROT_L, KEY_EXT_A_L
	MOV ROT_H, KEY_EXT_A_H	
	LDI NO_OF_ROT, 3
	CALL Rotate_Left
	
	MOV KEY_EXT_A_L, ROT_L
	MOV S_L, ROT_L
	MOV KEY_EXT_A_H, ROT_H
	MOV S_H, ROT_H


	; B = L[j] = (L[j] + A + B) <<< (A+B)
	MOV NO_OF_ROT, KEY_EXT_A_L
	ADD NO_OF_ROT, KEY_EXT_B_L
	ANDI NO_OF_ROT, 0x0F

	ADD KEY_EXT_B_L, L_L
	ADC KEY_EXT_B_H, L_H

	ADD KEY_EXT_B_L, KEY_EXT_A_L
	ADC KEY_EXT_B_H, KEY_EXT_A_H

	MOV ROT_L, KEY_EXT_B_L
	MOV ROT_H, KEY_EXT_B_H
	CALL Rotate_Left
	
	MOV KEY_EXT_B_L, ROT_L
	MOV L_L, ROT_L
	MOV KEY_EXT_B_H, ROT_H
	MOV L_H, ROT_H


	ST -Y, L_H
	ST -Y, L_L
	ST -X, S_H
	ST -X, S_L


	; i = (i+1) mod(t)
	INC KEY_EXT_i
	INC KEY_EXT_i
	LDI TEMP, (EXP_KEY_TABLE * WORD_SIZE_BYTES)
	CPSE TEMP, KEY_EXT_i
	RJMP next1
	CLR KEY_EXT_i
	next1:
	

	; j = (j+1) mod(c)
	INC KEY_EXT_j
	INC KEY_EXT_j
	LDI TEMP, (KEY_SIZE_WORDS * WORD_SIZE_BYTES)
	CPSE TEMP, KEY_EXT_j
	RJMP next2
	CLR KEY_EXT_j
	next2:

	DEC ROUNDS
	BRNE Key_exp_loop2

RET


//---------------------------------------------------------------------------------------------------------------------------------------------------------


Rotate_Left:

	BST ROT_H, 7
	ROL ROT_L
	ROL ROT_H
	BLD ROT_L, 0
	DEC NO_OF_ROT
	BRNE Rotate_Left
	RET


Rotate_Right:

	BST ROT_L, 0
	ROR ROT_H
	ROR ROT_L
	BLD ROT_H, 7
	DEC NO_OF_ROT
	BRNE Rotate_Right
	RET
	

Decrement:	// used to decrement 16-bits

	TST DEC_L
	BREQ Dec_XH
	DEC DEC_L
	BREQ Dec_done
	RET

Dec_XH:
	DEC DEC_H
	DEC DEC_L
	RET

Dec_done:
	TST DEC_H
	RET
