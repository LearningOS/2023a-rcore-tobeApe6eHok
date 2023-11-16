.altmacro
.macro SAVE_GP n
    sd x\n, \n*8(sp)
.endm
.macro LOAD_GP n
    ld x\n, \n*8(sp)
.endm
    .section .text
    .globl __alltraps
    .globl __restore
    .align 2
__alltraps:
    # 除了在内核初始化之后开始运行是从__switch进入的,其余情况全部都是从__alltraps中进入到内核的

    # 在内核态S的时候需要保证KernelStack已经被压入了一个trap_context,
    # 所以在内核初始化的时候需要在init_app_cx函数中压入

    # 每一个任务都是从__switch开始执行,就保证了从__switch中跳转到__restore的时候,sp指向kernel_stack(分配了trap_context的地址),
    # 并且trap_context中存储的是用户栈,因此就保证了__restore中把sscratch寄存器和sp进行交换后,分别是内核栈指针和用户栈指针,
    # 之后就执行用户态代码,
    # 而__alltraps必定是在__restore之后从用户态trap进来的,
    # 所以这里也就保证了sscratch和sp分别指向的是内核栈指针和用户栈指针
    csrrw sp, sscratch, sp
    # now sp->kernel stack, sscratch->user stack
    # allocate a TrapContext on kernel stack
    addi sp, sp, -34*8
    # save general-purpose registers
    sd x1, 1*8(sp)
    # skip sp(x2), we will save it later
    sd x3, 3*8(sp)
    # skip tp(x4), application does not use it
    # save x5~x31
    .set n, 5
    .rept 27
        SAVE_GP %n
        .set n, n+1
    .endr
    # we can use t0/t1/t2 freely, because they were saved on kernel stack
    csrr t0, sstatus
    csrr t1, sepc
    sd t0, 32*8(sp)
    sd t1, 33*8(sp)
    # read user stack from sscratch and save it on the kernel stack
    csrr t2, sscratch
    sd t2, 2*8(sp)
    # set input argument of trap_handler(cx: &mut TrapContext)
    mv a0, sp
    call trap_handler
    # trap_handler返回之后继续执行下面的指令,即跳转到了__restore

__restore:
    # 有两种跳转到__restore的情况
    # 1.__alltraps调用完trap_handler继续执行到__restore
    # 2.从__switch执行完通过ra寄存器跳转到__restore
    #   在系统初始化的时候从__switch执行到__restore时:sp指向的是kernel_stack,这时的kernel_stack已经在init_app_cx压入了一个trap_context,sp也是压入后的地址
    #       sp指向的trap_context中sepc指向app的第一条指令,并且保存了用户栈
    # now sp->kernel stack(after allocated), sscratch->user stack
    # restore sstatus/sepc
    ld t0, 32*8(sp)
    ld t1, 33*8(sp)
    ld t2, 2*8(sp)
    # 把t0、t1、t2寄存器中的值写入sstatus、sepc、sscratch,因此sscratch指向的就是用户栈
    csrw sstatus, t0
    csrw sepc, t1
    csrw sscratch, t2
    # restore general-purpuse registers except sp/tp
    ld x1, 1*8(sp)
    ld x3, 3*8(sp)
    .set n, 5
    .rept 27
        LOAD_GP %n
        .set n, n+1
    .endr
    # release TrapContext on kernel stack
    addi sp, sp, 34*8
    # now sp->kernel stack, sscratch->user stack
    csrrw sp, sscratch, sp
    sret
