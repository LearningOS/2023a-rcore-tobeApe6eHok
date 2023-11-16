# lab1

## 编程作业

我通过在任务的TaskContorlBlock中加入一个字段保存任务的TaskInfo来实现，实现很简单，为TASK_MANAGER实现两个pub的函数：task_manager_syscall_inc和task_manager_get_current_task_info，分别用来为当前任务的TaskInfo对应的syscall id号加1和获取当前任务的TaskInfo的指针（unsafe）。

通过上述实现，sys_task_info的实现也就变的格外简单，只需要调用task_manager_get_current_task_info获得内核中TaskInfo地址，然后赋值给用户态的TaskInfo即可（为TaskInfo实现了Copy），然后调用get_time_ms获得time字段即可。

## 简答作业

1.略

2.1 

有两种情况进入__restore分别是__alltraps顺序执行和从__switch通过ra寄存器跳转到__restore，第一种情况下a0的值是内核栈顶指针，第二种情况下a0是调用__switch是的current_task_cx_ptr指针，这个指针没有用了，所以在__restore中使用内核栈中的trap_context保存的a0覆盖。

2.2

特殊处理了sstatus、sepc、sscratch三个寄存器，把sstatus设置为USER、sepc设置为app下一条指令的地址、sscratch设置为用户栈指针，这样进入用户态之后就可以正常执行用户态代码，由于函数后面交换了sscratch和sp的值，所以在用户态再次遇到trap的时候也会保证__alltraps中sscratch中指向的是内核栈指针。

2.3

跳过x4是因为这个寄存器用户到，不需要保存和加载；跳过x2是因为已经把2*8(sp)放到了sscratch中，后面只需要交换sp和sscratch的值就可转换为用户栈栈顶指针。

2.4

sp是用户栈栈顶指针，sscratch是内核栈栈顶指针

2.5

sret发生了状态切换，执行该指令，CPU 会将当前的特权级按照 sstatus 的 SPP 字段设置为 U 或者 S ，会跳转到 sepc 寄存器指向的那条指令，然后继续执行。

2.6

sp指向内核栈栈顶，sscratch指向用户栈栈顶

2.7

是从用户态进行系统调用的时候引起的：

当 CPU 执行完一条指令并准备从用户特权级 陷入（ Trap ）到 S 特权级的时候，硬件会自动完成如下这些事情：

sstatus 的 SPP 字段会被修改为 CPU 当前的特权级（U/S）。

sepc 会被修改为 Trap 处理完成后默认会执行的下一条指令的地址。

scause/stval 分别会被修改成这次 Trap 的原因以及相关的附加信息。

CPU 会跳转到 stvec 所设置的 Trap 处理入口地址，并将当前特权级设置为 S ，然后从Trap 处理入口地址处开始执行。


## 荣誉准则
1. 在完成本次实验的过程（含此前学习的过程）中，我曾分别与 以下各位 就（与本次实验相关的）以下方面做过交流，还在代码中对应的位置以注释形式记录了具体的交流对象及内容：

无

2. 此外，我也参考了 以下资料 ，还在代码中对应的位置以注释形式记录了具体的参考来源及内容：

无

3. 我独立完成了本次实验除以上方面之外的所有工作，包括代码与文档。 我清楚地知道，从以上方面获得的信息在一定程度上降低了实验难度，可能会影响起评分。

4. 我从未使用过他人的代码，不管是原封不动地复制，还是经过了某些等价转换。 我未曾也不会向他人（含此后各届同学）复制或公开我的实验代码，我有义务妥善保管好它们。 我提交至本实验的评测系统的代码，均无意于破坏或妨碍任何计算机系统的正常运转。 我清楚地知道，以上情况均为本课程纪律所禁止，若违反，对应的实验成绩将按“-100”分计。