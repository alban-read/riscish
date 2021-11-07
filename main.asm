;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; riscish experiment by Alban
;; ARM64 November 2021



;; reserved registers.
;; X18 reserved
;; X29 frame ptr
;; X30 aka LR
;; X28 data section pointer
;; X0-X7 and D0-D7, are used to pass arguments to assembly functions, 
;; X19-X28 callee saved
;; X8 indirect result 

;; related to the interpreter
;; X16 data stack
;; X15 return stack
;; X14 IP (interpretive pointer)
;; X13 CSP code pointer stack
;; X12
;; X11


;; X28 dictionary
;; X22 word 

.data

.align 8

ver:    .double 0.32 
tver:   .ascii  "Version %2.2f\n"
        .zero   4



.text

.global main 

.align 8			 


 		; get line from terminal
getline:

		ADRP	X8, ___stdinp@GOTPAGE
		LDR		X8, [X8, ___stdinp@GOTPAGEOFF]
		LDR		X2, [X8]
	    ADRP	X0, zpadsz@PAGE	   
		ADD     X1, X0, zpadsz@PAGEOFF
		ADRP	X0, zpadptr@PAGE	
		ADD     X0, X0, zpadptr@PAGEOFF
		STP		LR, X16, [SP, #-16]!	
		BL		_getline
		LDP		LR, X16, [SP], #16	
		RET

   	    ; Ok prompt
sayok: 	
        ADRP	X0, tok@PAGE	
		ADD		X0, X0, tok@PAGEOFF
		B		sayit

saycr: 	
        ADRP	X0, tcr@PAGE	
		ADD		X0, X0, tcr@PAGEOFF
		B		sayit

saylb:
	 	ADRP	X0, tlbr@PAGE	
		ADD		X0, X0, tlbr@PAGEOFF
        B		sayit		

sayrb:
	 	ADRP	X0, trbr@PAGE	
		ADD		X0, X0, trbr@PAGEOFF
        B		sayit		


saybye:
	 	ADRP	X0, tbye@PAGE	
		ADD		X0, X0, tbye@PAGEOFF
        B		sayit


saynotfound:
	 	ADRP	X0, tcomer4@PAGE	
		ADD		X0, X0, tcomer4@PAGEOFF
        B		sayit


sayerrlength:
	 	ADRP	X0, tlong@PAGE	
		ADD		X0, X0, tlong@PAGEOFF
        B		sayit
				
sayword:
	 	ADRP	X0, zword@PAGE	
		ADD		X0, X0, zword@PAGEOFF
        B		sayit
				
sayoverflow:
	 	ADRP	X0, tovflr@PAGE	
		ADD		X0, X0, tovflr@PAGEOFF
        B		sayit

sayunderflow:
	 	ADRP	X0,	 tunder@PAGE	
		ADD		X0, X0,	tunder@PAGEOFF
        B		sayit

sayeol:
		ADRP	X0, texit@PAGE	
		ADD		X0, X0, texit@PAGEOFF
		BL		sayit
		B		finish


; first print all defined words in the long word dictionary
; then print all the words in the bytewords dictionary.

dotwords:
	
		ADRP	X8, ___stdoutp@GOTPAGE
		LDR		X8, [X8, ___stdoutp@GOTPAGEOFF]
		LDR		X1, [X8]

	 	ADRP	X2, dend@PAGE	
		ADD		X2, X2, dend@PAGEOFF

20:		ADD		X2, X2, #40
		LDR		X0, [X2]
		CMP     X0, #-1
		B.eq    10f
		CMP     X0, #0
		B.eq    30f

		MOV     X0, X2
		STP		X2, X1, [SP, #-16]!
		STP		LR, X16, [SP, #-16]!
		BL		_fputs	 
		MOV     X0, #32
		BL      _putchar
		LDP     LR, X16, [SP], #16
		LDP     X2, X1, [SP], #16


10:		; skip non word
		B		20b  

30:
 	 	ADRP	X2, fstbyteword@PAGE	
		ADD		X2, X2, fstbyteword@PAGEOFF

40:		

		LDR		X0, [X2, #8]
		CMP     X0, #-1
		B.eq    50f
		CMP     X0, #0
		B.eq    15f

		LDRB	W0, [X2]
		STP		X2, X1, [SP, #-16]!
		STP		LR, X16, [SP, #-16]!
		BL		_putchar 
		MOV     W0, #32
		BL      _putchar
		LDP     LR, X16, [SP], #16
		LDP     X2, X1, [SP], #16

50:		; skip non word
		ADD		X2, X2, #32
		B		40b  
15:
		RET

sayit:		
     
		ADRP	X8, ___stdoutp@GOTPAGE
		LDR		X8, [X8, ___stdoutp@GOTPAGEOFF]
		LDR		X1, [X8]
   		STP		LR, X16, [SP, #-16]!
 		STP		X1, X1, [SP, #-16]!
		BL		_fputs	 
		ADD     SP, SP, #16 
		LDP     LR, X16, [SP], #16
		RET


resetword: ; clear word return x22
		ADRP	X22, zword@PAGE	   
	    ADD		X22, X22, zword@PAGEOFF
		STP     XZR, XZR, [X22]
		STP     XZR, XZR, [X22, #8]
		RET

resetline:

		; get zpad address in X23
		ADRP	X0, zpad@PAGE	   
	    ADD		X23, X0, zpad@PAGEOFF
		MOV     X0, X23
		.rept   384
		MOV     W1, #32
		STRB	W1, [X0], #1
		MOV     W1, #0
		STRB	W1, [X0], #1
		.endr
		RET

advancespaces: ; byte ptr in x23, advance past spaces until zero
10:		LDRB	W0, [X23]
		CMP		W0, #0
		B.eq	90f	
		CMP     W0, #32
		b.ne	90f
		ADD		X23, X23, #1
		B		10b
90:		RET

absz:			
		RET


addz:			; add tos to 2os leaving result tos
		LDR		X1, [X16, #-8]
		LDR		X2, [X16, #-16]
		ADD		X3, X1, X2
		STR		X3, [X16, #-16]
		SUB		X16, X16, #8
		RET

subz:			; add tos to 2os leaving result tos
		LDR		X1, [X16, #-8]
		LDR		X2, [X16, #-16]
		SUB		X3, X2, X1
		STR		X3, [X16, #-16]
		SUB		X16, X16, #8
		RET


mulz:	; mul tos with 2os leaving result tos
		LDR		X1, [X16, #-8]
		LDR		X2, [X16, #-16]
		MUL		X3, X2, X1
		STR		X3, [X16, #-16]
		SUB		X16, X16, #8
		RET

andz:	; and tos with 2os leaving result tos
		LDR		X1, [X16, #-8]
		LDR		X2, [X16, #-16]
		AND		X3, X2, X1
		STR		X3, [X16, #-16]
		SUB		X16, X16, #8
		RET


negz:	;  negate 
		LDR		X1, [X16, #-8]
		NEG		X1, X1
		STR		X1, [X16, #-8]
		RET		


orz:	; or tos with 2os leaving result tos
		LDR		X1, [X16, #-8]
		LDR		X2, [X16, #-16]
		ORR		X3, X2, X1
		STR		X3, [X16, #-16]
		SUB		X16, X16, #8
		RET


sdivz:	; div tos by 2os leaving result tos
		LDR		X1, [X16, #-8]
		LDR		X2, [X16, #-16]
		SDIV	X3, X2, X1
		STR		X3, [X16, #-16]
		SUB		X16, X16, #8
		RET
 
udivz:	; div tos by 2os leaving result tos - ??? not clear this is correct.
		LDR		X1, [X16, #-8]
		LDR		X2, [X16, #-16]
		SDIV	X3, X2, X1
		STR		X3, [X16, #-16]
		SUB		X16, X16, #8
		RET



emitz:	; output tos as char
	
		LDR		X1, [X16, #-8]
		SUB		X16, X16, #8

		
12:		MOV		X0, X1 
		STP		LR, X16, [SP, #-16]!
 		STP		X0, X0, [SP, #-16]!
		BL		_putchar	 
		ADD     SP, SP, #16 
		LDP     LR, X16, [SP], #16
		RET


emitchz:	; output X0 as char
		STP		LR, X16, [SP, #-16]!
 		STP		X0, X0, [SP, #-16]!
		BL		_putchar	 
		ADD     SP, SP, #16 
		LDP     LR, X16, [SP], #16
		RET

emitchc:	; output X0 as char
		RET




reprintz:
	 
		LDP		X1, X0, [X16, #-16]
		SUB		X16, X16, #16
20:		CMP     X1, #0
		B.eq	10f
		STP     X0, X1,  [SP, #-16]!
		STP		LR, X16, [SP, #-16]!
 		STP		X0, X0, [SP, #-16]!
		BL		_putchar	 
		ADD     SP, SP, #16 
		LDP     LR, X16, [SP], #16
		LDP     X0, X1, [SP], #16
		SUB		X1, X1, #1
		B		20b

10:
		RET


reprintc:
		RET
	 


spacesz:
		; number of spaces
		
		LDR		X1, [X16, #-8]
		SUB		X16, X16, #8
20:		CMP     X1, #0
		B.eq	10f
		MOV     X0, #32
		STP     X0, X1,  [SP, #-16]!
		STP		LR, X16, [SP, #-16]!
 		STP		X0, X0, [SP, #-16]!
		BL		_putchar	 
		ADD     SP, SP, #16 
		LDP     LR, X16, [SP], #16
		LDP     X0, X1, [SP], #16
		SUB		X1, X1, #1
		B		20b

10:
		RET


spacesc:	
		RET


print: ; prints int on top of stack		
	
		LDR		X1, [X16, #-8]
		SUB		X16, X16, #8	
12:

	 	ADRP	X0, tdec@PAGE	   
		ADD		X0, X0,tdec@PAGEOFF
		STP		LR, X16, [SP, #-16]!
		STP		X1, X0, [SP, #-16]!
		BL		_printf		 
		ADD     SP, SP, #16 
		LDP		LR, X16, [SP], #16	
		RET


word2number:	; converts ascii at word to 32bit number
				; IN X16

		ADRP	X0, zword@PAGE	   
	    ADD		X0, X0, zword@PAGEOFF
		STP		LR, X16, [SP, #-16]!
		BL		_atoi
		LDP     LR, X16, [SP], #16

		STR		X0, [X16], #8

		; check for overflow
		B 			chkoverflow
		RET




chkunderflow: ; check for stack underflow
		ADRP	X0, spu@PAGE	   
	    ADD		X0, X0, spu@PAGEOFF
		CMP		X16, X0
		b.gt	12f	

		; reset stack
		ADRP	X27, sp1@PAGE	   
	    ADD		X27, X27, sp1@PAGEOFF
		ADRP	X0, dsp@PAGE	   
	    ADD		X0, X0, dsp@PAGEOFF
		STR		X27, [X0]
		MOV		X16, X27 
		; report underflow
	 
		B		sayunderflow

12:
		RET

chkoverflow:; check for stack overflow

		ADRP	X0, spo@PAGE	   
	    ADD		X0, X0, spo@PAGEOFF
		CMP		X16, X0
		b.lt	95f

		; reset stack
		ADRP	X27, sp1@PAGE	   
	    ADD		X27, X27, sp1@PAGEOFF
		ADRP	X0, dsp@PAGE	   
	    ADD		X0, X0, dsp@PAGEOFF
		STR		X27, [X0]
		MOV		X16, X27 
		; report overfow
	
		B		sayoverflow

95:
		RET


collectword:  ; byte ptr in x23, x22 
			  ; copy and advance byte ptr until space.

		STP		LR, X16, [SP, #-16]!
		; reset word to zeros;
		BL		resetword

		MOV		W1, #0


10:		LDRB	W0, [X23], #1
		CMP		W0, #32
		b.eq	90f
		CMP		W0, #10
		B.eq	90f
		CMP		W0, #12
		B.eq	90f
		CMP		W0, #13
		B.eq	90f
 		CMP		W0, #0
		B.eq	90f

30:				
		STRB	W0, [X22], #1
		ADD		W1, W1, #1
		CMP		W1, #15
		B.ne	10b

		ADRP	X0, zword@PAGE	   
	    ADD		X22, X0, zword@PAGEOFF
		STP     XZR, XZR, [X22]
		STP     XZR, XZR, [X22, #8]
		ADRP	X0, zword@PAGE	   
	    ADD		X22, X0, zword@PAGEOFF
		
		BL		sayerrlength
		B		95f
		
20:		B     	10b
		 
90:		MOV     W0, #0x00
		STRB	W0, [X22], #1
		STRB	W0, [X22], #1
95:		LDP     LR, X16, [SP], #16
		RET

		; announciate version
announce:		
	
        ADRP	X0, ver@PAGE	     
		ADD		X0, X0, ver@PAGEOFF
        LDR     X1, [X0]
	 	ADRP	X0, tver@PAGE	   
		ADD		X0, X0, tver@PAGEOFF
		STP		LR, X16, [SP, #-16]!
		STP		X1, X0, [SP, #-16]!
		BL		_printf		 
		ADD     SP, SP, #16  
		LDP		LR, X16, [SP], #16	
		RET

		; exit the program
finish: 
		MOV		X0, #0
		LDR		LR, [SP], #16
		LDP		X19, X20, [SP], #16
		RET

 

;; leaf
get_word: ; get word from zword into x22
		ADRP	X22, zword@PAGE	   
	    ADD		X22, X22, zword@PAGEOFF
		LDR		X22, [X22]
		RET

;; leaf
empty_wordQ: ; is word empty?
		ADRP	X22, zword@PAGE	   
	    ADD		X22, X22, zword@PAGEOFF
 		LDRB	W0, [X22]
		CMP		W0, #0 
		RET


start_point: ; dictionary entry points are based on first charachter
	
		LDRB 	W0,	[X22]	; first letter
		
		; lower case and check for a..z
		ORR		W0, W0, 0x20

		CMP		W0, #'z'	
		B.gt 	searchall
		
		CMP		W0, #'a'
		B.lt	searchall

		; We have a..z, A..Z, so narrow the search.

		CMP		W0, #'a'
		B.ne	201f
		ADRP	X28, adict@PAGE	   
	    ADD		X28, X28, adict@PAGEOFF	
		B		251f

201:	CMP		W0, #'b'
		B.ne	221f
		ADRP	X28, bdict@PAGE	   
	    ADD		X28, X28, bdict@PAGEOFF	
	 	B       251f


221:	CMP		W0, #'c'
		B.ne	202f
		ADRP	X28, cdict@PAGE	   
	    ADD		X28, X28, cdict@PAGEOFF	
	 	B       251f		 

202:	CMP		W0, #'d'
		B.ne	203f
		ADRP	X28, ddict@PAGE	   
	    ADD		X28, X28, ddict@PAGEOFF	
		B       251f
 
203:	CMP		W0, #'e'
		B.ne	204f
		ADRP	X28, edict@PAGE	   
	    ADD		X28, X28, edict@PAGEOFF	
		B       251f
 
204:	CMP		W0, #'f'
		B.ne	205f
		ADRP	X28, fdict@PAGE	   
	    ADD		X28, X28, fdict@PAGEOFF	
		B       251f

205:	CMP		W0, #'g'
		B.ne	206f
		ADRP	X28, gdict@PAGE	   
	    ADD		X28, X28, gdict@PAGEOFF	
		B       251f


206:	CMP		W0, #'h'
		B.ne	207f
		ADRP	X28, hdict@PAGE	   
	    ADD		X28, X28, hdict@PAGEOFF	
		B       251f

207:	CMP		W0, #'i'
		B.ne	208f
		ADRP	X28, idict@PAGE	   
	    ADD		X28, X28, idict@PAGEOFF	
		B       251f

208:	CMP		W0, #'j'
		B.ne	209f
		ADRP	X28, jdict@PAGE	   
	    ADD		X28, X28, jdict@PAGEOFF	
		B       251f

209:	CMP		W0, #'k'
		B.ne	210f
		ADRP	X28, kdict@PAGE	   
	    ADD		X28, X28, kdict@PAGEOFF	
		B       251f

210:	CMP		W0, #'l'
		B.ne	211f
		ADRP	X28, ldict@PAGE	   
	    ADD		X28, X28, ldict@PAGEOFF	
		B       251f

211:	CMP		W0, #'m'
		B.ne	212f
		ADRP	X28, mdict@PAGE	   
	    ADD		X28, X28, mdict@PAGEOFF	
		B       251f

212:	CMP		W0, #'n'
		B.ne	213f
		ADRP	X28, ndict@PAGE	   
	    ADD		X28, X28, ndict@PAGEOFF	
		B       251f

213:	CMP		W0, #'o'
		B.ne	214f
		ADRP	X28, odict@PAGE	   
	    ADD		X28, X28, odict@PAGEOFF	
		B       251f

214:	CMP		W0, #'p'
		B.ne	215f
		ADRP	X28, pdict@PAGE	   
	    ADD		X28, X28, pdict@PAGEOFF	
		B       217f

215:	CMP		W0, #'q'
		B.ne	216f
		ADRP	X28, qdict@PAGE	   
	    ADD		X28, X28, qdict@PAGEOFF	
		B       251f

216:	CMP		W0, #'r'
		B.ne	217f
		ADRP	X28, rdict@PAGE	   
	    ADD		X28, X28, rdict@PAGEOFF	
		B       251f

217:	CMP		W0, #'s'
		B.ne	218f
		ADRP	X28, sdict@PAGE	   
	    ADD		X28, X28, sdict@PAGEOFF	
		B       251f

218:	CMP		W0, #'t'
		B.ne	219f
		ADRP	X28, tdict@PAGE	   
	    ADD		X28, X28, tdict@PAGEOFF	
		B       251f

219:	CMP		W0, #'u'
		B.ne	220f
		ADRP	X28, udict@PAGE	   
	    ADD		X28, X28, udict@PAGEOFF	
		B       251f

220:	CMP		W0, #'v'
		B.ne	221f
		ADRP	X28, vdict@PAGE	   
	    ADD		X28, X28, vdict@PAGEOFF	
		B       251f

221:	CMP		W0, #'w'
		B.ne	222f
		ADRP	X28, wdict@PAGE	   
	    ADD		X28, X28, wdict@PAGEOFF	
		B       251f

222:	CMP		W0, #'x'
		B.ne	223f
		ADRP	X28, xdict@PAGE	   
	    ADD		X28, X28, ydict@PAGEOFF	
		B       251f

223:	CMP		W0, #'y'
		B.ne	224f
		ADRP	X28, tdict@PAGE	   
	    ADD		X28, X28, tdict@PAGEOFF	
		B       251f

224:	CMP		W0, #'z'
		B.ne	225f
		ADRP	X28, tdict@PAGE	   
	    ADD		X28, X28, tdict@PAGEOFF	
		B       251f		

225:

searchall:
		; search from bottom of dictionary
		; from here X28 is current word in sdict
		ADRP	X28, startdict@PAGE	   
	    ADD		X28, X28, startdict@PAGEOFF
251:	
		SUB		X28, X28, #40

		RET


;; start running here

main:	 
		 

init:	

		ADRP	X0, dsp@PAGE	   
	    ADD		X0, X0, dsp@PAGEOFF
		LDR		X16, [X0]  ;; <-- data stack pointer to X16


   	    BL  announce

input: 	BL  chkoverflow
		BL  chkunderflow
		BL  sayok
		BL  resetword
		BL  resetline
		BL  getline

advance_word:

10:		BL  advancespaces

		BL  collectword

		; check if we have read all available words in the line
		BL 		empty_wordQ
		B.eq	input ; get next line
	 
		; look for BYE - which does quit.
		BL		get_word
		ADRP	X0, dbye@PAGE	   
	    ADD		X21, X0, dbye@PAGEOFF
		LDR		X21, [X21]
		CMP		X21, X22
		B.ne	outer  
		
		; Bye - we are leaving the program

		ADRP	X0, tbye@PAGE	
		ADD		X0, X0, tbye@PAGEOFF  
		ADRP	X8, ___stdoutp@GOTPAGE
		LDR		X8, [X8, ___stdoutp@GOTPAGEOFF]
		LDR		X1, [X8]

 		STP		X1, X0, [SP, #-16]!
		BL		_fputs	 
		ADD     SP, SP, #16 
		MOV		X0, #0
		BL		_exit


		; outer interpreter
		; look for WORDs - when found, execute the words function	
		; we are in immediate mode, we see a word and we execute its code.

outer:	
		

interpret_word:	

		ADRP	X22, zword@PAGE	   
	    ADD		X22, X22, zword@PAGEOFF
		LDRB	W0, [X22, #1]
		CMP		W0, #0
		B.ne	fw1	

short_words:

		; we have a byte length word.

		; check if we need to enter the compiler loop.
		LDRB	W0, [X22]
		CMP 	W0, #':' 	; do we enter the compiler ?
		B.eq	enter_compiler

		; check if we need to enter the compiler loop.
		LDRB	W0, [X22]
		CMP 	W0, #']' 	; do we enter the compiler ?
		B.eq	enter_compiler


		; otherwise just search bytewords dictionary

		LDRB 	W0,	[X22]
		LSL		X0, X0, #5
		ADRP	X1,bytewords@PAGE 
		ADD		X1, X1, bytewords@PAGEOFF
		ADD		X1, X1, X0 ; words address

		; found word, exec z function
		LDR     X2,	[X1, #8]
		CMP		X2, #0 

		B.eq	advance_word ; no exec

		LDR     X0,  [X1, #24] ; data 
		STP		X28, XZR, [SP, #-16]!
		BLR		X2	 ;; call function
		LDP		X28, XZR, [SP]
		B		advance_word
		

fw1:
		BL		start_point	


252: 
		BL 		get_word
		LDR		X21, [X28]
		CMP     X21, #0        ; end of list?
		B.eq    finish_list	
		CMP     X21, #-1       ; undefined entry in list?
		b.eq    251b

		CMP		X21, X22       ; is this our word?
		B.ne	251b

		; found word, exec function
		LDR     X2,	[X28, #16]
		CMP		X2, #0 
		B.eq	finish_list
		LDR     X0,	[X28, #32] ; data
		STP		X28, XZR, [SP, #-16]!
		BLR		X2	 ;; call function
		LDP		X28, XZR, [SP]
		B       advance_word

finish_list: ; we did not find a defined word.

	 

check_integer_variables:

		; look for a single letter variable name
		; followed by @ (fetch) or ! (store)
 
		ADRP	X22, zword@PAGE	   
	    ADD		X22, X22, zword@PAGEOFF
		LDRB	W0, [X22, #1]
		CMP		W0, #'@'
		B.eq	ivfetch
		CMP		W0, #'!'
		B.eq	ivset
		B		20f

ivfetch: ; from variable push to stack
		LDRB 	W0,	[X22]
		LSL		X0, X0, #3
		ADRP	X27,ivars@PAGE 
		ADD		X27, X27, ivars@PAGEOFF
		LDR		X0, [X27, X0]
		STR		X0, [X16], #8	
		; todo check overflow.
		B       advance_word

ivset:	; from stack set variable
		LDRB 	W0,	[X22]
		LSL     X0, X0, #3
		LDR		X1, [X16, #-8]
		SUB		X16, X16, #8
		; todo check under-flow.

		; check underflow
		ADRP	X2, spu@PAGE	   
	    ADD		X2, X2, spu@PAGEOFF
		CMP		X16, X2
		b.gt	ivset2	

		; reset stack
		ADRP	X26, sp1@PAGE	   
	    ADD		X26, X26, sp1@PAGEOFF
		ADRP	X2, dsp@PAGE	   
	    ADD		X2, X2, dsp@PAGEOFF
		STR		X26, [X2]
		MOV		X16, X26 
		; report underflow
		BL		sayunderflow
		B		10b

ivset2:		
		ADRP	X27,ivars@PAGE 
		ADD		X27, X27, ivars@PAGEOFF
		ADD     X27, X27, X0
		STR		X1, [X27]
		B		10b


20:
		; look for an integer number made of decimal digits.
		; If found immediately push it onto our Data Stack

		ADRP	X22, zword@PAGE	   
	    ADD		X22, X22, zword@PAGEOFF
		
		; tolerate a negative number
		LDRB	W0, [X22]
		CMP		W0, #'-'
		B.ne	22f 
		ADD		X22, X22, #1
		LDRB	W0, [X22]

22:
		CMP 	W0, #'9'
		B.gt    compiler
		CMP     W0, #'0'
		B.lt    compiler

23:		ADD		X22, X22, #1
		LDRB	W0, [X22]
		CMP		W0, #0
		B.eq	24f
		CMP 	W0, #'.'
		B.eq	decimal_number
		CMP 	W0, #'9'
		B.gt    compiler
		CMP     W0, #'0'
		B.lt    compiler
		
		B		23b
24:
		; we have a valid number, so translate it
		BL		word2number
		B       advance_word

		; OR the word may be a decimal number

decimal_number:
		; TODO: decimals





		; from here we are no longer interpreting the line.
		; we are compiling input until we get see a ';'

compiler:

		ADRP	X22, zword@PAGE	   
	    ADD		X22, X22, zword@PAGEOFF
		
		LDRB	W0, [X22]
		CMP 	W0, #':' 	; do we enter the compiler ?
		B.ne	not_compiling ; no..

		; yes, from here we compile a new word.

enter_compiler:

		; look for the name of the new word we are compiling.
		BL  	advancespaces
		BL  	collectword
		 
		BL 		empty_wordQ
		B.ne	create_word 

		; : was followed by nothing which is an error.
		ADRP	X0,	 tcomer1@PAGE	
		ADD		X0, X0,	tcomer1@PAGEOFF
        BL		sayit
		B		input ; back to immediate mode.

		; to create a new word :-
		; 1. find first free word in the list. 
		; 2. set the words name.
		; 4. find the next code space address.
		; 5. set the function to the code space addres
		; 6. set the first code space element to DOCOL 
		; 7. set the next code space elemement to SEMI
		; - [DOCOL, SEMI] is essentially a NOOP. 




create_word: 



		; we need to repeat all of the parsing functions here in the compiling loop.
		; in this loop we compile each word rather than just executing it.
		; all words have a compile action, so they essentially compile themselves..

compile_word:






exit_compiler:


		; BL sayok

		B	advance_word ; back to main loop









not_compiling:

; at this point we have not found this word
; display word not found as an error.

		BL		saycr
		BL		saylb
		BL		sayword
		BL		sayrb
		BL 		saynotfound
		
		B		advance_word


exit_program:		

		MOV		X0,#0
        BL		_exit
		

		;brk #0xF000



;; these functions are all single letter words.
;; z is run time, c is the optional compile time behaviour.

dstorez:	; ( addr value -- )
		B		storz
		RET

dstorec:	; ( addr value -- )
		RET


dquotz:	; " 
		RET

dquotc:	; " 
		RET

dhashz:	; # 
		RET

dhashc:	; #
		RET

ddollarz: ; $ 
		RET

ddollarc: ; $ 
		RET

dmodz: ; %  MOD
		LDP  	X0, X1,  [X16, #-16]  
		UDIV 	X2, X0, X1
		MSUB 	X3, X2, X1, X0 
		STR 	X3, [X16, #-16]
		SUB 	X16, X16, #8
		RET


		RET

dmodc: ; % 
		RET


dandz: ; & 
		B 	andz
		RET

dandc: ; & 
		RET

dtickz: ; '
		RET

dtickc: ; '
		RET

dlrbz: ; (
		RET

dlrbc: ; (
		RET

drrbz: ; )
		RET

drrbc: ; )
		RET

dstarz: ; *
		B		mulz
		RET

dstarc: ; *
		RET

dcomaz: ; , compile tos into dict.
		RET

dcomac: ; ,
		RET

dsubz: ; -  subtract
		B  		subz
		RET

dsubc: ;  subtract
		RET

ddotz: ; . print tos
		B  		print
		RET

ddotc: ; 
		RET


ddivz: ; / divide
		B  		udivz
		RET

ddivc: ; 
		RET

dsdivz: ; \ divide
		B  		sdivz
		RET

dsdivc: ; 
		RET

dsmodz: ; /MOD
		LDP  	X0, X1,  [X16, #-16]  
		UDIV 	X2, X0, X1
		MSUB 	X3, X2, X1, X0 
		STP	 	X3, X2, [X16, #-16]  
		RET

dsmodc:
		RET


; break to debugger
dbreakz: 
		
		BRK #01
		RET

dbreakc: ; 
		RET



dplusz: ; +
		B  		addz
		RET

dplusc: ; 
		RET

ddropz: ;  
		SUB 	X16, X16, #8
		RET

ddropc: ;   
		RET	

ddupz: ;  
		LDR 	X0, [X16, #-8] 
		STR		X0, [X16], #8
		RET
	

dqdupc: ;   
		RET	


dqdupz: ;  ?DUP 
		LDR 	X0, [X16, #-8]
		CMP		X0, #0
		B.eq	10f 
		STR		X0, [X16], #8
10:		
		RET
	

ddupc: ;   
		RET	


dswapz: ;  
		LDP    X0, X1, [X16, #-16]
		STP    X1, X0, [X16, #-16]
		RET

dswapc: ;   
		RET	

drotz: ;  
		LDP		X1, X0, [X16, #-16] 
		LDR     X2, [X16, #-24]   
		STP		X0, X2, [X16, #-16]  
		STR		X1, [X16, #-24]  
		RET

drotc: ;   
		RET		



doverz: ;
		LDR 	X0, [X16, #-16] 
		STR		X0, [X16], #8
		RET

doverc:	
		RET


dpickc: ;   
	
		RET	

dpickz: ;  
		LDR		X0, [X16, #-8]!
		ADD     X0, X0, #1
		NEG     X0, X0
		LDR		X1, [X16, X0, LSL #3]
		STR		X1, [X16], #8
		RET

	

dnipc: ;   
		RET	

dnipz: ;  
	
		LDP		X0, X1, [X16, #-16]  
		STR 	X1, [X16, #-16]  
		SUB 	X16, X16, #8
		RET





dcolonz: ; : define new word, docol
		RET

dcolonc: ;  : compile word 
		RET		

dsemiz: ; ";" semi, end word, return.
		RET

dsemic: ;  ";" semi, end word, stop compiling.
		RET		


dltz: ; "<" less than
		
lessthanz:
		LDR		X0, [X16, #-8] 
		LDR		X1, [X16, #-16]
		CMP  	X0, X1		
		B.gt	10f
		B.eq	10f
		MVN		X0, XZR ; true
		B		20f
10:
		MOV		X0, XZR
20:
		STR 	X0, [X16, #-16]
		SUB		X16, X16, #8
		RET


dltc: ;  "<"  
		RET		

dequz: ; "=" less than
	
equalz:
		LDR		X0, [X16, #-8] 
		LDR		X1, [X16, #-16]
		CMP  	X0, X1		
		B.ne	10f
		MVN		X0, XZR ; true
		B		20f
10:
		MOV		X0, XZR
20:
		STR 	X0, [X16, #-16]
		SUB		X16, X16, #8
		RET


dequc: ;  "="  
		RET		

dgtz: ; ">" greater than

greaterthanz:
		LDR		X0, [X16, #-8] 
		LDR		X1, [X16, #-16]
		CMP  	X0, X1		
		B.lt	10f
		B.eq	10f
		MVN		X0, XZR ; true
		B		20f
10:
		MOV		X0, XZR
20:
		STR 	X0, [X16, #-16]
		SUB		X16, X16, #8
		RET		


dgtc: ;  ">"  
		RET		

dqmz: ; "?" if zero
		RET

dqmc: ;  "?"  
		RET		

datz: ; "@" at - fetch 
		B 		atz
 

datc: ;  "@"  
		RET		


atz: ;  ( address -- n ) fetch var.
		LDR		X0, [X16, #-8] 
		LDR     X0, [X0]
		STR		X0, [X16, #-8]
		RET

storz:  ; ( n address -- )
		LDR		X0, [X16, #-8] 
		LDR		X1, [X16, #-16]
		STR 	X1, [X0]
		SUB		X16, X16, #16
		RET



nsubz:	;
		LDR		X1, [X16, #-8]
		SUB		X1, X1, X0
		STR		X1, [X16, #-8]
		RET

dnsubz:	
		B 		nsubz


dnsubc:	
		RET	



nplusz:	;
		LDR		X1, [X16, #-8]
		ADD		X1, X1, X0
		STR		X1, [X16, #-8]
		RET

dnplusz:
		B 		nplusz


dnplusc:
		RET	


nmulz:	; perform shift left to multiply
		LDR		X1, [X16, #-8]
		LSL		X1, X1, X0
		STR		X1, [X16, #-8]
		RET

dnmulz:
		B 		nmulz


dnmulc:
		RET	
		



ndivz:	; perform shift right to divide
		LDR		X1, [X16, #-8]
		LSR		X1, X1, X0
		STR		X1, [X16, #-8]
		RET

dndivz:
		B 		ndivz

dndivc:
		RET


stackit: ; push x0 to stack.

		STR		X0, [X16], #8
		RET

dvaraddz: ; address of variable
		STR		X0, [X16], #8
		RET

dvaraddc: ; compile address of variable
		RET

dconstz: ; value of constant
		STR		X0, [X16], #8
		RET


dconstc: ; value of constant
		STR		X0, [X16], #8
		RET



diloopz: ; special I loop variable
		RET

djloopz: ; special J loop variable
		RET

dkloopz: ; special K loop variable
		RET

diloopc: ; special I loop variable
		RET

djloopc: ; special J loop variable
		RET

dkloopc: ; special K loop variable
		RET

dlsbz:  ; [ 
		RET
		

dlsbc:  ; [
		RET

dshlashz:  ; \
		RET
		
dshlashc:  ; \
		RET

drsbz:  ; ]
		RET
		
drsbc:  ; ]
		RET

dabsz:  ; ABS

		LDR		X0, [X16, #-8]
		CMP 	X0,  #1
		CSNEG   X0, X0, X0, pl	
		STR     X0, [X16, #-8]
		RET
		

dabsc:  ; 
		RET



dtophatz:  ; 
		RET
		

dtophatc:  ; 
		RET


dunderscorez:  ; 
		RET
		

dunderscorec:  ; 
		RET


dbacktkz:  ; 
		RET
		

dbacktkc:  ;   
		RET

dlcbz: ;  {   lcb
		RET

dlcbc: ;  {   lcb
		RET



dpipez: ; |  pipe
		B 	orz
		RET


dpipec: ; |  pipe
		RET


drcbz: ;  }   rcb
		RET

drcbc: ;  }  rcb
		RET

dtildez: ;  ~  tilde
		RET

dtildec: ;  ~  tilde
		RET


ddelz:	; del (127)
		RET

ddelc:	; del (127)
		RET


.data

.align 8
 

dpage: .zero 4
zstdin: .zero 16



;; text literals



.align 8

tok:    .ascii  "\nOk\n"
		.zero 16

.align 	8
tbye:	.ascii "\nBye..\n"
		.zero 16


.align 	8
texit:	.ascii "Exit no more input.."
		.zero 16

.align 	8
tlong:	.ascii "Word too long.."
		.zero 16

.align 	8
tcr:	.ascii "\r\n"
		.zero 16

.align 	8
tlbr:	.ascii "["
		.zero 16

.align 	8
trbr:	.ascii "]"
		.zero 16

.align 	8
tdec:	.ascii "%3ld"
		.zero 16

.align 	8
tovflr:	.ascii "\nstack over-flow"
		.zero 16

.align 	8
tunder:	.ascii "\nstack under-flow"
		.zero 16

.align 	8
tcomer1: .ascii "\nCompiler error ':' expects a word to define."
		.zero 16

.align 	8
tcomer3: .ascii "\nCompiler error  "
		.zero 16

.align 	8
tcomer4: .ascii "<-- Word was not recognized. "
		.zero 16

.align 	8
tcomer5: .ascii "Compiler error  "
		.zero 16


.align 	8
spaces:	.ascii "                              "
		.zero 16


; this is the code pointer stack
; every address pushed here is a leaf subroutine address.
; 
.align 8
cps:	.zero 8*16	
cpu:	.zero 16
cp1:    .zero 4096*16  
cpo:	.zero 16
cp0:    .zero 16
csp:	.quad cp1


; this is the data stack
.align  8
sps:	.zero 8*8	
spu:	.zero 4
sp1:    .zero 256*4  
spo:	.zero 4
sp0:    .zero 8*8
dsp:	.quad sp1

; this is the return stack
.align  8
rps:	.zero 8*8	
rpu:	.zero 4
rp1:    .zero 256*4  
rpo:	.zero 4
rp0:    .zero 8*8
rsp:	.quad rp1

; global, single letter, integer variables
.align 16
ivars:	.zero 256*16	


; used for line input
.align 8
zpad:    .ascii "ZPAD STARTS HERE"
		 .zero 1024

.align 8
zword: .zero 64

 .align 8
 dbye:		.ascii "BYE" 
			.zero 5
			.zero 8
			.quad 0
			.quad 0


 		    ; each word is 16 bytes of zero terminated ascii	
			; a pointer to the adress of the run time machine code function to call.
			; a pointer to the adress of the compile time machine code function to call.
			; a data element
			; gaps for capacity are stacked up towards 'a'  
			;  

			; the end of the list
 dend:		.quad 0	; name
			.quad 0	; name
			.quad 0	; zptr - run time action
			.quad 0 ; cptr - compile time action
			.quad 0 ; cdata - class data 
			; primitive code word headings.

			.rept 44  
			.quad -1 
			.quad 0
			.quad -1 
			.quad 0
			.quad 0
			.endr

			.ascii "ABS" 
			.zero 5	
			.zero 8	
			.quad dabsz
			.quad dabsc
			.quad 0
adict:

			.rept 44 
			.quad -1 
			.quad 0
			.quad -1 
			.quad 0
			.quad 0
			.endr

			.ascii "BREAK" 
			.zero 3
			.zero 8	
			.quad dbreakz
			.quad dbreakc
			.quad 0


			.ascii "BL" 
			.zero 6
			.zero 8	
			.quad dconstz
			.quad dconstc
			.quad 32
			

bdict:

			.ascii "CR" 
			.zero 6	
			.zero 8	
			.quad saycr
			.quad 0
			.quad 0

cdict:
			.rept 40  
			.quad -1 
			.quad 0
			.quad -1 
			.quad 0
			.quad 0
			.endr

			.ascii "DUP" 
			.zero 5	
			.zero 8	
			.quad ddupz
			.quad ddupc
			.quad 0

			.ascii "DROP" 
			.zero 4	
			.zero 8	
			.quad ddropz
			.quad ddropc
			.quad 0

ddict:
			.rept 40 
			.quad -1 
			.quad 0
			.quad -1 
			.quad 0
			.quad 0
			.endr

			.rept 40 
			.quad -1 
			.quad 0
			.quad -1 
			.quad 0
			.quad 0
			.endr

			.ascii "EMIT" 
			.zero 4
			.zero 8	
			.quad emitz
			.quad 0
			.quad 0

edict:
			.rept 40 
			.quad -1 
			.quad 0
			.quad -1 
			.quad 0
			.quad 0
			.endr


fdict:		
			.rept 38  
			.quad -1 
			.quad 0
			.quad -1 
			.quad 0
			.quad 0
			.endr


gdict:
			.rept 38  
			.quad -1 
			.quad 0
			.quad -1 
			.quad 0
			.quad 0
			.endr


hdict:

			.rept 36  
			.quad -1 
			.quad 0
			.quad -1 
			.quad 0
			.quad 0
			.endr

idict:
			.rept 36  
			.quad -1 
			.quad 0
			.quad -1 
			.quad 0
			.quad 0
			.endr

jdict:
			.rept 34  
			.quad -1 
			.quad 0
			.quad -1 
			.quad 0
			.quad 0
			.endr

kdict:
			.rept 34  
			.quad -1 
			.quad 0
			.quad -1 
			.quad 0
			.quad 0
			.endr

ldict:
			.rept 34  
			.quad -1 
			.quad 0
			.quad -1 
			.quad 0
			.quad 0
			.endr


			.ascii "MOD" 
			.zero 5
			.zero 8	
			.quad dmodz
			.quad dmodc
			.quad 0


mdict:
			.rept 32  
			.quad -1 
			.quad 0
			.quad -1 
			.quad 0
			.quad 0
			.endr

			.ascii "NEGATE" 
			.zero 2
			.zero 8	
			.quad negz
			.quad 0
			.quad 0	

			.ascii "NIP" 
			.zero 5
			.zero 8	
			.quad dnipz
			.quad dnipc
			.quad 0	



ndict:		
			.rept 32  
			.quad -1 
			.quad 0
			.quad -1 
			.quad 0
			.quad 0
			.endr


			.ascii "OVER" 
			.zero 4
			.zero 8	
			.quad doverz		
			.quad doverc
			.quad 0

			.ascii "OK" 
			.zero 6
			.zero 8	
			.quad sayok			
			.quad 0
			.quad 0

odict:
			.rept 32  
			.quad -1 
			.quad 0
			.quad -1 
			.quad 0
			.quad 0
			.endr

			.ascii "PRINT" 
			.zero 3
			.zero 8	
			.quad print
			.quad 0
			.quad 0

			.ascii "PICK" 
			.zero 4
			.zero 8	
			.quad dpickz
			.quad dpickc
			.quad 0


pdict:
			.rept 32  
			.quad -1 
			.quad 0
			.quad -1 
			.quad 0
			.quad 0
			.endr


qdict:
			.rept 30  
			.quad -1 
			.quad 0
			.quad -1 
			.quad 0
			.quad 0
			.endr

			.ascii "REPRINT" 
			.zero 1
			.zero 8	
			.quad reprintz
			.quad reprintc
			.quad 0

			.ascii "ROT" 
			.zero 5
			.zero 8	
			.quad drotz
			.quad drotc
			.quad 0

rdict:

			.rept 30  
			.quad -1 
			.quad 0
			.quad -1 
			.quad 0
			.quad 0
			.endr

			.ascii "SWAP" 
			.zero 4
			.zero 8	
			.quad dswapz
			.quad dswapc
			.quad 0

			.ascii "SPACES" 
			.zero 2
			.zero 8	
			.quad spacesz
			.quad spacesc
			.quad 32

			.ascii "SPACE" 
			.zero 3
			.zero 8	
			.quad emitchz
			.quad emitchc
			.quad 32

sdict:

			.rept 30  
			.quad -1 
			.quad 0
			.quad -1 
			.quad 0
			.quad 0
			.endr

tdict:

			.rept 30  
			.quad -1 
			.quad 0
			.quad -1 
			.quad 0
			.quad 0
			.endr

udict:
			.rept 28  
			.quad -1 
			.quad 0
			.quad -1 
			.quad 0
			.quad 0
			.endr

 		
vdict:
			.rept 28  
			.quad -1 
			.quad 0
			.quad -1 
			.quad 0
			.quad 0
			.endr


			.ascii "WORDS" 
			.zero 3
			.zero 8	
			.quad dotwords
			.quad 0
			.quad 0
			
			
wdict:

			.rept 28  
			.quad -1 
			.quad 0
			.quad -1 
			.quad 0
			.quad 0
			.endr

xdict:
			.rept 28  
			.quad -1 
			.quad 0
			.quad -1 
			.quad 0
			.quad 0
			.endr

ydict:
			.rept 24  
			.quad -1 
			.quad 0
			.quad -1 
			.quad 0
			.quad 0
			.endr

zdict:
			.rept 24  
			.quad -1 
			.quad 0
			.quad -1 
			.quad 0
			.quad 0
			.endr

			.ascii "1+"
			.zero 6
			.zero 8
			.quad dnplusz
			.quad 0
			.quad 1

			.ascii "2+"
			.zero 6
			.zero 8
			.quad dnplusz
			.quad 0
			.quad 2


			.ascii "1-"
			.zero 6
			.zero 8
			.quad dnsubz
			.quad 0
			.quad 1

			.ascii "2-"
			.zero 6
			.zero 8
			.quad dnsubz
			.quad 0
			.quad 2

			.ascii "2*"
			.zero 6
			.zero 8
			.quad dnmulz
			.quad 0
			.quad 1


			.ascii "2/"
			.zero 6
			.zero 8
			.quad dndivz
			.quad 0
			.quad 1

			.ascii "4+"
			.zero 6
			.zero 8
			.quad dnplusz
			.quad 0
			.quad 4

			.ascii "4*"
			.zero 6
			.zero 8
			.quad dnmulz
			.quad 0
			.quad 2

			.ascii "4/"
			.zero 6
			.zero 8
			.quad dndivz
			.quad 0
			.quad 2


			.ascii "8+"
			.zero 6
			.zero 8
			.quad dnplusz
			.quad 0
			.quad 8


			.ascii "8*"
			.zero 6
			.zero 8
			.quad dnmulz
			.quad 0
			.quad 3

			.ascii "8/"
			.zero 6
			.zero 8
			.quad dndivz
			.quad 0
			.quad 3

			.ascii "16+"
			.zero 5
			.zero 8
			.quad dnplusz
			.quad 0
			.quad 16

			.ascii "16*"
			.zero 5
			.zero 8
			.quad dnmulz
			.quad 0
			.quad 4

			.ascii "16/"
			.zero 5
			.zero 8
			.quad dndivz
			.quad 0
			.quad 4

			.ascii "32*"
			.zero 5
			.zero 8
			.quad dnmulz
			.quad 0
			.quad 5

			.ascii "32/"
			.zero 5
			.zero 8
			.quad dndivz
			.quad 0
			.quad 5


			.ascii "64*"
			.zero 5
			.zero 8
			.quad dnmulz
			.quad 0
			.quad 6

			.ascii "64/"
			.zero 5
			.zero 8
			.quad dndivz
			.quad 0
			.quad 6


			.ascii "/MOD" 
			.zero 4
			.zero 8	
			.quad dsmodz
			.quad dsmodc
			.quad 0

			.ascii ".VERSION" 
			.zero 8	
			.quad announce
			.quad 0
			.quad 0

 			.ascii "?DUP" 
			.zero 4	
			.zero 8
			.quad dqdupz
			.quad dqdupc
			.quad 0



 duserdef:
			.rept 32 ; 
			.quad -1 
			.quad 0
			.quad -1 
			.quad 0
			.quad 0
			.endr

 startdict:		
 			.quad -1 
			.quad  0
			.quad -1	
			.quad 0	
			.quad 0	

			.quad 0 
			.quad 0
			.quad 0
			.quad 0	
			.quad 0	


.align 8
zpos:    .quad 0
zpadsz:  .quad 1024
zpadptr: .quad zpad

.align 8
addressbuffer:
		.zero 128*8


 .align 8
 bytewords:	; single character words
			; 32 byte struct
			; we can just look these up without searching a list
			; a..z A..Z are int variable read.
			;  .. except i,j,k are loop variables.
			; 
  
			; control code, unprintable, byte codes.
			.rept 33 		; 
			.quad -1		; word name etc
			.quad 0			; function address
			.quad 0			; data
			.quad 0			; data
			.endr

			; printable, byte codes, symbols we can use.

fstbyteword: ; ascii 33 !
			.byte 33		; word name etc
			.zero 7
			.quad dstorez	; function address
			.quad dstorec	;			 
			.quad 0			; data

			; ascii 34 " double quote
			.byte 34		; word name etc
			.zero 7
			.quad dquotz	; function address
			.quad dquotc    ; compile time
			.quad 0			; data

			; ascii 35 # hash -- used for numeric formats
			.byte 35		; word name etc
			.zero 7
			.quad dhashz	; function address
			.quad dhashc    ; compile time
			.quad 0			; data

			; ascii 36 $    used for strings
			.byte 36		; word name etc
			.zero 7
			.quad ddollarz	; function address
			.quad ddollarc   ; compile time
			.quad 0			; data

			; ascii 37 %    used for mod
			.byte 37	   	; word name etc
			.zero 7
			.quad dmodz		; function address
			.quad dmodc   	; compile time
			.quad 0			; data

			; ascii 38 &    used for and
			.byte 38	    ; word name etc
			.zero 7
			.quad dandz	    ; function address
			.quad dandc     ; compile time
			.quad 0			; data

			; ascii 39 '    used for tick
			.byte 39	    ; word name etc
			.zero 7
			.quad dtickz	; function address
			.quad dtickc    ; compile time
			.quad 0			; data

			; ascii 40 (    lrb
			.byte 40	    ; word name etc
			.zero 7
			.quad dlrbz		; function address
			.quad dlrbc    	; compile time
			.quad 0			; data

			; ascii 41 )    rrb
			.byte 41	    ; word name etc
			.zero 7
			.quad drrbz		; function address
			.quad drrbc    	; compile time
			.quad 0			; data

			; ascii 42 *    multiply
			.byte 42	    ; word name etc
			.zero 7
			.quad dstarz	; function address
			.quad dstarc    ; compile time
			.quad 0			; data

			; ascii 43 +    plus
			.byte 43	    ; word name etc
			.zero 7
			.quad dplusz	; function address
			.quad dplusc    ; compile time
			.quad 0			; data


			; ascii 44 ,    compile into dictionary
			.byte 44	    ; word name etc
			.zero 7
			.quad dcomaz	; function address
			.quad dcomac    ; compile time
			.quad 0			; data


			; ascii 45 -    sub
			.byte 45	    ; word name etc
			.zero 7
			.quad dsubz		; function address
			.quad dsubc     ; compile time
			.quad 0			; data

			; ascii 46 .    dot
			.byte 46	    ; word name etc
			.zero 7
			.quad ddotz		; function address
			.quad ddotc     ; compile time
			.quad 0			; data


			; ascii 47 /    div
			.byte 47	    ; word name etc
			.zero 7
			.quad dsdivz	; function address
			.quad dsdivc    ; compile time
			.quad 0			; data

			; digits, we stack these.

			; ascii 48 0    zero
			.byte 48	    ; word name etc
			.zero 7
			.quad stackit	; function address
			.quad 0		    ; compile time
			.quad 0			; data to stack

			; ascii 49 1    one
			.byte 49	    ; word name etc
			.zero 7
			.quad stackit	; function address
			.quad 0		    ; compile time
			.quad 1			; data to stack

			; ascii 50 2    two
			.byte 50	    ; word name etc
			.zero 7
			.quad stackit	; function address
			.quad 0		    ; compile time
			.quad 2			; data to stack

			; ascii 51 3    three
			.byte 51	    ; word name etc
			.zero 7
			.quad stackit	; function address
			.quad 0		    ; compile time
			.quad 3			; data to stack

			; ascii 52 4    four
			.byte 52	    ; word name etc
			.zero 7
			.quad stackit	; function address
			.quad 0		    ; compile time
			.quad 4			; data to stack

			; ascii 53 5    five
			.byte 53	    ; word name etc
			.zero 7
			.quad stackit	; function address
			.quad 0		    ; compile time
			.quad 5			; data to stack

			; ascii 54 6    
			.byte 54	    ; word name etc
			.zero 7
			.quad stackit	; function address
			.quad 0		    ; compile time
			.quad 6			; data to stack

			; ascii 55 7   
			.byte 55	    ; word name etc
			.zero 7
			.quad stackit	; function address
			.quad 0		    ; compile time
			.quad 7			; data to stack

			; ascii 56 8   
			.byte 56	    ; word name etc
			.zero 7
			.quad stackit	; function address
			.quad 0		    ; compile time
			.quad 8			; data to stack

			; ascii 57 9   
			.byte 57	    ; word name etc
			.zero 7
			.quad stackit	; function address
			.quad 0		    ; compile time
			.quad 9			; data to stack

			; ascii 58 : - define word, docol   
			.byte 58	    ; word name etc
			.zero 7
			.quad dcolonz		; function address of docol
			.quad dcolonc		; compile time action..
			.quad 0			; data to stack

			; ascii 59 ; - end word, semi   
			.byte 59	    ; word name etc
			.zero 7
			.quad dsemiz	; function address of docol
			.quad dsemic	; compile time action..
			.quad 0			; data to stack

			; ascii 60 ; < less than 
			.byte 60	    ; word name etc
			.zero 7
			.quad dltz		; function address of docol
			.quad dltc		; compile time action..
			.quad 0			; data to stack

			; ascii 61 ; = equ 
			.byte 61	    ; word name etc
			.zero 7
			.quad dequz		; function address of docol
			.quad dequc		; compile time action..
			.quad 0			; data to stack

			; ascii 62 >   
			.byte 62	    ; word name etc
			.zero 7
			.quad dgtz		; function address of docol
			.quad dgtc		; compile time action..
			.quad 0			; data to stack

			; ascii 63  ?  
			.byte 63	    ; word name etc
			.zero 7
			.quad dqmz		; function address of docol
			.quad dqmc		; compile time action..
			.quad 0			; data to stack

			; ascii 64  @ fetch  
			.byte 64	    ; word name etc
			.zero 7
			.quad datz		; function address of docol
			.quad datc		; compile time action..
			.quad 0			; data to stack

			; ascii 65 variable A  
			.byte 65	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad  8 * 65 + ivars	 

			; ascii 66 variable B ..  
			.byte 66	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 66 + ivars	

			; ascii 67 variable C ..  
			.byte 67	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 67 + ivars	

			; .. variable 
			.byte 68	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 68 + ivars	

			; .. variable 
			.byte 69	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 69 + ivars	

			; .. variable 
			.byte 70	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 70 + ivars	

			; .. variable 
			.byte 71	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 71 + ivars	

			; .. variable H 
			.byte 72	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 72 + ivars	

			; special I loop vbariable 
			.byte 73	    ; word name etc
			.zero 7
			.quad diloopz	 
			.quad diloopc	 
			.quad 0

			; special J loop variable 
			.byte 74	    ; word name etc
			.zero 7
			.quad djloopz	 
			.quad djloopc	 
			.quad 0

			; special K loop variable 
			.byte 75	    ; word name etc
			.zero 7
			.quad dkloopz	 
			.quad dkloopc	 
			.quad 0

			; .. variable L 
			.byte 76	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 76 + ivars

		 	; .. variable M 
			.byte 77	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 77 + ivars

 			; .. variable N 
			.byte 78	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 78 + ivars

			; .. variable O 
			.byte 79	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 79 + ivars

			; .. variable P 
			.byte 80	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 80 + ivars

			; .. variable Q 
			.byte 81	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 81 + ivars

			; .. variable R 
			.byte 82	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 82 + ivars

			; .. variable S 
			.byte 83	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 83 + ivars

			; .. variable T 
			.byte 84	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 84 + ivars

			; .. variable U 
			.byte 85	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 85 + ivars

			; .. variable V
			.byte 86	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 86 + ivars

			; .. variable W
			.byte 87	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 87 + ivars

			; .. variable X
			.byte 88	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 88 + ivars

			; .. variable Y
			.byte 89	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 89 + ivars

			; .. variable Z
			.byte 90	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 90 + ivars

			; end of A..Z


			; ascii 93 [ lsb stop interpreting and compile
			.byte 91	    ; word name etc
			.zero 7
			.quad dlsbz		; function address  
			.quad dlsbc		; compile time action..
			.quad 0			; data to stack

			; ascii 92 \ 	; slash
			.byte 92	    ; word name etc
			.zero 7
			.quad dshlashz		; function address  
			.quad dshlashc		; compile time action..
			.quad 0			; data to stack

			; ascii 93 ] rsb stop interpreting and compile
			.byte 93	    ; word name etc
			.zero 7
			.quad drsbz		; function address  
			.quad drsbc		; compile time action..
			.quad 0			; data to stack

			
			; ascii 94  top hat
			.byte 94	    ; word name etc
			.zero 7
			.quad dtophatz	; function address  
			.quad dtophatc	; compile time action..
			.quad 0			; data to stack

			; ascii 95  underscore
			.byte 95	    	; word name etc
			.zero 7
			.quad dunderscorez	; function address  
			.quad dunderscorec	; compile time action..
			.quad 0				; data to stack

			; ascii 96  backtick
			.byte 96	    	; word name etc
			.zero 7
			.quad dbacktkz		; function address  
			.quad dbacktkc		; compile time action..
			.quad 0				; data to stack


			;; lower case 


			; ascii 97 variable A  
			.byte 97	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad  8 * 97 + ivars	 

			; ascii 98 variable B ..  
			.byte 98	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 98 + ivars	

			; ascii 99 variable C ..  
			.byte 99	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 99 + ivars	

			; .. variable 
			.byte 100	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 100 + ivars	

			; .. variable 
			.byte 101	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 101 + ivars	

			; .. variable 
			.byte 102	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 102 + ivars	

			; .. variable 
			.byte 103	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 103 + ivars	

			; .. variable H 
			.byte 104	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 104 + ivars	

			; special I loop variable 
			.byte 105	    ; word name etc
			.zero 7
			.quad diloopz	 
			.quad diloopc	 
			.quad 0

			; special J loop variable 
			.byte 106	    ; word name etc
			.zero 7
			.quad djloopz	 
			.quad djloopc	 
			.quad 0

			; special K loop variable 
			.byte 107	    ; word name etc
			.zero 7
			.quad dkloopz	 
			.quad dkloopc	 
			.quad 0

			; .. variable L 
			.byte 108	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 108 + ivars

		 	; .. variable M 
			.byte 109	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 109 + ivars

 			; .. variable N 
			.byte 110	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 110 + ivars

			; .. variable O 
			.byte 111	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 111 + ivars

			; .. variable P 
			.byte 112	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 112 + ivars

			; .. variable Q 
			.byte 113	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 113 + ivars

			; .. variable R 
			.byte 114	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 114 + ivars

			; .. variable S 
			.byte 115	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 115 + ivars

			; .. variable T 
			.byte 116	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 116 + ivars

			; .. variable U 
			.byte 117	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 117 + ivars

			; .. variable V
			.byte 118	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 118 + ivars

			; .. variable W
			.byte 119	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 119 + ivars

			; .. variable X
			.byte 120	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 120 + ivars

			; .. variable Y
			.byte 121	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 121 + ivars

			; .. variable Z
			.byte 122	    ; word name etc
			.zero 7
			.quad dvaraddz	;  
			.quad 0			; compile time action..
			.quad 8 * 122 + ivars


			; ascii 123 {   lcb
			.byte 123	    ; word name etc
			.zero 7
			.quad dlcbz		; function address
			.quad dlcbc    	; compile time
			.quad 0			; data

			; ascii 124 |  pipe
			.byte 124	    ; word name etc
			.zero 7
			.quad dpipez	; function address
			.quad dpipec    ; compile time
			.quad 0			; data

			; ascii 125  } rcb
			.byte 125	    ; word name etc
			.zero 7
			.quad drcbz		; function address
			.quad drcbz    ; compile time
			.quad 0			; data

			; ascii 126 ~  tilde
			.byte 125	    ; word name etc
			.zero 7
			.quad dtildez	; function address
			.quad dtildec   ; compile time
			.quad 0			; data

			; ascii 127 del
			.byte 127	    ; word name etc
			.zero 7
			.quad ddelz		; function address
			.quad ddelc     ; compile time
			.quad 0			; data

			; non ascii 7 bit byte codes
			.rept 127 		; 
			.quad -1		; word name etc
			.quad 0			; function address
			.quad 0			; data
			.quad 0			; data
			.endr

			.quad 0
			.quad 0
			.quad 0
			.quad 0
			.quad 0
			.quad 0
			.quad 0
			.quad 0

			   



