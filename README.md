# zsh-os


***

# 如何利用汇编读写软盘

在计算机系统中，软盘是最早的外部存储设备之一。虽然现在已经很少使用，但在操作系统开发、低级存储器控制等领域，学习如何利用汇编读写软盘仍然是一个很好的练习。本文将介绍如何使用 x86 汇编语言编写程序，从软盘中读取数据并将数据写入软盘。

## 1. 基础知识

### 1.1 CHS 与 LBA

*   **CHS（Cylinder, Head, Sector）**：柱面-磁头-扇区，是早期磁盘的寻址方式。通过柱面号（Cylinder）、磁头号（Head）和扇区号（Sector）来定位磁盘上的位置。
*   **LBA（Logical Block Addressing）**：逻辑块寻址，将整个磁盘视为一个连续的块序列，从0开始。

### 1.2 BIOS 中断 0x13

BIOS 提供了一组用于磁盘操作的中断服务，0x13 中断是其中最常用的一个，用于磁盘的读写操作。

*   **`int 0x13`**：调用磁盘服务。
    *   `AH = 0x02`：读取扇区。
    *   `AH = 0x03`：写入扇区。

### 1.3 实模式与16位代码

在启动阶段，CPU 处于实模式，所有操作都在 16 位下进行。使用 `BITS 16` 指令来指示汇编器生成16位代码。

## 2. 汇编代码

以下是一个完整的汇编代码示例，该代码用于从软盘读取数据并将其显示在屏幕上。你还可以使用该代码将字符串写入软盘。

```asm
[ORG  0x7c00]
[SECTION .text]
[BITS 16]
global _start

_start:
    xchg    bx, bx           ; 方便调试的无操作指令
    ; 设置屏幕模式为文本模式，清除屏幕
    mov ax, 3
    int 0x10

    ; 初始化段寄存器
    mov ax, 0
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov si, ax

    ; 打印启动消息
    mov si, msg
    call print

	; 将字符串 "test floppy" 写入软盘第二扇区
    ;mov si, write_msg
    ;call write_floppy

    ; 读取软盘第二扇区并显示
    call read_floppy
    call print

    jmp     $     ; 死循环，防止程序退出

; 打印字符串函数
print:
    mov ah, 0x0e              ; 使用 BIOS 中断 0x10，功能号 0x0E 打印字符
    mov bh, 0
    mov bl, 0x01
.loop:
    mov al, [si]              ; 加载字符串中的下一个字符到 AL
    cmp al, 0                 ; 判断是否到达字符串末尾
    jz .done
    int 0x10                  ; 调用 BIOS 中断打印字符

    inc si                    ; 移动到下一个字符
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
    mov ax, 0x0201            ; 功能号：读取扇区，1 扇区
    mov bx, 0x0500            ; 数据缓冲区地址，0x0500
    mov cx, 0x0002            ; 磁道0，扇区2
    mov dx, 0x0000            ; 磁头0，驱动器A
    int 0x13                  ; 调用 BIOS 中断读取扇区
    mov si, 0x0500            ; 设置 SI 指向读取的数据
    ret

write_msg:
    db "test floppy", 0
msg:
    db "Booting...", 0        ; 启动消息

times 510 - ($ - $$) db 0      ; 填充至 510 字节
db 0x55, 0xaa                  ; 引导扇区签名
```

## 3. 使用 Makefile 构建和运行

我们可以使用 Makefile 来自动化汇编程序的编译、软盘镜像的创建以及将程序加载到软盘中。以下是相应的 Makefile 示例：

```makefile
BUILD := ./build
FLOPPY_IMG_NAME = floppy.img

all: ${BUILD}/boot/boot.o
	$(shell rm -rf $(FLOPPY_IMG_NAME))
	bximage -q -fd=1.44M -func=create $(FLOPPY_IMG_NAME)
	dd if=${BUILD}/boot/boot.o of=$(FLOPPY_IMG_NAME) bs=512 seek=0 count=1 conv=notrunc
	echo -n "Hello, Floppy!" | dd of=$(FLOPPY_IMG_NAME) bs=512 seek=1 count=1 conv=notrunc

${BUILD}/boot/%.o: %.asm
	$(shell mkdir -p ${BUILD}/boot)
	nasm $< -o $@

clean:
	$(shell rm -rf ${BUILD})

bochs: all
	bochs -q -f bochsrc

qemu: all
	qemu-system-x86_64 -hda hd.img

qemus: all
	qemu-system-x86_64 -fda floppy.img
```

### 3.1 关键步骤解析

*   **编译汇编代码**：将 `boot.asm` 编译为 `boot.o`，并写入软盘镜像的第一个扇区。
*   **写入数据**：通过 `dd` 命令，将字符串 `Hello, Floppy!` 写入软盘的第二个扇区（`seek=1`）。
*   **启动虚拟机**：可以使用 `bochs` 或 `qemu` 来测试生成的软盘镜像。

## 4. 运行与验证

在成功编译并生成软盘镜像后，您可以使用以下命令来启动虚拟机并测试软盘镜像：

```bash
make bochs   # 使用 Bochs 运行
make qemu    # 使用 QEMU 运行
```

观察输出，如果一切设置正确，你应该能看到屏幕上显示 `"Booting...Hello, Floppy!"`。

## 5. 常见问题与调试

### 5.1 读取不到数据

*   确保写入数据的扇区和读取数据的扇区匹配。如果写入到第 2 扇区，读取时应该设置 `cx = 0x0003`（CHS 中扇区编号从1开始）。

### 5.2 程序运行异常

*   检查段寄存器的初始化，确保所有寄存器指向正确的内存区域。
*   使用 `xchg bx, bx` 或其他无操作指令帮助调试。

### 5.3 程序大小超出 512 字节

*   检查代码段和数据段大小，避免在引导扇区中静态定义过大的数据。

## 6. 总结

通过以上步骤，您已经掌握了如何使用汇编语言来读写软盘，并能够通过虚拟机（如 Bochs 或 QEMU）进行测试。希望这篇指南能帮助您深入理解软盘的低级操作，并为后续的操作系统开发打下坚实的基础。

***


