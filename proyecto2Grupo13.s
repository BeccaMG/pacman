#********$****************>****************$*************<********************>#
#*                                                                            *#
#*                             PROYECTO 2: PACMAN                             *#
#*                             ==================                             *#         
#*     Realizado por:                                                         *# 
#*              Rebeca Machado      10-10406                                  *#  
#*              Gabriel Gedler      10-10272            Sección: 1            *#
#*                                                                            *#
#***$**<***$***********$****>****************************<***********$*********#


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
	sw $v0 s1		    # Not re-entrant and we can't trust $sp
	sw $a0 s2		    # But we need to use these registers

	mfc0 $k0 $13		# Cause register
	srl $a0 $k0 2		# Extract ExcCode Field
	andi $a0 $a0 0x1f
	
# Interrupt-specific code goes here!
# Don't skip instruction at EPC since it has not executed.


################################################################################
#                                                                              #
#                   COMIENZA EL MANEJADOR DE INTERRUPCIONES                    #
#                                                                              #
################################################################################

    li $t0, 0xffff                  # Esto para retrasar un poco el movimiento
                                    # de los fantasmas, al igual que cuando se
                                    # se reinicia el timer (es mejor que habilitar
                                    # y deshabilitar las interrupciones)
loop1:
	mtc0 $0, $9				        # Reinicializo el conteo de ms
	lw $a0, 0xffff0000		        # Busco si hubo una interrupción por teclado
	andi $a0, $a0, 0x1		        # Mediante verificación del bit Ready
    addi $t0, -1                    # Decremento el contador del ciclo
    bnez $a0, check_key             # Si hubo interrupción por teclado
    bnez $t0, loop1
	beqz $a0, move_ghost            # Si no hay interrupción por teclado, mueve
                                    # solos a los fantasmas
	

################################################################################
#                                                                              #
#                           MOVIMIENTO DEL PACMAN                              #
#                                                                              #
################################################################################

check_key:
    mtc0 $0, $9
    lw $a0, 0xffff0004		        # Carga la tecla presionada
	li $t1, 0x77	                # Cargo la 'w' para verificar si fue la tecla presionada
	beq $t1, $a0, get_north
	li $t1, 0x73	                # Cargo la 's' para verificar si fue la tecla presionada
	beq $t1, $a0, get_south
	li $t1, 0x6b	                # Cargo la 'k' para verificar si fue la tecla presionada
	beq $t1, $a0, get_west
	li $t1, 0x6c	                # Cargo la 'l' para verificar si fue la tecla presionada
	beq $t1, $a0, get_east
    li $t1, 0x71                    # Cargo la 'q' para salir
    beq $t1, $a0, quit

	b move_ghost	                # Si no es ninguna tecla, que se sigan moviendo los fantasmas
	
	
get_north:
	move $t0, $s6		            # Cargo la pos del pac
	sub $t0, $t0, $s7	            # Muevo el pac hacia arriba, mediante resta de la pos 
                                    # con el número de elementos de una columna
	lb $t2, 0($t0)		            # Cargo el caracter de la nueva posición
	li $t3, 0x76		            # Coloco el caracter de la nueva forma del pac (v)
	
	b verificar_posible             # Verifico si es un movimiento posible

	
get_south:		                    # ANÁLOGO AL get_north
	move $t0, $s6
	add $t0, $t0, $s7
	lb $t2, 0($t0)
	li $t3, 0x5e                    # Nueva forma del pac (^)
	
	b verificar_posible

	
get_east:		                    # ANÁLOGO AL get_north
	move $t0, $s6
	addi $t0, $t0, 1
	lb $t2, 0($t0)
	li $t3, 0x3c                    # Nueva forma del pac (<)
	
	b verificar_posible

	
get_west:		                    # ANÁLOGO AL move_north
	move $t0, $s6
	addi $t0, $t0, -1
	lb $t2, 0($t0)
	li $t3, 0x3e                    # Nueva forma del pac (>)
	
	
verificar_posible:				    # Verifico todos los casos posibles (muro, fantasma, punto, cereza)
	mtc0 $0, $9	
    li $t1, 0x58				    # Verificación de muro
	beq $t1, $t2, rotate_pac	    # Si encuentro un muro, entonces...
	
	li $t1, 0x61				    # Verificación de 'a'
	beq $t1, $t2, add_one
	
	li $t1, 0x2a				    # Verificación de '*'
	beq $t1, $t2, add_hundred
	
	li $t1, 0x24				    # Verificación de fantasma
	beq $t1, $t2, dead_pac

	b move_pac					    # Significa que se movio hacia una 'o'
	

################################################################################
#                                                                              #
#                          ACTUALIZACIÓN DE PUNTOS                             #
#                                                                              #
################################################################################   
 
add_one:				            # Incremento la puntuación en 1
	addi, $s4, $s4, 1
	mtc0 $0, $9
	b move_pac

	
add_hundred:			            # Incremento la puntuación en 100
	addi, $s4, $s4, 100
	mtc0 $0, $9	
	b move_pac

	
rotate_pac:		                    # ... roto al pac
	sb $t3, 0($s6)
    mtc0 $0, $9
	b end_pacmove
    

################################################################################
#                                                                              #
#                              MUERTE DEL PACMAN                               #
#                                                                              #
################################################################################

dead_pac:		                    # Colisión con fantasma, de parte del pac o del fantasma

	reset_pac:
		move $t0, $s6		        # Cargo la posición del pac
		li $t1, 0x6f	
		sb $t1, 0($t0)		        # Coloco una 'o' en la posición del pac
		
		la $t0, pac_start	        # Cargo la pos inicial del pac
		lw $t0, 0($t0)
		move $s6, $t0		        # Coloco al pac en su inicio
		li $t1, 0x3c
		sb $t1, 0($s6)		        # Coloco un < donde comienza el pac
		
		addi $s3, $s3, -1	        # Resto una vida
		
        mtc0 $0, $9
        
	b end_pacmove   

move_pac:
    mtc0 $0, $9	
	sb $t3, 0($t0)		            # Coloco el caracter respectivo en la nueva pos del pac
	li $t1, 0x6f
	sb $t1, 0($s6)	    	        # Coloco una 'o' en su vieja pos
	move $s6, $t0                   # Actualizo la posición
	
    
################################################################################
#                                                                              #
#                           MOVIMIENTO DE FANTASMAS                            #
#                                                                              #
################################################################################ 
	
move_ghost:
    mtc0 $0, $9
    
    move_inky:
        la $t0, inky_dir            # Cargo la dirección en la que iba
        lb $t0, 0($t0)              # Esta es la letra que indica la dirección         
        lw $a1, inky_pos            # Cargo su posición
        la $t5, inky_habia          # Cargo lo que habia en su posición
        lb $t6, 0($t5)              # El caracter que estaba
        li $t8, -1                  # Cargo -1 porque es el primer fantasma
        b check_ghost_move          # Voy a moverlo
        
    move_pinky:                     
        la $t0, pinky_dir
        lb $t0, 0($t0)
        lw $a1, pinky_pos           
        la $t5, pinky_habia         
        lb $t6, 0($t5)              
        addi $t8, 1                 # Le sumo 1, para que al dar 0, sea el segundo fantasma
        b check_ghost_move
    
    move_blinky:
        la $t0, blinky_dir
        lb $t0, 0($t0)
        lw $a1, blinky_pos          
        la $t5, blinky_habia        
        lb $t6, 0($t5)              
        li $t8, 1                   # Cargo 1, es el tercer fantasma
        
    check_ghost_move:
        li $t3, 0x24                # Caracter que esta en la posición del fantasma ($)
        li $t1, 0x77	            # Cargo la 'w'
        beq $t1, $t0, get_north_ghost
        li $t1, 0x73	            # Cargo la 's'
        beq $t1, $t0, get_south_ghost
        li $t1, 0x6b	            # Cargo la 'k'
        beq $t1, $t0, get_west_ghost
        li $t1, 0x6c	            # Cargo la 'l'
        beq $t1, $t0, get_east_ghost
        bltz $t8, move_pinky
        beqz $t8, move_blinky       # Aquí verifico cuál es el siguiente en mover
        bgtz $t8, end_pacmove
        
    
get_north_ghost:
    move $a0, $a1                   # Guardo la posición anterior
    sub $a1, $a1, $s7               # Lo muevo hacia arriba restando columnas
    lb $t2, 0($a1)                  # Cargo el caracter de la nueva posición
    
    b verificar_posible_ghost
    
get_south_ghost:
    move $a0, $a1                   # Guardo la posición anterior
    add $a1, $a1, $s7               # Sumo las columnas para moverlo hacia abajo
    lb $t2, 0($a1)
    
    b verificar_posible_ghost
    
get_east_ghost:
    move $a0, $a1                   # Guardo la posición anterior
    addi $a1, $a1, 1                # Lo muevo a la derecha
    lb $t2, 0($a1)

    b verificar_posible_ghost
    
get_west_ghost:
    move $a0, $a1                   # Guardo la posición anterior
    addi $a1, $a1, -1               # Lo muevo a la izquierda
    lb $t2, 0($a1)

    
verificar_posible_ghost:
    mtc0 $0, $9
    move $t0, $0                    # Limpia la tecla para que no se vaya a ningun loop
	li $t1, 0x58				    # Verificación de muro
	beq $t1, $t2, choose_dir	    # Si encuentro un muro, entonces aleatorio
    li $t1, 0x76
    beq $t1, $t2, dead_pac          
    li $t1, 0x5e
    beq $t1, $t2, dead_pac
    li $t1, 0x3c                    # Muerte de todos los caracteres posibles del pac
    beq $t1, $t2, dead_pac
    li $t1, 0x3e
    beq $t1, $t2, dead_pac
    li $t1, 0x24
    beq $t1, $t2, choose_dir        # Si se choca con otro fantasma, aleatorio
    sb $t6, 0($a0)                  # Si no sucede nada, guardo el caracter de "ghost_habia"
                                    # en la antigua posición (a0)
    sb $t3, 0($a1)                  # Coloco el '$' en la nueva posición
    sb $t2, 0($t5)                  # Coloco el caracter que había en la nueva posición
                                    # como el nuevo "ghost_habia"

save_ghost:                         # Guarda las nuevas posiciones de todos los fantasmas
    bltz $t8, save_inky
    beqz $t8, save_pinky
    bgtz $t8, save_blinky
    
    save_inky:
        sw $a1, inky_pos
        b check_ghost_move
        
    save_pinky:
        sw $a1, pinky_pos
        b check_ghost_move
        
	save_blinky:
        sw $a1, blinky_pos
        b check_ghost_move


################################################################################
#                                                                              #
#                     GENERACIÓN DE DIRECCIONES ALEATORIAS                     #
#           (basado en el archivo aleatorio.s tomado de Aula Virtual)          #
################################################################################
        
choose_dir:
    mtc0 $0, $9	      
    li $t1, 70                      # Veces que se ejecuta el ciclo, 70 para mayor aleatoriedad
	li $t0, 4                       # Rango de los valores aleatorios a generar, 
                                    # 4 pues son 4 puntos cardinales.
    move $t3, $0                    
    move $t4, $0
    move $t5, $0                    # Limpio los registros a usar (para que funcionen
    move $t6, $0                    # los xor basados en 0)
    
loop2:
    mtc0 $0, $9
	srl $t3, $a3, 3                 # La semilla se guarda en a3
	xor $t4, $t3, $a3
	sll $t5, $t4, 5
	xor $t6, $t5, $t4
	addi $t1, $t1, -1
	
	move $a3, $t6

	bgtz $t1, loop2  
    div $t6, $t0      
    mfhi $t9	                    # Se obtiene el mod para reducir la cantidad de valores aletaorios a generar
	abs $t9, $t9                    # Se calcula el valor absoluto para sólo generar valores positivos
	bltz $t8, change_dir_inky
    beqz $t8, change_dir_pinky
    bgtz $t8, change_dir_blinky
    
    # Para cada fantasma, los números obtenidos significan una dirección distinta
    change_dir_inky:
        la $t0, inky_dir
        li $t1, 0x73	            # Cargo la 's' para cambiar
        sb $t1, 0($t0)
        li $t2, 0
        beq $t2, $t9, move_pinky
        li $t1, 0x6b	            # Cargo la 'k' para cambiar
        sb $t1, 0($t0)
        li $t2, 1
        beq $t2, $t9, move_pinky
        li $t1, 0x77	            # Cargo la 'w' para cambiar
        sb $t1, 0($t0)
        li $t2, 2
        beq $t2, $t9, move_pinky
        li $t1, 0x6c	            # Cargo la 'l' para cambiar
        sb $t1, 0($t0)
        b move_pinky
        
    change_dir_pinky:
        la $t0, pinky_dir
        li $t1, 0x77	            # Cargo la 'w' para cambiar
        sb $t1, 0($t0)
        li $t2, 0
        beq $t2, $t9, move_blinky
        li $t1, 0x73	            # Cargo la 's' para cambiar
        sb $t1, 0($t0)
        li $t2, 1
        beq $t2, $t9, move_blinky
        li $t1, 0x6b	            # Cargo la 'k' para cambiar
        sb $t1, 0($t0)
        li $t2, 2
        beq $t2, $t9, move_blinky
        li $t1, 0x6c	            # Cargo la 'l' para cambiar
        sb $t1, 0($t0)
        b move_blinky
        
    change_dir_blinky:
        la $t0, blinky_dir
        li $t1, 0x6c	            # Cargo la 'l' para cambiar
        sb $t1, 0($t0)
        li $t2, 0
        beq $t2, $t9, end_pacmove
        li $t1, 0x6b	            # Cargo la 'k' para cambiar
        sb $t1, 0($t0)
        li $t2, 1
        beq $t2, $t9, end_pacmove
        li $t1, 0x73	            # Cargo la 's' para cambiar
        sb $t1, 0($t0)
        li $t2, 2
        beq $t2, $t9, end_pacmove
        li $t1, 0x77	            # Cargo la 'w' para cambiar
        sb $t1, 0($t0)
        b end_pacmove


################################################################################
#                                                                              #
#                            IMPRESION DEL MAPA                                #
#                                                                              #
################################################################################

end_pacmove:				
    li $a0, 1
	la $a0, line_jumps		        # Imprime varios saltos de línea
	li $v0, 4
	syscall
	la $a0, vidas			        # Imprime "vidas: "
	syscall
	move $a0, $s3			        # Imprime cuantas vidas le quedan
	li $v0, 1
	syscall
	la $a0, puntos			        # Imprime "       puntos: "
	li $v0, 4
	syscall
	move $a0, $s4
	li $v0, 1
	syscall
	
	li $v0, 4
	la $a0, line_jump
	syscall
    
	la $a0, pacmap			        # Imprimo el mapa, ahora modificado
	syscall
    la $a0, line_jumps		        
	syscall
    syscall
    
quit:
    move $v1 $a0                    # Mueve la tecla presionada que estará guardada
                                    # en a0 para verificar en el ciclo

		
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
#------------------------------------------------------------------------------#
#---------------------------fin de área del kernel-----------------------------#
#------------------------------------------------------------------------------#



################################################################################
#                                                                              #
#                   COMIENZA EL AREA DE DATOS DEL USUARIO                      #
#                                                                              #
################################################################################

        .data
ulose:          .asciiz "\n\n\nTe has quedado sin vidas :(\n\n          GAME OVER\n\n\n"
pactext:        .asciiz "pac.txt"
archivox:       .space 50
pacmap:         .space 2000
archivo:        .space 5000
last_level:     .word 0
line_jumps:     .asciiz "\n\n\n\n\n\n\n"
line_jump:      .asciiz "\n"
vidas:          .asciiz "vidas: "
puntos:         .asciiz "       puntos: "
saludo:         .asciiz "\nBienvenido al juego de PACMAN :D Presiona enter para cargar pac.txt\no introduce el nombre de otro archivo\n"
opening:        .asciiz "Abriendo "
press_enter:    .asciiz "  Presiona ENTER para empezar a jugar. Recuerda que puedes salir presionando q\n\n"
next:           .asciiz "Felicidades, pasaste de nivel. "
uscored:        .asciiz "Obtuviste "
win:            .asciiz "No hay más niveles... ¡GANASTE!\n\n\n\n\n"
points:         .asciiz " puntos :D\n\n\n"

# Posiciones iniciales
pac_start:      .word 0

# Posiciones actualues (la del pac se guarda en $s6)
inky_pos:       .word 0
blinky_pos:     .word 0
pinky_pos:      .word 0

# Dirección a la cual se mueve
inky_dir:       .space 1
blinky_dir:     .space 1
pinky_dir:      .space 1

# Caracter en la posición de los fantasmas
inky_habia:     .space 1
blinky_habia:   .space 1
pinky_habia:    .space 1


################################################################################
#                                                                              #
#                     COMIENZA EL PROGRAMA DEL USUARIO                         #
#                                                                              #                                        
################################################################################
	
        .text
        .globl __start
	
__start:
	
    la $a0 saludo                   # Muestro un mensaje de saludo
    li $v0 4
    syscall
    
    la $a0 archivox 
    li $a1 49
    li $v0 8                        # Pregunto por el nuevo archivo
    syscall
    
    lb $t0 0($a0)                   # Cargo el primer byte de lo leido
    li $v1, 0xa                     # Cargo el caracter salto de linea
    
    la $a0 opening                  # Escribo un mensaje de "abriendo..."
    li $v0 4
    syscall
    
    bne $t0, $v1 abrir_otro         # Si es distinto de enter, abro otro
    
abrir_pac:
    la $a0 pactext                  # Muestro el nombre del archivo que se abre
    li $v0 4                        # Ruta pac.txt
    syscall   
    b continue

abrir_otro:
    la $a0 archivox
    li $v1, 0xa
loopa:
    lb $a1, 0($a0)
    addi $a0, 1                     # Este ciclo es para colocar un caracter nulo al final del nombre
    bne $v1, $a1, loopa
    addi $a0, -1
    sb $0, 0($a0)
    la $a0 archivox
    li $v0 4
    syscall
      
continue:
    li $a1, 0                       # Flags read only
    li $a2, 0x1ff                   # Permisos
    li $v0, 13                      # Abrir archivo
    syscall
    
    move $a0, $v0                   # Moviendo file descriptor
    la $a1, archivo                 # Guardando lo leido en memoria
    li $a2, 2000                    # Bytes a leer
    li $v0, 14                      # Llamada a leer archivo
    syscall
    
    li $v0, 16                      # Cerrar archivo
    syscall
    
    la $s1, archivo
    sw $s1, last_level              # Guardo la dirección como el ultimo nivel cargado

show_press_enter:
    la $a0 press_enter
    li $v0 4                        # Mensaje de presionar ENTER
    syscall

enter_loop1:                        # No empieza hasta que no se presione el enter
    li $v0, 12
    syscall
    li $a0, 0xa
    bne $v0, $a0, enter_loop1
    
begin:    
    lw $s1, last_level              # Carga el ultimo nivel
	li $s3, 3		                # Número de vidas del pac
    li $s4, 0		                # Número de puntos del pac
    li $s5, 0		                # Número de puntos en el nivel
    li $s7, 0		                # Contador de cuantas columnas tiene el mapa
    li $t1, 0xa		                # Caracter salto de linea para saber cuando terminan las columnas
	
get_columnas:	                    # Cuenta las columnas del mapa
	lb $t0, 0($s1)
	addi $s1, $s1, 1
	addi $s7, $s7, 1

	bne $t0, $t1, get_columnas      # Hasta que no sea salto de linea, sigue en loop
	
	lw $s1, last_level	            # Vuelvo al principio de la matriz
	la $s0, pacmap	                # Carga el espacio de memoria donde se guardará el mapa que será modificado
	li $t1, 0x3c	                # Caracter < para saber donde comienza el pacman
	li $t2, 0x24	                # Xaracter $ para los fantasmas
    li $t4, 0xa                     # Caracter salto de línea
    li $t5, 2                       # Contador de saltos de linea (para saber cuando hay 2 seguidos)
    li $t9, 0
    
    
################################################################################
#                                                                              #
#                             GENERACIÓN DE MAPAS                              #
#                                                                              #                                        
################################################################################ 

loop_map:	                        # Imprime caracter por caracter el mapa del texto en el espacio de memoria modificable
	lb $t0, 0($s1)	
	sb $t0, 0($s0)
    beq $t0, $t4, add_enter         # Si es un enter, que sume uno
	beq $t0, $t1, set_pac 	        # Si encuentro la posición del pac, entonces...
	beq $t0, $t2, set_ghost	        # Si encuentro la posición de ALGUN fantasma, entonces...
    li $t5, 2                       # Voy reinicializando 2 cuando el siguiente no es salto de línea de nuevo
	addi $s0, $s0, 1                # Avanzo en memoria
	addi $s1, $s1, 1
	li $t3, 0x61                    # Caracter 'a'
	beq $t3, $t0, contar_uno
	li $t3, 0x2a                    # Caracter '*'
	beq $t3, $t0, contar_cien
	
	bnez $t0, loop_map
    beqz $t0, end_levels            # Cuando es nulo, se terminaron los niveles
    
    
stop:
    addi $s1, 1
    sw $s1, last_level              # Aquí lo deja en la línea siguiente para el nuevo nivel
	b enable_int

add_enter:                          # Cuenta un salto de línea (para separación de niveles)
    addi $t5, -1
    beqz $t5, stop
    addi $s0, $s0, 1
	addi $s1, $s1, 1
    b loop_map

# Se cuentan los puntos del nivel    

contar_cien:
	addi $s5, $s5, 100
	b loop_map
	
contar_uno:
	addi $s5, $s5, 1
	b loop_map
	
set_pac:				            # ... guardo la posición del pac
	move $s6, $s0
	la $a0, pac_start
	sw $s0, 0($a0)
	addi $s0, $s0, 1
	addi $s1, $s1, 1
	b loop_map

set_ghost:				            # ...reviso cuantos fantasmas he guardado, y guardo respectivamente
	li $t8, 0
	beq $t8, $t9, set_inky
	
	li $t8, 1
	beq $t8, $t9, set_pinky
	
	li $t8, 2
	beq $t8, $t9, set_blinky
    
	addi $s0, $s0, 1		
	addi $s1, $s1, 1	
	b loop_map

    
set_inky:
	addi $t9, $t9, 1
	
	la $a0, inky_pos
	sw $s0, 0($a0)
	
	la $a0, inky_habia
	li $t8, 0x6f
	sb $t8, 0($a0)
    
    li $t8, 0x77                    # Cargo la 'w' para que los fantasmas se muevan en esa dirección
    la $a0, inky_dir                # Lo guardo como última tecla
	sb $t8, 0($a0)

	addi $s0, $s0, 1		
	addi $s1, $s1, 1	
	b loop_map

	
set_pinky:
	addi $t9, $t9, 1
	
	la $a0, pinky_pos
	sw $s0, 0($a0)
	
	la $a0, pinky_habia
	li $t8, 0x6f
	sb $t8, 0($a0)
    
    li $t8, 0x77                    # Cargo la 'w' para que los fantasmas se muevan en esa dirección
    la $a0, pinky_dir
    sb $t8, 0($a0)
	
	addi $s0, $s0, 1		
	addi $s1, $s1, 1	
	b loop_map

	
set_blinky:
	addi $t9, $t9, 1

	la $a0, blinky_pos
	sw $s0, 0($a0)
	
	la $a0, blinky_habia
	li $t8, 0x6f
	sb $t8, 0($a0)
    
    li $t8, 0x77                    # Cargo la 'w' para que los fantasmas se muevan en esa dirección
    la $a0, blinky_dir
    sb $t8, 0($a0)
	
	addi $s0, $s0, 1		
	addi $s1, $s1, 1	
	b loop_map

    
################################################################################
#                                                                              #
#                           HABILITAR INTERRUPCIONES                           #
#                                                                              #
################################################################################

enable_int:	#habilito interrupciones

	mfc0 $t0, $12			        # Busco el status register
	ori $t0, $t0, 0xfff1            # Habilito todas las interrupciones
	mtc0 $t0, $12			        # Devuelvo el registro modificado

	li $t0, 200
    mtc0 $t0, $11			        # Coloco el tiempo de interrupción por timer en 35 ms
	mtc0 $0, $9				        # Inicio el tiempo de conteo en 0 ms
    li $a3, 0xB9                    # Guardo la semilla de aleatoriedad


################################################################################
#                                                                              #
#                               CÓDIGO DEL JUEGO                               #
#                                                                              #
################################################################################    

inf_loop:
	beqz $s3, game_over             # Si se acaban las vidas, pierde
    li $t0 0x71                     # Si la tecla presionada es la 'q'
    beq $v1 $t0 exit
    beq $s4, $s5, next_level        # Si ya tiene todos los puntos
	j inf_loop
	
next_level:
    mfc0 $a0, $12
    andi $a0, 0x0                   # Paro las interrupciones
    mtc0 $a0, $12
    lw $a0, last_level              # Pregunto si queda algún otro nivel
    addi $a0, 2
    lb $a0, 0($a0)
    beqz $a0, end_levels            # Si no quedan, gana
    
    la $a0, next                    # Carga mensaje de paso de nivel
    li $v0, 4
    syscall
    la $a0, uscored
    syscall
    move $a0, $s4                   # Carga puntos acumulados
    li $v0, 1
    syscall
    la $a0, points
    li $v0, 4
    syscall
    
    b show_press_enter
    
game_over:
	la $a0, ulose
	li $v0, 4
	syscall
    la $a0, uscored                 # Mensaje de GAME OVER y puntos
    syscall
    move $a0, $s4
    li $v0, 1
    syscall
    la $a0, points
    li $v0, 4
    syscall
    b exit
    
end_levels:
    la $a0, win
    li $v0, 4                       # Mensaje de juego finalizados
    syscall
    
exit:	
	jal main
	nop
                                    # Se sale del manejador de excepciones
	li $v0 10
	syscall	

        .globl __eoth
__eoth:

	
