; ------------------------------------------------------------------------------
; Linux System NASM Assembler program to output a file
; as just 1's and 0's.  Just like 'cat' but less useful.
;
; This code uses x86_64 Linux System Calls.
;
; Author: Paul Hornsey (paul@1partcarbon.co.uk)
;
; Copyright 2014 1partCarbon Ltd.
; ------------------------------------------------------------------------------

section .data
        usage_msg:              db 'Usage: bincat [FILE]'
        usage_msg_len:          equ $-usage_msg
        byte_buffer:            times 8 db 0  ; to store converted ascii bytes.
        newline:                db 10
        read_buffer_length:     equ 1024
        file_error_msg:         db 'bincat: Error reading file.', 10
        file_error_msg_len:     equ $-file_error_msg

section .bss
        file_descriptor:        resw 2      ; syscall int
        read_buffer:            resb 1024   ; Must match read_buffer_length

section .text
        global _start

_start:
        pop     rbx                         ; argc (Number of arguments)
        cmp     rbx, 2                      ; 2 arguments expected (command, filename)
        jne     print_usage                 ; print usage then exit if no filename

        pop     rbx                         ; First arg is the command name
        pop     rbx                         ; The file to print out

open_file:
        mov     rax, 2                      ; int sys_open(
        mov     rdi, rbx                    ;   const char *pathname
        mov     rsi, 0                      ;   int flags)
        syscall                             ; return file descriptor in rax or -1 on error
        and    rax, rax                     ; set flags for return value
        js     print_file_error_then_exit   ; jump if - Failed to open file

file_opened:
        mov     [file_descriptor], rax      ; save descriptor for closing

read_file:
        mov     rax, 0                      ; ssize_t sys_read(
        mov     rdi, [file_descriptor]      ;   file descriptor into param 2
        mov     rsi, read_buffer            ;   void *buf
        mov     rdx, read_buffer_length     ;   size_t count)
        syscall
        cmp     rax, 0
        jle     finish_reading              ; Jump if read to end or error
        mov     r8, rax

        mov     rbx, 0
convert_byte:
        mov     rdx, byte_buffer            ; rdx - address of byte display string
        mov     rsi, [read_buffer+rbx]      ; rsi - loadwith next byte to convert
        call byte2str

output_bit_string:
        mov     rax, 1                      ; sys_write
        mov     rdi, 1                      ; File descriptor 1 for stdout
        mov     rsi, byte_buffer
        mov     rdx, 8
        syscall

next_byte:
        inc     rbx                         ; Move the buffer offset on
        dec     r8                          ; Count down bytes left to convert
        jnz     convert_byte                ; Loop until all buffered bytes printed

        jmp     read_file                   ; Jumps back to load more from the file.

finish_reading:

close_test_file:
        mov     rax, 3                      ; sys_close
        mov     rdi, [file_descriptor]      ; the file descriptor
        syscall

exit:
        jmp     print_newline_then_exit

; ------------------------------------------------------------------------------
; Procedure to print a byte as eight ascii '1's and '0's
;
; rsi - The byte to convert
; rdx - Start address of the output string of '1's and '0's
; ------------------------------------------------------------------------------
byte2str:
        push    rbx
        mov     rbx, 128                    ; 10000000b msb for test mask
until_all_bits_converted:
        test    rsi, rbx                    ; test bit that rbx masks
        jnz     one                         ; jump if bit a 1
        mov     byte [rdx], 48              ; else bit is a 0
        jmp     move_to_next_bit
one:
        mov     byte [rdx], 49
move_to_next_bit:
        inc     rdx
        shr     rbx, 1
        jnz     until_all_bits_converted
        pop     rbx
        ret

; ------------------------------------------------------------------------------
print_usage:
        mov     rax, 1                      ; sys_write
        mov     rdi, 1                      ; File descriptor 1 for stdout
        mov     rsi, usage_msg
        mov     rdx, usage_msg_len
        syscall
        ; fall through to print_newline_then_exit

; ------------------------------------------------------------------------------
print_newline_then_exit:
        mov     rax, 1                      ; sys_write
        mov     rdi, 1                      ; File descriptor 1 for stdout
        mov     rsi, newline
        mov     rdx, 1
        syscall
        ; fall through to exit_0

; ------------------------------------------------------------------------------
; Use the system exit(0) to exit the program totally
exit_0:
        mov     rax, 60                     ; sys_exit
        mov     rdi, 0
        syscall

; ------------------------------------------------------------------------------
print_file_error_then_exit:
        mov     rax, 1                      ; sys_write
        mov     rdi, 1                      ; File descriptor 1 for stdout
        mov     rsi, file_error_msg
        mov     rdx, file_error_msg_len
        syscall
        mov     rax, 60                     ; sys_exit
        mov     rdi, 1
        syscall
; ------------------------------------------------------------------------------
