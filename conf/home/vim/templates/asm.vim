; fucking masm
; vim:ft=asm

assume cs:code,ds:data

data segment
data ends

stack segment
stack ends

code segment
start:

	mov ax,4c00h
	int 21h
code ends

end start
