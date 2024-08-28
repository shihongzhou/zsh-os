[ORG  0x7c00]

[SECTION .text]
[BITS 16]
global _start
_start:
    ;使用 BIOS 中断 0x13 读取软盘
     mov ah, 0x02             ; 功能号：读取扇区
     mov al, 1                ; 扇区数量：1
     mov ch, 0                ; 磁头号：0
     mov cl, 2                ; 扇区号：2（读取第一个扇区）
     mov dh, 0                ; 磁头号：0
     mov dl, 0                ; 驱动器号：软盘A = 0
     mov bx, 0x0000           ; ES:BX 指向缓冲区，缓冲区地址是 0x0000:0x7C00
     int 0x13                 ; 调用 BIOS 中断读取扇区

     jc read_error            ; 如果 CF 标志设置，跳转到错误处理

     ; 读取成功，打印成功消息
     mov si, success_msg      ; 加载字符串地址到 SI
     call print_string        ; 调用打印字符串函数

     ; 继续执行（例如跳转到加载的引导扇区代码）
     jmp 0x7C00               ; 跳转到加载的引导扇区代码

 read_error:
     ; 错误处理代码，可以闪烁光标或循环等待重试
     mov si, error_msg        ; 加载错误消息字符串地址到 SI
     call print_string        ; 调用打印字符串函数
     hlt                      ; 暂停 CPU

 print_string:
     ; 打印字符串函数
     mov ah, 0x0E             ; BIOS 中断 10h, 功能代码 0Eh, 显示字符
 .next_char:
     lodsb                    ; 加载字符串中的下一个字符到 AL
     cmp al, 0                ; 判断是否到达字符串末尾
     je .done_print
     int 0x10                 ; 显示字符
     jmp .next_char
 .done_print:
     ret

 success_msg db 'Read successful!', 0 ; 成功消息字符串，以 0 结尾
 error_msg db 'Read error!', 0         ; 错误消息字符串，以 0 结尾

times 510 - ($ - $$) db 0
db 0x55, 0xaa           ; 引导扇区结束标志
