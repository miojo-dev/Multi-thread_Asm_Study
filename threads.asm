section .data
    msg_thread1 db 'Hello from thread 1 to ', 0
    msg_thread2 db 'Hello from thread 2 to ', 0
    msg db 'Type your name: ', 0
    len equ $ - msg

section .bss
    stack2 resb 4096 ; 4KB para stack da thread 2
    name resb 100 ; name buffer
    temp_msg1 resb 100 ; temporary buffer for thread 1
    temp_msg2 resb 100 ; temporary buffer for thread 2

section .text
    global _start

_start:
    mov eax, 4 ; Write method(sys_write)
    mov ebx, 1 ; Output method(std_out)
    mov ecx, msg ; Message
    mov edx, len ; Message size
    int 0x80 ; Kernel call

    mov eax, 3 ; Read method(sys_read)
    mov ebx, 0 ; Input method(std_in)
    mov ecx, name ; Var who stores the input
    mov edx, 99 ; Input max size
    int 0x80 ; Kernel call

    ; Create thread 1
    mov eax, 120 ; syscall clone
    mov ebx, 0x4111 ; CLONE_VM - share memory
    mov ecx, 0 ; stack (NULL = use current stack)
    int 0x80
    test eax, eax
    je thread1_func ; if eax == 0, we are in the child (thread 1)

    ; Create thread 2
    mov eax, 120 ; syscall clone
    mov ebx, 0x4111 ; CLONE_VM
    mov ecx, stack2 + 4096 ; top of the stack (grows down)
    int 0x80
    test eax, eax
    je thread2_func ; if eax == 0, we are in the child (thread 2)

    ; wait the threads to finish
    mov eax, 114 ; syscall wait4
    mov ebx, -1 ; wait any child
    mov ecx, 0 ; status
    mov edx, 0 ; options
    mov esi, 0
    int 0x80

    ; exit
    mov eax, 1 ; syscall exit
    xor ebx, ebx
    int 0x80

thread1_func:
    ; thead 1 code
    mov esi, msg_thread1 ; 1st string
    mov edi, name ; 2nd string
    mov eax, temp_msg1 ; buffer destiny
    call concat_strings ; call func to concat strings

    ; write concatenated msg
    mov ebx, 1 ; stdout
    mov ecx, temp_msg1 ; concatenated msg
    mov edx, eax ; returned size
    mov eax, 4 ; write
    int 0x80

    ; exit thread
    mov eax, 1 ; syscall exit
    xor ebx, ebx
    int 0x80

thread2_func:
    ; thread 2 code
    mov esi, msg_thread2 ; 1st string
    mov edi, name ; 2nd string
    mov eax, temp_msg2 ; buffer destiny
    call concat_strings ; same func

    ; write concatenated msg
    mov ebx, 1 ; stdout
    mov ecx, temp_msg2 ; concatenated msg
    mov edx, eax ; returned size
    mov eax, 4 ; write
    int 0x80

    ; exit thread
    mov eax, 1
    xor ebx, ebx
    int 0x80

concat_strings:
    push ebx
    push ecx
    push edx

    ; copy 1st string
    mov ebx, esi ; ebx = src1
    mov ecx, eax ; ecx = dest

.copy_loop1:
    mov dl, [ebx] ; read character
    mov [ecx], dl ; write on destiny
    inc ebx
    inc ecx
    cmp dl, 0 ; end of the string?
    jne .copy_loop1

    dec ecx ; remove null char

    ; copy 2nd string
    mov ebx, edi ; ebx = src2

.copy_loop2:
    mov dl, [ebx] ; read character
    mov [ecx], dl ; write on destiny
    inc ebx
    inc ecx
    cmp dl, 0 ; end of the string?
    jne .copy_loop2

    ; calculate total size
    sub ecx, eax ; ecx - eax = size
    mov eax, ecx ; return size

    pop edx
    pop ecx
    pop ebx
    ret