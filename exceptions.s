# SPIM S20 MIPS simulator.
# The default exception handler for spim.
#
# Copyright (c) 1990-2010, James R. Larus.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
#
# Neither the name of the James R. Larus nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific
# prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
# GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# Define the exception handling code.  This must go first!

	.kdata

line_jumps: .asciiz "\n\n\n\n\n"
line_jump: .asciiz "\n"
vidas: .asciiz "vidas: "
puntos: .asciiz "       puntos: "
s1:	.word 0
s2:	.word 0

# This is the exception handler code that the processor runs when
# an exception occurs. It only prints some information about the
# exception, but can server as a model of how to write a handler.
#
# Because we are running in the kernel, we can use $k0/$k1 without
# saving their old values.

	.ktext 0x80000180
	.set noat
	move $k1 $at		# Save $at
	.set at
	sw $v0 s1		# Not re-entrant and we can't trust $sp
	sw $a0 s2		# But we need to use these registers

	mfc0 $k0 $13		# Cause register
	srl $a0 $k0 2		# Extract ExcCode Field
	andi $a0 $a0 0x1f

	
# Interrupt-specific code goes here!
# Don't skip instruction at EPC since it has not executed.

	mtc0 $0, $9				#reinicializo el conteo de ms
	lw $a0, 0xffff0000		#busco si hubo una interrupcion por teclado
	andi $a0, $a0, 0x1		#mediante verificacion del bit Ready
	beqz $a0 check_move		#si no hubo modificacion entonces...
	lw $a0, 0xffff0004		#si la hubo, cargo la tecla que se presiono
	
check_key:
	li $t1, 0x77	#cargo la 'w' para verificar si fue la tecla presionada
	beq $t1, $a0, change_key
	li $t1, 0x73	#cargo la 'a' para verificar si fue la tecla presionada
	beq $t1, $a0, change_key
	li $t1, 0x6b	#cargo la 'k' para verificar si fue la tecla presionada
	beq $t1, $a0, change_key
	li $t1, 0x6c	#cargo la 'l' para verificar si fue la tecla presionada
	beq $t1, $a0, change_key

	b check_move		#si no se cumplio ninguna condicion, entonces mueve el pac con la tecla que tenia
	
	
change_key:
	la $t0, last_key	#guardo la ULTIMA tecla presionada
	sb $t1, 0($t0)
	
	
check_move:
	la $t0, last_key
	lb $t0, 0($t0)

	li $t1, 0x77	#cargo la 'w' para verificar si fue la tecla presionada
	beq $t1, $t0, get_north
	li $t1, 0x73	#cargo la 'a' para verificar si fue la tecla presionada
	beq $t1, $t0, get_south
	li $t1, 0x6b	#cargo la 'k' para verificar si fue la tecla presionada
	beq $t1, $t0, get_west
	li $t1, 0x6c	#cargo la 'l' para verificar si fue la tecla presionada
	beq $t1, $t0, get_east
	
	b end_pacmove	#si todavia no hay una tecla asignada, no mueve (caso inicio juego)
	
	
get_north:
	move $t0, $s6		#Cargo la pos del pac
	sub $t0, $t0, $s7	#muevo el pac hacia arriba, mediante resta de la pos con el numero de elementos de una columna
	lb $t2, 0($t0)		#cargo el caracter de la nueva posicion
	li $t3, 0x76		#coloco el caracter de la nueva forma del pac
	
	b verificar_posible

	
get_south:		#ANALOGO AL move_north
	move $t0, $s6
	add $t0, $t0, $s7
	lb $t2, 0($t0)
	li $t3, 0x5e
	
	b verificar_posible

	
get_east:		#ANALOGO AL move_north
	move $t0, $s6
	addi $t0, $t0, 1
	lb $t2, 0($t0)
	li $t3, 0x3c
	
	b verificar_posible

	
get_west:		#ANALOGO AL move_north
	move $t0, $s6
	addi $t0, $t0, -1
	lb $t2, 0($t0)
	li $t3, 0x3e
	
	
verificar_posible:				#verifico todos los casos posibles (muro, fantasma, punto, cereza)
	li $t1, 0x78				#verificacion de muro
	beq $t1, $t2, rotate_pac	#si encuentro un muro, entonces...
	
	li $t1, 0x61				#verificacion de 'a'
	beq $t1, $t2, add_one
	
	li $t1, 0x2a				#verificacion de '*'
	beq $t1, $t2, add_hundred
	
	li $t1, 0x24				#verificacion de fantasma
	beq $t1, $t2, dead_pac

	b move_pac					#significa que se movio hacia una 'o'
	
	
add_one:				#incremento la puntuacion en 1
	addi, $s4, $s4, 1
	
	b move_pac

	
add_hundred:			#incremento la puntuacion en 100
	addi, $s4, $s4, 100
	
	b move_pac

	
rotate_pac:		#... roto al pac
	sb $t3, 0($s6)
	b move_ghost

	
dead_pac:		#colision con fantasma, de parte del pac o del fantasma

	reset_pac:
		move $t0, $s6		#cargo la posicion del pac
		li $t1, 0x6f	
		sb $t1, 0($t0)		#coloco una 'o' en la posicion del pac
		
		la $t0, pac_start	#cargo la pos inicial del pac
		lw $t0, 0($t0)
		move $s6, $t0		#coloco al pac en su inicio
		li $t1, 0x3c
		sb $t1, 0($s6)		#coloco un < donde comienza el pac
		
		addi $s3, $s3, -1	#resto una vida
		
		la $a0, last_key	#reseteo la tecla
		sb $0, 0($a0)

	reset_inky:	
		la $t0, inky_pos
		lw $t3, 0($t0)		#cargo la pos de inky
		la $t1, inky_habia
		la $t2, inky_start
		lw $t2, 0($t0)		#cargo la posicion de inicio de inky
		
		lb $t9, 0($t1)		#tomo el caracter de lo que habia donde esta inky
		sb $t9, 0($t3)		#coloco el caracter en donde esta el inky
		
		li $t9, 0x6f		
		sb $t9, 0($t1)		#coloco la 'o' como lo que habia en la casilla inicial de inky(siempre es o)
		
		sw $t2, 0($t0)		#coloco a inky donde comienza
		lw $t0, 0($t0)
		li $t9, 0x24
		sb $t9, 0($t0)		#coloco el '$' en la pos inicial de inky
		
	reset_pinky:	
		la $t0, pinky_pos
		lw $t3, 0($t0)
		la $t1, pinky_habia
		la $t2, pinky_start
		lw $t2, 0($t0)
		
		lb $t9, 0($t1)		#tomo el caracter de lo que habia donde esta pinky
		sb $t9, 0($t3)		#coloco el caracter en donde esta el pinky
		
		li $t9, 0x6f		
		sb $t9, 0($t1)		#coloco la 'o' como lo que habia en la casilla inicial de pinky(siempre es o)
		
		sw $t2, 0($t0)		#coloco a pinky donde comienza
		lw $t0, 0($t0)
		li $t9, 0x24
		sb $t9, 0($t0)		#coloco el '$' en la pos inicial de pinky
		
	reset_blinky:	
		la $t0, blinky_pos
		lw $t3, 0($t0)
		la $t1, blinky_habia
		la $t2, blinky_start
		lw $t2, 0($t0)
		
		lb $t9, 0($t1)		#tomo el caracter de lo que habia donde esta blinky
		sb $t9, 0($t3)		#coloco el caracter en donde esta el blinky
		
		li $t9, 0x6f		
		sb $t9, 0($t1)		#coloco la 'o' como lo que habia en la casilla inicial de blinky(siempre es o)
		
		sw $t2, 0($t0)		#coloco a blinky donde comienza
		lw $t0, 0($t0)
		li $t9, 0x24
		sb $t9, 0($t0)		#coloco el '$' en la pos inicial de blinky
	
	b end_pacmove
	

move_pac:
	sb $t3, 0($t0)		#coloco el caracter respectivo en la nueva pos del pac
	li $t1, 0x6f
	sb $t1, 0($s6)		#coloco una 'o' en su vieja pos
	move $s6, $t0
	
	
move_ghost:		#los movimientos de los fantasmas van aqui


end_pacmove:				#imprime todos los nuevos 
	la $a0, line_jumps		#eventualmente este salto de linea deberia dejar al tablero en la misma posicion de la consola 
	li $v0, 4
	syscall
	la $a0, vidas			#imprime "vidas: "
	syscall
	move $a0, $s3			#imprime cuantas vidas le quedan
	li $v0, 1
	syscall
	la $a0, puntos			#imprime "       puntos: "
	li $v0, 4
	syscall
	move $a0, $s4
	li $v0, 1
	syscall
	
	li $v0, 4
	la $a0, line_jump
	syscall
	la $a0, pacmap			#imprimo el mapa, ahora modificado
	syscall
		
# Restore registers and reset procesor state
#
	lw $v0 s1		# Restore other registers
	lw $a0 s2

	.set noat
	move $at $k1		# Restore $at
	.set at

	mtc0 $0 $13		# Clear Cause register

	mfc0 $k0 $12		# Set Status register
	ori  $k0 0x1		# Interrupts enabled
	mtc0 $k0 $12

# Return from exception on MIPS32:
	eret


# Standard startup code.  Invoke the routine "main" with arguments:
#	main(argc, argv, envp)
#

	.data

ulose: .asciiz "\n\n\nTe has quedado sin vidas\n\n\n"
pactext: .asciiz "xxxxxxxx\nx*aaaa*x\nxaaxx$ax\nx$axaaax\nxaaxxa<x\nx*aa$a*x\nxxxxxxxx"
pacmap: .space 2000
last_key: .space 4

#posiciones iniciales
pac_start: .word 0
inky_start: .word 0
pinky_start: .word 0
blinky_start: .word 0

#posiciones actualues (la del pac se guarda en $s6, quizas sea inteligente guardar estas en registro tambien)
inky_pos: .word 0
blinky_pos: .word 0
pinky_pos: .word 0

#direcciones a la cual se mueve(para seguir moviendolo mientras no haya pared)
inky_dir: .space 4
blinky_dir: .space 4
pinky_dir: .space 4

#que habia en la posicion de los fantasmas(podria estar en registro, pero se acaban)	
inky_habia: .space 4
blinky_habia: .space 4
pinky_habia: .space 4

	.text
	.globl __start
	
	
__start:
	la $a0, last_key
	sb $0, 0($a0)
	la $s1, pactext
	li $s7, 0		#contador de cuantas columnas tiene el mapa, esto es para subir o bajar filas
	li $t1, 0xa		#caracter salto de linea para saber cuando termina la columna
	li $s5, 0		#numero de puntos en el nivel
	li $s4, 0		#numero de puntos del pac
	li $s3, 2		#numero de vidas del pac
	li $t9, 0		#contador de cuantos fantasmas ha iniciado
	
	
get_columnas:	#cuenta cuantas columnas tiene el mapa
	lb $t0, 0($s1)
	addi $s1, $s1, 1
	addi $s7, $s7, 1

	bne $t0, $t1, get_columnas
	
	la $s1, pactext	#vuelvo al principio de la matriz
	la $s0, pacmap	#carga el espacio de memoria donde se guardara el mapa que sera modificado
	li $t1, 0x3c	#caracter < para saber donde comienza el pacman
	li $t2, 0x24	#caracter $ para los fantasmas
	
	
loop_map:	#imprime caracter por caracter el mapa del texto(eventualmente buffer) al espacio de memoria modificable
	lb $t0, 0($s1)	
	sb $t0, 0($s0)
	beq $t0, $t1, set_pac 	#si encuentro la posicion del pac, entonces...
	beq $t0, $t2, set_ghost	#si encuentro la posicion de ALGUN fantasma, entonces...
	addi $s0, $s0, 1
	addi $s1, $s1, 1
	li $t3, 0x61
	beq $t3, $t0, contar_uno
	li $t3, 0x2a
	beq $t3, $t0, contar_cien
	
	bnez $t0, loop_map
	b enable_int

	
contar_cien:
	addi $s5, $s5, 100
	b loop_map
	
	
contar_uno:
	addi $s5, $s5, 1
	b loop_map
	
	
set_pac:				#... guardo la posicion del pac
	move $s6, $s0
	la $a0, pac_start
	sw $s0, 0($a0)
	addi $s0, $s0, 1
	addi $s1, $s1, 1
	b loop_map

	
set_ghost:				#...reviso cuantos fantasmas he guardado, y guardo respectivamente
	li $t8, 0
	beq $t8, $t9, set_inky
	
	li $t8, 1
	beq $t8, $t9, set_pinky
	
	li $t8, 2
	beq $t8, $t9, set_blinky
	
	li $t8, 0x6f		#esto es solo en caso de que haya mas de 3 fantasmas(compilacion condicional)
	sb $t8, 0($s0)		#lo que hago es colocar una 'o' en donde va el fantasma extra
	addi $s0, $s0, 1		
	addi $s1, $s1, 1	
	b loop_map

	
set_inky:
	addi $t9, $t9, 1
	
	la $a0, inky_start
	sw $s0, 0($a0)
	
	la $a0, inky_pos
	sw $s0, 0($a0)
	
	la $a0, inky_habia
	li $t8, 0x6f
	sb $t8, 0($a0)

	addi $s0, $s0, 1		
	addi $s1, $s1, 1	
	b loop_map

	
set_pinky:
	addi $t9, $t9, 1
	
	la $a0, pinky_start
	sw $s0, 0($a0)
	
	la $a0, pinky_pos
	sw $s0, 0($a0)
	
	la $a0, pinky_habia
	li $t8, 0x6f
	sb $t8, 0($a0)
	
	addi $s0, $s0, 1		
	addi $s1, $s1, 1	
	b loop_map

	
set_blinky:
	addi $t9, $t9, 1
	
	la $a0, blinky_start
	sw $s0, 0($a0)
	
	la $a0, blinky_pos
	sw $s0, 0($a0)
	
	la $a0, blinky_habia
	li $t8, 0x6f
	sb $t8, 0($a0)
	
	addi $s0, $s0, 1		
	addi $s1, $s1, 1	
	b loop_map

enable_int:	#habilito interrupciones
	mfc0 $t0, $12			#busco el status register
	ori $t0, $t0, 0xff01	#habilito todas las interrupciones (8:15 son los 8 bits de posibles interrupciones, y 1 es el bit que te dice
							#que las interrupciones se habilitan o no. En este caso habilito todas las interrupciones(por ff) y las activo globalmente (por 1)
	mtc0 $t0, $12			#devuelvo el registro modificado
	
	lw $a0, 0xffff0000		#busco la direccion de interrupcion por teclado
	andi $a0, $a0, 0x0		#deshabilito la interrupcion
	sw $a0, 0xffff0000		#devuelvo

	li $t0, 500
	mtc0 $t0, $11			#coloco el tiempo de interrupcion por timer en 500 ms
	mtc0 $0, $9				#inicio el tiempo de conteo en 0 ms
	 

inf_loop:
	
	beqz $s3, game_over
	j inf_loop
	

game_over:
	la $a0, ulose
	li $v0, 4
	syscall
	
	jal main
	nop

	li $v0 10
	syscall			# syscall 10 (exit)

	.globl __eoth
__eoth:

	
