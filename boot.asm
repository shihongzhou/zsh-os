[ORG  0x7c00]

[SECTION .text]
[BITS 16]
global _start
_start:
    xchg    bx, bx
    ; 设置屏幕模式为文本模式，清除屏幕
    mov ax, 3
    int 0x10

    mov     ax, 0
    mov     ss, ax
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax
    mov     si, ax

    mov     si, msg
    call    print

    ; 将字符串 "test floppy" 写入软盘第二扇区
    mov si, write_msg
    call write_floppy

    ; 读取软盘第二扇区并显示
    call read_floppy
    call print

    jmp     $     ;死循环

; 如何调用
; mov     si, msg   ; 1 传入字符串
; call    print     ; 2 调用
print:
    mov ah, 0x0e
    mov bh, 0
    mov bl, 0x01
.loop:
    mov al, [si]
    cmp al, 0
    jz .done
    int 0x10

    inc si
    jmp .loop
.done:
    ret

; 将字符串写入软盘
write_floppy:
    mov ax, 0x0301         ; 功能号：写扇区，1扇区
    mov bx, si             ; 数据缓冲区
    mov cx, 0x0002         ; 磁道0，扇区2
    mov dx, 0x0000         ; 磁头0，驱动器A
    int 0x13               ; 调用 BIOS 中断写入扇区
    ret

; 从软盘读取扇区到内存
read_floppy:
    mov ax, 0x0201         ; 功能号：读取扇区，1扇区
    mov bx, 0x0500    ; 数据缓冲区
    mov cx, 0x0002        ; 磁道0，扇区2
    mov dx, 0x0000         ; 磁头0，驱动器SA
    int 0x13               ; 调用 BIOS 中断读取扇区
    mov si, 0x0500    ; 将读取的数据放到 SI
    ret

write_msg:
    db "test floppy", 0

;read_buffer times 100 db 0   ; 缓冲区大小为1个扇区
msg:
    db "Booting...", 0

times 510 - ($ - $$) db 0
db 0x55, 0xaa
