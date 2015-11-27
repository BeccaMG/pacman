	.data
mprof:	.ascii "/// Este mensaje indica que el proyecto 2 ha finalizado y es de los Profesores del curso ///\n"
        .asciiz "El programa que se usara en la correccion puede ser diferente del que aqui se entrega\n"

	.text
	#  Programa que inprime un mensaje por pantalla
	#  Su unica utilidad es evitar que el QtSpim indique que no ha sido cargado un programa para ejecutar

	
main:
	la $a0, mprof
	li $v0, 4
	syscall
	
	jr $ra