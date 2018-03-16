
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 f0 11 00       	mov    $0x11f000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 f0 11 f0       	mov    $0xf011f000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5c 00 00 00       	call   f010009a <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	56                   	push   %esi
f0100044:	53                   	push   %ebx
f0100045:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100048:	83 3d 80 ce 22 f0 00 	cmpl   $0x0,0xf022ce80
f010004f:	75 3a                	jne    f010008b <_panic+0x4b>
		goto dead;
	panicstr = fmt;
f0100051:	89 35 80 ce 22 f0    	mov    %esi,0xf022ce80

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f0100057:	fa                   	cli    
f0100058:	fc                   	cld    

	va_start(ap, fmt);
f0100059:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005c:	e8 e1 5e 00 00       	call   f0105f42 <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 e0 65 10 f0       	push   $0xf01065e0
f010006d:	e8 e8 35 00 00       	call   f010365a <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 b8 35 00 00       	call   f0103634 <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 bf 6b 10 f0 	movl   $0xf0106bbf,(%esp)
f0100083:	e8 d2 35 00 00       	call   f010365a <cprintf>
	va_end(ap);
f0100088:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010008b:	83 ec 0c             	sub    $0xc,%esp
f010008e:	6a 00                	push   $0x0
f0100090:	e8 68 08 00 00       	call   f01008fd <monitor>
f0100095:	83 c4 10             	add    $0x10,%esp
f0100098:	eb f1                	jmp    f010008b <_panic+0x4b>

f010009a <i386_init>:
static void boot_aps(void);


void
i386_init(void)
{
f010009a:	55                   	push   %ebp
f010009b:	89 e5                	mov    %esp,%ebp
f010009d:	53                   	push   %ebx
f010009e:	83 ec 08             	sub    $0x8,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a1:	b8 08 e0 26 f0       	mov    $0xf026e008,%eax
f01000a6:	2d d8 b9 22 f0       	sub    $0xf022b9d8,%eax
f01000ab:	50                   	push   %eax
f01000ac:	6a 00                	push   $0x0
f01000ae:	68 d8 b9 22 f0       	push   $0xf022b9d8
f01000b3:	e8 68 58 00 00       	call   f0105920 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 82 05 00 00       	call   f010063f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 4c 66 10 f0       	push   $0xf010664c
f01000ca:	e8 8b 35 00 00       	call   f010365a <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 c4 11 00 00       	call   f0101298 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 db 2d 00 00       	call   f0102eb4 <env_init>
	trap_init();
f01000d9:	e8 47 36 00 00       	call   f0103725 <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 55 5b 00 00       	call   f0105c38 <mp_init>
	lapic_init();
f01000e3:	e8 75 5e 00 00       	call   f0105f5d <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 94 34 00 00       	call   f0103581 <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000ed:	c7 04 24 c0 17 12 f0 	movl   $0xf01217c0,(%esp)
f01000f4:	e8 b7 60 00 00       	call   f01061b0 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01000f9:	83 c4 10             	add    $0x10,%esp
f01000fc:	83 3d 88 ce 22 f0 07 	cmpl   $0x7,0xf022ce88
f0100103:	77 16                	ja     f010011b <i386_init+0x81>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100105:	68 00 70 00 00       	push   $0x7000
f010010a:	68 04 66 10 f0       	push   $0xf0106604
f010010f:	6a 57                	push   $0x57
f0100111:	68 67 66 10 f0       	push   $0xf0106667
f0100116:	e8 25 ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f010011b:	83 ec 04             	sub    $0x4,%esp
f010011e:	b8 9e 5b 10 f0       	mov    $0xf0105b9e,%eax
f0100123:	2d 24 5b 10 f0       	sub    $0xf0105b24,%eax
f0100128:	50                   	push   %eax
f0100129:	68 24 5b 10 f0       	push   $0xf0105b24
f010012e:	68 00 70 00 f0       	push   $0xf0007000
f0100133:	e8 35 58 00 00       	call   f010596d <memmove>
f0100138:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010013b:	bb 20 d0 22 f0       	mov    $0xf022d020,%ebx
f0100140:	eb 4d                	jmp    f010018f <i386_init+0xf5>
		if (c == cpus + cpunum())  // We've started already.
f0100142:	e8 fb 5d 00 00       	call   f0105f42 <cpunum>
f0100147:	6b c0 74             	imul   $0x74,%eax,%eax
f010014a:	05 20 d0 22 f0       	add    $0xf022d020,%eax
f010014f:	39 c3                	cmp    %eax,%ebx
f0100151:	74 39                	je     f010018c <i386_init+0xf2>
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100153:	89 d8                	mov    %ebx,%eax
f0100155:	2d 20 d0 22 f0       	sub    $0xf022d020,%eax
f010015a:	c1 f8 02             	sar    $0x2,%eax
f010015d:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100163:	c1 e0 0f             	shl    $0xf,%eax
f0100166:	05 00 60 23 f0       	add    $0xf0236000,%eax
f010016b:	a3 84 ce 22 f0       	mov    %eax,0xf022ce84
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f0100170:	83 ec 08             	sub    $0x8,%esp
f0100173:	68 00 70 00 00       	push   $0x7000
f0100178:	0f b6 03             	movzbl (%ebx),%eax
f010017b:	50                   	push   %eax
f010017c:	e8 2a 5f 00 00       	call   f01060ab <lapic_startap>
f0100181:	83 c4 10             	add    $0x10,%esp
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
f0100184:	8b 43 04             	mov    0x4(%ebx),%eax
f0100187:	83 f8 01             	cmp    $0x1,%eax
f010018a:	75 f8                	jne    f0100184 <i386_init+0xea>
	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010018c:	83 c3 74             	add    $0x74,%ebx
f010018f:	6b 05 c4 d3 22 f0 74 	imul   $0x74,0xf022d3c4,%eax
f0100196:	05 20 d0 22 f0       	add    $0xf022d020,%eax
f010019b:	39 c3                	cmp    %eax,%ebx
f010019d:	72 a3                	jb     f0100142 <i386_init+0xa8>
	// Starting non-boot CPUs
	boot_aps();

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f010019f:	83 ec 08             	sub    $0x8,%esp
f01001a2:	6a 00                	push   $0x0
f01001a4:	68 08 30 22 f0       	push   $0xf0223008
f01001a9:	e8 d3 2e 00 00       	call   f0103081 <env_create>
	ENV_CREATE(user_yield, ENV_TYPE_USER);
	ENV_CREATE(user_yield, ENV_TYPE_USER);	
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001ae:	e8 82 47 00 00       	call   f0104935 <sched_yield>

f01001b3 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f01001b3:	55                   	push   %ebp
f01001b4:	89 e5                	mov    %esp,%ebp
f01001b6:	83 ec 08             	sub    $0x8,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f01001b9:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001be:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001c3:	77 12                	ja     f01001d7 <mp_main+0x24>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001c5:	50                   	push   %eax
f01001c6:	68 28 66 10 f0       	push   $0xf0106628
f01001cb:	6a 6e                	push   $0x6e
f01001cd:	68 67 66 10 f0       	push   $0xf0106667
f01001d2:	e8 69 fe ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01001d7:	05 00 00 00 10       	add    $0x10000000,%eax
f01001dc:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001df:	e8 5e 5d 00 00       	call   f0105f42 <cpunum>
f01001e4:	83 ec 08             	sub    $0x8,%esp
f01001e7:	50                   	push   %eax
f01001e8:	68 73 66 10 f0       	push   $0xf0106673
f01001ed:	e8 68 34 00 00       	call   f010365a <cprintf>

	lapic_init();
f01001f2:	e8 66 5d 00 00       	call   f0105f5d <lapic_init>
	env_init_percpu();
f01001f7:	e8 88 2c 00 00       	call   f0102e84 <env_init_percpu>
	trap_init_percpu();
f01001fc:	e8 6d 34 00 00       	call   f010366e <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100201:	e8 3c 5d 00 00       	call   f0105f42 <cpunum>
f0100206:	6b d0 74             	imul   $0x74,%eax,%edx
f0100209:	81 c2 20 d0 22 f0    	add    $0xf022d020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f010020f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100214:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0100218:	c7 04 24 c0 17 12 f0 	movl   $0xf01217c0,(%esp)
f010021f:	e8 8c 5f 00 00       	call   f01061b0 <spin_lock>
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:
	lock_kernel();
	
	sched_yield();
f0100224:	e8 0c 47 00 00       	call   f0104935 <sched_yield>

f0100229 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100229:	55                   	push   %ebp
f010022a:	89 e5                	mov    %esp,%ebp
f010022c:	53                   	push   %ebx
f010022d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100230:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100233:	ff 75 0c             	pushl  0xc(%ebp)
f0100236:	ff 75 08             	pushl  0x8(%ebp)
f0100239:	68 89 66 10 f0       	push   $0xf0106689
f010023e:	e8 17 34 00 00       	call   f010365a <cprintf>
	vcprintf(fmt, ap);
f0100243:	83 c4 08             	add    $0x8,%esp
f0100246:	53                   	push   %ebx
f0100247:	ff 75 10             	pushl  0x10(%ebp)
f010024a:	e8 e5 33 00 00       	call   f0103634 <vcprintf>
	cprintf("\n");
f010024f:	c7 04 24 bf 6b 10 f0 	movl   $0xf0106bbf,(%esp)
f0100256:	e8 ff 33 00 00       	call   f010365a <cprintf>
	va_end(ap);
}
f010025b:	83 c4 10             	add    $0x10,%esp
f010025e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100261:	c9                   	leave  
f0100262:	c3                   	ret    

f0100263 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100263:	55                   	push   %ebp
f0100264:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100266:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010026b:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010026c:	a8 01                	test   $0x1,%al
f010026e:	74 0b                	je     f010027b <serial_proc_data+0x18>
f0100270:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100275:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100276:	0f b6 c0             	movzbl %al,%eax
f0100279:	eb 05                	jmp    f0100280 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010027b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100280:	5d                   	pop    %ebp
f0100281:	c3                   	ret    

f0100282 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100282:	55                   	push   %ebp
f0100283:	89 e5                	mov    %esp,%ebp
f0100285:	53                   	push   %ebx
f0100286:	83 ec 04             	sub    $0x4,%esp
f0100289:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010028b:	eb 2b                	jmp    f01002b8 <cons_intr+0x36>
		if (c == 0)
f010028d:	85 c0                	test   %eax,%eax
f010028f:	74 27                	je     f01002b8 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f0100291:	8b 0d 24 c2 22 f0    	mov    0xf022c224,%ecx
f0100297:	8d 51 01             	lea    0x1(%ecx),%edx
f010029a:	89 15 24 c2 22 f0    	mov    %edx,0xf022c224
f01002a0:	88 81 20 c0 22 f0    	mov    %al,-0xfdd3fe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01002a6:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01002ac:	75 0a                	jne    f01002b8 <cons_intr+0x36>
			cons.wpos = 0;
f01002ae:	c7 05 24 c2 22 f0 00 	movl   $0x0,0xf022c224
f01002b5:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01002b8:	ff d3                	call   *%ebx
f01002ba:	83 f8 ff             	cmp    $0xffffffff,%eax
f01002bd:	75 ce                	jne    f010028d <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01002bf:	83 c4 04             	add    $0x4,%esp
f01002c2:	5b                   	pop    %ebx
f01002c3:	5d                   	pop    %ebp
f01002c4:	c3                   	ret    

f01002c5 <kbd_proc_data>:
f01002c5:	ba 64 00 00 00       	mov    $0x64,%edx
f01002ca:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01002cb:	a8 01                	test   $0x1,%al
f01002cd:	0f 84 f8 00 00 00    	je     f01003cb <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01002d3:	a8 20                	test   $0x20,%al
f01002d5:	0f 85 f6 00 00 00    	jne    f01003d1 <kbd_proc_data+0x10c>
f01002db:	ba 60 00 00 00       	mov    $0x60,%edx
f01002e0:	ec                   	in     (%dx),%al
f01002e1:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01002e3:	3c e0                	cmp    $0xe0,%al
f01002e5:	75 0d                	jne    f01002f4 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01002e7:	83 0d 00 c0 22 f0 40 	orl    $0x40,0xf022c000
		return 0;
f01002ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01002f3:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01002f4:	55                   	push   %ebp
f01002f5:	89 e5                	mov    %esp,%ebp
f01002f7:	53                   	push   %ebx
f01002f8:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01002fb:	84 c0                	test   %al,%al
f01002fd:	79 36                	jns    f0100335 <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01002ff:	8b 0d 00 c0 22 f0    	mov    0xf022c000,%ecx
f0100305:	89 cb                	mov    %ecx,%ebx
f0100307:	83 e3 40             	and    $0x40,%ebx
f010030a:	83 e0 7f             	and    $0x7f,%eax
f010030d:	85 db                	test   %ebx,%ebx
f010030f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100312:	0f b6 d2             	movzbl %dl,%edx
f0100315:	0f b6 82 00 68 10 f0 	movzbl -0xfef9800(%edx),%eax
f010031c:	83 c8 40             	or     $0x40,%eax
f010031f:	0f b6 c0             	movzbl %al,%eax
f0100322:	f7 d0                	not    %eax
f0100324:	21 c8                	and    %ecx,%eax
f0100326:	a3 00 c0 22 f0       	mov    %eax,0xf022c000
		return 0;
f010032b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100330:	e9 a4 00 00 00       	jmp    f01003d9 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100335:	8b 0d 00 c0 22 f0    	mov    0xf022c000,%ecx
f010033b:	f6 c1 40             	test   $0x40,%cl
f010033e:	74 0e                	je     f010034e <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100340:	83 c8 80             	or     $0xffffff80,%eax
f0100343:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100345:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100348:	89 0d 00 c0 22 f0    	mov    %ecx,0xf022c000
	}

	shift |= shiftcode[data];
f010034e:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100351:	0f b6 82 00 68 10 f0 	movzbl -0xfef9800(%edx),%eax
f0100358:	0b 05 00 c0 22 f0    	or     0xf022c000,%eax
f010035e:	0f b6 8a 00 67 10 f0 	movzbl -0xfef9900(%edx),%ecx
f0100365:	31 c8                	xor    %ecx,%eax
f0100367:	a3 00 c0 22 f0       	mov    %eax,0xf022c000

	c = charcode[shift & (CTL | SHIFT)][data];
f010036c:	89 c1                	mov    %eax,%ecx
f010036e:	83 e1 03             	and    $0x3,%ecx
f0100371:	8b 0c 8d e0 66 10 f0 	mov    -0xfef9920(,%ecx,4),%ecx
f0100378:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010037c:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010037f:	a8 08                	test   $0x8,%al
f0100381:	74 1b                	je     f010039e <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f0100383:	89 da                	mov    %ebx,%edx
f0100385:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100388:	83 f9 19             	cmp    $0x19,%ecx
f010038b:	77 05                	ja     f0100392 <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f010038d:	83 eb 20             	sub    $0x20,%ebx
f0100390:	eb 0c                	jmp    f010039e <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f0100392:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100395:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100398:	83 fa 19             	cmp    $0x19,%edx
f010039b:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010039e:	f7 d0                	not    %eax
f01003a0:	a8 06                	test   $0x6,%al
f01003a2:	75 33                	jne    f01003d7 <kbd_proc_data+0x112>
f01003a4:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01003aa:	75 2b                	jne    f01003d7 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f01003ac:	83 ec 0c             	sub    $0xc,%esp
f01003af:	68 a3 66 10 f0       	push   $0xf01066a3
f01003b4:	e8 a1 32 00 00       	call   f010365a <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003b9:	ba 92 00 00 00       	mov    $0x92,%edx
f01003be:	b8 03 00 00 00       	mov    $0x3,%eax
f01003c3:	ee                   	out    %al,(%dx)
f01003c4:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003c7:	89 d8                	mov    %ebx,%eax
f01003c9:	eb 0e                	jmp    f01003d9 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01003cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01003d0:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01003d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01003d6:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003d7:	89 d8                	mov    %ebx,%eax
}
f01003d9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01003dc:	c9                   	leave  
f01003dd:	c3                   	ret    

f01003de <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01003de:	55                   	push   %ebp
f01003df:	89 e5                	mov    %esp,%ebp
f01003e1:	57                   	push   %edi
f01003e2:	56                   	push   %esi
f01003e3:	53                   	push   %ebx
f01003e4:	83 ec 1c             	sub    $0x1c,%esp
f01003e7:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01003e9:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003ee:	be fd 03 00 00       	mov    $0x3fd,%esi
f01003f3:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003f8:	eb 09                	jmp    f0100403 <cons_putc+0x25>
f01003fa:	89 ca                	mov    %ecx,%edx
f01003fc:	ec                   	in     (%dx),%al
f01003fd:	ec                   	in     (%dx),%al
f01003fe:	ec                   	in     (%dx),%al
f01003ff:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100400:	83 c3 01             	add    $0x1,%ebx
f0100403:	89 f2                	mov    %esi,%edx
f0100405:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100406:	a8 20                	test   $0x20,%al
f0100408:	75 08                	jne    f0100412 <cons_putc+0x34>
f010040a:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100410:	7e e8                	jle    f01003fa <cons_putc+0x1c>
f0100412:	89 f8                	mov    %edi,%eax
f0100414:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100417:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010041c:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010041d:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100422:	be 79 03 00 00       	mov    $0x379,%esi
f0100427:	b9 84 00 00 00       	mov    $0x84,%ecx
f010042c:	eb 09                	jmp    f0100437 <cons_putc+0x59>
f010042e:	89 ca                	mov    %ecx,%edx
f0100430:	ec                   	in     (%dx),%al
f0100431:	ec                   	in     (%dx),%al
f0100432:	ec                   	in     (%dx),%al
f0100433:	ec                   	in     (%dx),%al
f0100434:	83 c3 01             	add    $0x1,%ebx
f0100437:	89 f2                	mov    %esi,%edx
f0100439:	ec                   	in     (%dx),%al
f010043a:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100440:	7f 04                	jg     f0100446 <cons_putc+0x68>
f0100442:	84 c0                	test   %al,%al
f0100444:	79 e8                	jns    f010042e <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100446:	ba 78 03 00 00       	mov    $0x378,%edx
f010044b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010044f:	ee                   	out    %al,(%dx)
f0100450:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100455:	b8 0d 00 00 00       	mov    $0xd,%eax
f010045a:	ee                   	out    %al,(%dx)
f010045b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100460:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100461:	89 fa                	mov    %edi,%edx
f0100463:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100469:	89 f8                	mov    %edi,%eax
f010046b:	80 cc 07             	or     $0x7,%ah
f010046e:	85 d2                	test   %edx,%edx
f0100470:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100473:	89 f8                	mov    %edi,%eax
f0100475:	0f b6 c0             	movzbl %al,%eax
f0100478:	83 f8 09             	cmp    $0x9,%eax
f010047b:	74 74                	je     f01004f1 <cons_putc+0x113>
f010047d:	83 f8 09             	cmp    $0x9,%eax
f0100480:	7f 0a                	jg     f010048c <cons_putc+0xae>
f0100482:	83 f8 08             	cmp    $0x8,%eax
f0100485:	74 14                	je     f010049b <cons_putc+0xbd>
f0100487:	e9 99 00 00 00       	jmp    f0100525 <cons_putc+0x147>
f010048c:	83 f8 0a             	cmp    $0xa,%eax
f010048f:	74 3a                	je     f01004cb <cons_putc+0xed>
f0100491:	83 f8 0d             	cmp    $0xd,%eax
f0100494:	74 3d                	je     f01004d3 <cons_putc+0xf5>
f0100496:	e9 8a 00 00 00       	jmp    f0100525 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f010049b:	0f b7 05 28 c2 22 f0 	movzwl 0xf022c228,%eax
f01004a2:	66 85 c0             	test   %ax,%ax
f01004a5:	0f 84 e6 00 00 00    	je     f0100591 <cons_putc+0x1b3>
			crt_pos--;
f01004ab:	83 e8 01             	sub    $0x1,%eax
f01004ae:	66 a3 28 c2 22 f0    	mov    %ax,0xf022c228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004b4:	0f b7 c0             	movzwl %ax,%eax
f01004b7:	66 81 e7 00 ff       	and    $0xff00,%di
f01004bc:	83 cf 20             	or     $0x20,%edi
f01004bf:	8b 15 2c c2 22 f0    	mov    0xf022c22c,%edx
f01004c5:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004c9:	eb 78                	jmp    f0100543 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004cb:	66 83 05 28 c2 22 f0 	addw   $0x50,0xf022c228
f01004d2:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004d3:	0f b7 05 28 c2 22 f0 	movzwl 0xf022c228,%eax
f01004da:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004e0:	c1 e8 16             	shr    $0x16,%eax
f01004e3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004e6:	c1 e0 04             	shl    $0x4,%eax
f01004e9:	66 a3 28 c2 22 f0    	mov    %ax,0xf022c228
f01004ef:	eb 52                	jmp    f0100543 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01004f1:	b8 20 00 00 00       	mov    $0x20,%eax
f01004f6:	e8 e3 fe ff ff       	call   f01003de <cons_putc>
		cons_putc(' ');
f01004fb:	b8 20 00 00 00       	mov    $0x20,%eax
f0100500:	e8 d9 fe ff ff       	call   f01003de <cons_putc>
		cons_putc(' ');
f0100505:	b8 20 00 00 00       	mov    $0x20,%eax
f010050a:	e8 cf fe ff ff       	call   f01003de <cons_putc>
		cons_putc(' ');
f010050f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100514:	e8 c5 fe ff ff       	call   f01003de <cons_putc>
		cons_putc(' ');
f0100519:	b8 20 00 00 00       	mov    $0x20,%eax
f010051e:	e8 bb fe ff ff       	call   f01003de <cons_putc>
f0100523:	eb 1e                	jmp    f0100543 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100525:	0f b7 05 28 c2 22 f0 	movzwl 0xf022c228,%eax
f010052c:	8d 50 01             	lea    0x1(%eax),%edx
f010052f:	66 89 15 28 c2 22 f0 	mov    %dx,0xf022c228
f0100536:	0f b7 c0             	movzwl %ax,%eax
f0100539:	8b 15 2c c2 22 f0    	mov    0xf022c22c,%edx
f010053f:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100543:	66 81 3d 28 c2 22 f0 	cmpw   $0x7cf,0xf022c228
f010054a:	cf 07 
f010054c:	76 43                	jbe    f0100591 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010054e:	a1 2c c2 22 f0       	mov    0xf022c22c,%eax
f0100553:	83 ec 04             	sub    $0x4,%esp
f0100556:	68 00 0f 00 00       	push   $0xf00
f010055b:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100561:	52                   	push   %edx
f0100562:	50                   	push   %eax
f0100563:	e8 05 54 00 00       	call   f010596d <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100568:	8b 15 2c c2 22 f0    	mov    0xf022c22c,%edx
f010056e:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100574:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010057a:	83 c4 10             	add    $0x10,%esp
f010057d:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100582:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100585:	39 d0                	cmp    %edx,%eax
f0100587:	75 f4                	jne    f010057d <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100589:	66 83 2d 28 c2 22 f0 	subw   $0x50,0xf022c228
f0100590:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100591:	8b 0d 30 c2 22 f0    	mov    0xf022c230,%ecx
f0100597:	b8 0e 00 00 00       	mov    $0xe,%eax
f010059c:	89 ca                	mov    %ecx,%edx
f010059e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010059f:	0f b7 1d 28 c2 22 f0 	movzwl 0xf022c228,%ebx
f01005a6:	8d 71 01             	lea    0x1(%ecx),%esi
f01005a9:	89 d8                	mov    %ebx,%eax
f01005ab:	66 c1 e8 08          	shr    $0x8,%ax
f01005af:	89 f2                	mov    %esi,%edx
f01005b1:	ee                   	out    %al,(%dx)
f01005b2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005b7:	89 ca                	mov    %ecx,%edx
f01005b9:	ee                   	out    %al,(%dx)
f01005ba:	89 d8                	mov    %ebx,%eax
f01005bc:	89 f2                	mov    %esi,%edx
f01005be:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01005bf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005c2:	5b                   	pop    %ebx
f01005c3:	5e                   	pop    %esi
f01005c4:	5f                   	pop    %edi
f01005c5:	5d                   	pop    %ebp
f01005c6:	c3                   	ret    

f01005c7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01005c7:	80 3d 34 c2 22 f0 00 	cmpb   $0x0,0xf022c234
f01005ce:	74 11                	je     f01005e1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01005d0:	55                   	push   %ebp
f01005d1:	89 e5                	mov    %esp,%ebp
f01005d3:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01005d6:	b8 63 02 10 f0       	mov    $0xf0100263,%eax
f01005db:	e8 a2 fc ff ff       	call   f0100282 <cons_intr>
}
f01005e0:	c9                   	leave  
f01005e1:	f3 c3                	repz ret 

f01005e3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01005e3:	55                   	push   %ebp
f01005e4:	89 e5                	mov    %esp,%ebp
f01005e6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01005e9:	b8 c5 02 10 f0       	mov    $0xf01002c5,%eax
f01005ee:	e8 8f fc ff ff       	call   f0100282 <cons_intr>
}
f01005f3:	c9                   	leave  
f01005f4:	c3                   	ret    

f01005f5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01005f5:	55                   	push   %ebp
f01005f6:	89 e5                	mov    %esp,%ebp
f01005f8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01005fb:	e8 c7 ff ff ff       	call   f01005c7 <serial_intr>
	kbd_intr();
f0100600:	e8 de ff ff ff       	call   f01005e3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100605:	a1 20 c2 22 f0       	mov    0xf022c220,%eax
f010060a:	3b 05 24 c2 22 f0    	cmp    0xf022c224,%eax
f0100610:	74 26                	je     f0100638 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100612:	8d 50 01             	lea    0x1(%eax),%edx
f0100615:	89 15 20 c2 22 f0    	mov    %edx,0xf022c220
f010061b:	0f b6 88 20 c0 22 f0 	movzbl -0xfdd3fe0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100622:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100624:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010062a:	75 11                	jne    f010063d <cons_getc+0x48>
			cons.rpos = 0;
f010062c:	c7 05 20 c2 22 f0 00 	movl   $0x0,0xf022c220
f0100633:	00 00 00 
f0100636:	eb 05                	jmp    f010063d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100638:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010063d:	c9                   	leave  
f010063e:	c3                   	ret    

f010063f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010063f:	55                   	push   %ebp
f0100640:	89 e5                	mov    %esp,%ebp
f0100642:	57                   	push   %edi
f0100643:	56                   	push   %esi
f0100644:	53                   	push   %ebx
f0100645:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100648:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010064f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100656:	5a a5 
	if (*cp != 0xA55A) {
f0100658:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010065f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100663:	74 11                	je     f0100676 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100665:	c7 05 30 c2 22 f0 b4 	movl   $0x3b4,0xf022c230
f010066c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010066f:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100674:	eb 16                	jmp    f010068c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100676:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010067d:	c7 05 30 c2 22 f0 d4 	movl   $0x3d4,0xf022c230
f0100684:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100687:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010068c:	8b 3d 30 c2 22 f0    	mov    0xf022c230,%edi
f0100692:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100697:	89 fa                	mov    %edi,%edx
f0100699:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010069a:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010069d:	89 da                	mov    %ebx,%edx
f010069f:	ec                   	in     (%dx),%al
f01006a0:	0f b6 c8             	movzbl %al,%ecx
f01006a3:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006a6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006ab:	89 fa                	mov    %edi,%edx
f01006ad:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006ae:	89 da                	mov    %ebx,%edx
f01006b0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01006b1:	89 35 2c c2 22 f0    	mov    %esi,0xf022c22c
	crt_pos = pos;
f01006b7:	0f b6 c0             	movzbl %al,%eax
f01006ba:	09 c8                	or     %ecx,%eax
f01006bc:	66 a3 28 c2 22 f0    	mov    %ax,0xf022c228

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f01006c2:	e8 1c ff ff ff       	call   f01005e3 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<IRQ_KBD));
f01006c7:	83 ec 0c             	sub    $0xc,%esp
f01006ca:	0f b7 05 a8 13 12 f0 	movzwl 0xf01213a8,%eax
f01006d1:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006d6:	50                   	push   %eax
f01006d7:	e8 2d 2e 00 00       	call   f0103509 <irq_setmask_8259A>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006dc:	be fa 03 00 00       	mov    $0x3fa,%esi
f01006e1:	b8 00 00 00 00       	mov    $0x0,%eax
f01006e6:	89 f2                	mov    %esi,%edx
f01006e8:	ee                   	out    %al,(%dx)
f01006e9:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01006ee:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01006f3:	ee                   	out    %al,(%dx)
f01006f4:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01006f9:	b8 0c 00 00 00       	mov    $0xc,%eax
f01006fe:	89 da                	mov    %ebx,%edx
f0100700:	ee                   	out    %al,(%dx)
f0100701:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100706:	b8 00 00 00 00       	mov    $0x0,%eax
f010070b:	ee                   	out    %al,(%dx)
f010070c:	ba fb 03 00 00       	mov    $0x3fb,%edx
f0100711:	b8 03 00 00 00       	mov    $0x3,%eax
f0100716:	ee                   	out    %al,(%dx)
f0100717:	ba fc 03 00 00       	mov    $0x3fc,%edx
f010071c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100721:	ee                   	out    %al,(%dx)
f0100722:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100727:	b8 01 00 00 00       	mov    $0x1,%eax
f010072c:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010072d:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100732:	ec                   	in     (%dx),%al
f0100733:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100735:	83 c4 10             	add    $0x10,%esp
f0100738:	3c ff                	cmp    $0xff,%al
f010073a:	0f 95 05 34 c2 22 f0 	setne  0xf022c234
f0100741:	89 f2                	mov    %esi,%edx
f0100743:	ec                   	in     (%dx),%al
f0100744:	89 da                	mov    %ebx,%edx
f0100746:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100747:	80 f9 ff             	cmp    $0xff,%cl
f010074a:	75 10                	jne    f010075c <cons_init+0x11d>
		cprintf("Serial port does not exist!\n");
f010074c:	83 ec 0c             	sub    $0xc,%esp
f010074f:	68 af 66 10 f0       	push   $0xf01066af
f0100754:	e8 01 2f 00 00       	call   f010365a <cprintf>
f0100759:	83 c4 10             	add    $0x10,%esp
}
f010075c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010075f:	5b                   	pop    %ebx
f0100760:	5e                   	pop    %esi
f0100761:	5f                   	pop    %edi
f0100762:	5d                   	pop    %ebp
f0100763:	c3                   	ret    

f0100764 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100764:	55                   	push   %ebp
f0100765:	89 e5                	mov    %esp,%ebp
f0100767:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010076a:	8b 45 08             	mov    0x8(%ebp),%eax
f010076d:	e8 6c fc ff ff       	call   f01003de <cons_putc>
}
f0100772:	c9                   	leave  
f0100773:	c3                   	ret    

f0100774 <getchar>:

int
getchar(void)
{
f0100774:	55                   	push   %ebp
f0100775:	89 e5                	mov    %esp,%ebp
f0100777:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010077a:	e8 76 fe ff ff       	call   f01005f5 <cons_getc>
f010077f:	85 c0                	test   %eax,%eax
f0100781:	74 f7                	je     f010077a <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100783:	c9                   	leave  
f0100784:	c3                   	ret    

f0100785 <iscons>:

int
iscons(int fdnum)
{
f0100785:	55                   	push   %ebp
f0100786:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100788:	b8 01 00 00 00       	mov    $0x1,%eax
f010078d:	5d                   	pop    %ebp
f010078e:	c3                   	ret    

f010078f <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010078f:	55                   	push   %ebp
f0100790:	89 e5                	mov    %esp,%ebp
f0100792:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100795:	68 00 69 10 f0       	push   $0xf0106900
f010079a:	68 1e 69 10 f0       	push   $0xf010691e
f010079f:	68 23 69 10 f0       	push   $0xf0106923
f01007a4:	e8 b1 2e 00 00       	call   f010365a <cprintf>
f01007a9:	83 c4 0c             	add    $0xc,%esp
f01007ac:	68 a8 69 10 f0       	push   $0xf01069a8
f01007b1:	68 2c 69 10 f0       	push   $0xf010692c
f01007b6:	68 23 69 10 f0       	push   $0xf0106923
f01007bb:	e8 9a 2e 00 00       	call   f010365a <cprintf>
f01007c0:	83 c4 0c             	add    $0xc,%esp
f01007c3:	68 d0 69 10 f0       	push   $0xf01069d0
f01007c8:	68 35 69 10 f0       	push   $0xf0106935
f01007cd:	68 23 69 10 f0       	push   $0xf0106923
f01007d2:	e8 83 2e 00 00       	call   f010365a <cprintf>
	return 0;
}
f01007d7:	b8 00 00 00 00       	mov    $0x0,%eax
f01007dc:	c9                   	leave  
f01007dd:	c3                   	ret    

f01007de <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007de:	55                   	push   %ebp
f01007df:	89 e5                	mov    %esp,%ebp
f01007e1:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007e4:	68 3f 69 10 f0       	push   $0xf010693f
f01007e9:	e8 6c 2e 00 00       	call   f010365a <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007ee:	83 c4 08             	add    $0x8,%esp
f01007f1:	68 0c 00 10 00       	push   $0x10000c
f01007f6:	68 f0 69 10 f0       	push   $0xf01069f0
f01007fb:	e8 5a 2e 00 00       	call   f010365a <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100800:	83 c4 0c             	add    $0xc,%esp
f0100803:	68 0c 00 10 00       	push   $0x10000c
f0100808:	68 0c 00 10 f0       	push   $0xf010000c
f010080d:	68 18 6a 10 f0       	push   $0xf0106a18
f0100812:	e8 43 2e 00 00       	call   f010365a <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100817:	83 c4 0c             	add    $0xc,%esp
f010081a:	68 c1 65 10 00       	push   $0x1065c1
f010081f:	68 c1 65 10 f0       	push   $0xf01065c1
f0100824:	68 3c 6a 10 f0       	push   $0xf0106a3c
f0100829:	e8 2c 2e 00 00       	call   f010365a <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010082e:	83 c4 0c             	add    $0xc,%esp
f0100831:	68 d8 b9 22 00       	push   $0x22b9d8
f0100836:	68 d8 b9 22 f0       	push   $0xf022b9d8
f010083b:	68 60 6a 10 f0       	push   $0xf0106a60
f0100840:	e8 15 2e 00 00       	call   f010365a <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100845:	83 c4 0c             	add    $0xc,%esp
f0100848:	68 08 e0 26 00       	push   $0x26e008
f010084d:	68 08 e0 26 f0       	push   $0xf026e008
f0100852:	68 84 6a 10 f0       	push   $0xf0106a84
f0100857:	e8 fe 2d 00 00       	call   f010365a <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010085c:	b8 07 e4 26 f0       	mov    $0xf026e407,%eax
f0100861:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100866:	83 c4 08             	add    $0x8,%esp
f0100869:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010086e:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100874:	85 c0                	test   %eax,%eax
f0100876:	0f 48 c2             	cmovs  %edx,%eax
f0100879:	c1 f8 0a             	sar    $0xa,%eax
f010087c:	50                   	push   %eax
f010087d:	68 a8 6a 10 f0       	push   $0xf0106aa8
f0100882:	e8 d3 2d 00 00       	call   f010365a <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100887:	b8 00 00 00 00       	mov    $0x0,%eax
f010088c:	c9                   	leave  
f010088d:	c3                   	ret    

f010088e <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010088e:	55                   	push   %ebp
f010088f:	89 e5                	mov    %esp,%ebp
f0100891:	57                   	push   %edi
f0100892:	56                   	push   %esi
f0100893:	53                   	push   %ebx
f0100894:	83 ec 38             	sub    $0x38,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100897:	89 eb                	mov    %ebp,%ebx
	// Your code here.
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
f0100899:	68 58 69 10 f0       	push   $0xf0106958
f010089e:	e8 b7 2d 00 00       	call   f010365a <cprintf>

	while (ebp != 0) {
f01008a3:	83 c4 10             	add    $0x10,%esp
		uintptr_t eip = *(uintptr_t *)(ebp + 0x4);
		struct Eipdebuginfo info;
		debuginfo_eip(eip, &info);
f01008a6:	8d 7d d0             	lea    -0x30(%ebp),%edi
{
	// Your code here.
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");

	while (ebp != 0) {
f01008a9:	eb 41                	jmp    f01008ec <mon_backtrace+0x5e>
		uintptr_t eip = *(uintptr_t *)(ebp + 0x4);
f01008ab:	8b 73 04             	mov    0x4(%ebx),%esi
		struct Eipdebuginfo info;
		debuginfo_eip(eip, &info);
f01008ae:	83 ec 08             	sub    $0x8,%esp
f01008b1:	57                   	push   %edi
f01008b2:	56                   	push   %esi
f01008b3:	e8 f4 45 00 00       	call   f0104eac <debuginfo_eip>

		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n"
f01008b8:	89 f0                	mov    %esi,%eax
f01008ba:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01008bd:	89 04 24             	mov    %eax,(%esp)
f01008c0:	ff 75 d8             	pushl  -0x28(%ebp)
f01008c3:	ff 75 dc             	pushl  -0x24(%ebp)
f01008c6:	ff 75 d4             	pushl  -0x2c(%ebp)
f01008c9:	ff 75 d0             	pushl  -0x30(%ebp)
f01008cc:	ff 73 18             	pushl  0x18(%ebx)
f01008cf:	ff 73 14             	pushl  0x14(%ebx)
f01008d2:	ff 73 10             	pushl  0x10(%ebx)
f01008d5:	ff 73 0c             	pushl  0xc(%ebx)
f01008d8:	ff 73 08             	pushl  0x8(%ebx)
f01008db:	56                   	push   %esi
f01008dc:	53                   	push   %ebx
f01008dd:	68 d4 6a 10 f0       	push   $0xf0106ad4
f01008e2:	e8 73 2d 00 00       	call   f010365a <cprintf>
				info.eip_file, info.eip_line,
				info.eip_fn_namelen, info.eip_fn_name,
				eip - info.eip_fn_addr
		);

		ebp = *(uint32_t *)ebp;
f01008e7:	8b 1b                	mov    (%ebx),%ebx
f01008e9:	83 c4 40             	add    $0x40,%esp
{
	// Your code here.
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");

	while (ebp != 0) {
f01008ec:	85 db                	test   %ebx,%ebx
f01008ee:	75 bb                	jne    f01008ab <mon_backtrace+0x1d>
		);

		ebp = *(uint32_t *)ebp;
	}
	return 0;
}
f01008f0:	b8 00 00 00 00       	mov    $0x0,%eax
f01008f5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008f8:	5b                   	pop    %ebx
f01008f9:	5e                   	pop    %esi
f01008fa:	5f                   	pop    %edi
f01008fb:	5d                   	pop    %ebp
f01008fc:	c3                   	ret    

f01008fd <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01008fd:	55                   	push   %ebp
f01008fe:	89 e5                	mov    %esp,%ebp
f0100900:	57                   	push   %edi
f0100901:	56                   	push   %esi
f0100902:	53                   	push   %ebx
f0100903:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100906:	68 24 6b 10 f0       	push   $0xf0106b24
f010090b:	e8 4a 2d 00 00       	call   f010365a <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100910:	c7 04 24 48 6b 10 f0 	movl   $0xf0106b48,(%esp)
f0100917:	e8 3e 2d 00 00       	call   f010365a <cprintf>

	if (tf != NULL)
f010091c:	83 c4 10             	add    $0x10,%esp
f010091f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100923:	74 0e                	je     f0100933 <monitor+0x36>
		print_trapframe(tf);
f0100925:	83 ec 0c             	sub    $0xc,%esp
f0100928:	ff 75 08             	pushl  0x8(%ebp)
f010092b:	e8 29 2f 00 00       	call   f0103859 <print_trapframe>
f0100930:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100933:	83 ec 0c             	sub    $0xc,%esp
f0100936:	68 6a 69 10 f0       	push   $0xf010696a
f010093b:	e8 89 4d 00 00       	call   f01056c9 <readline>
f0100940:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100942:	83 c4 10             	add    $0x10,%esp
f0100945:	85 c0                	test   %eax,%eax
f0100947:	74 ea                	je     f0100933 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100949:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100950:	be 00 00 00 00       	mov    $0x0,%esi
f0100955:	eb 0a                	jmp    f0100961 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100957:	c6 03 00             	movb   $0x0,(%ebx)
f010095a:	89 f7                	mov    %esi,%edi
f010095c:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010095f:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100961:	0f b6 03             	movzbl (%ebx),%eax
f0100964:	84 c0                	test   %al,%al
f0100966:	74 63                	je     f01009cb <monitor+0xce>
f0100968:	83 ec 08             	sub    $0x8,%esp
f010096b:	0f be c0             	movsbl %al,%eax
f010096e:	50                   	push   %eax
f010096f:	68 6e 69 10 f0       	push   $0xf010696e
f0100974:	e8 6a 4f 00 00       	call   f01058e3 <strchr>
f0100979:	83 c4 10             	add    $0x10,%esp
f010097c:	85 c0                	test   %eax,%eax
f010097e:	75 d7                	jne    f0100957 <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f0100980:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100983:	74 46                	je     f01009cb <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100985:	83 fe 0f             	cmp    $0xf,%esi
f0100988:	75 14                	jne    f010099e <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010098a:	83 ec 08             	sub    $0x8,%esp
f010098d:	6a 10                	push   $0x10
f010098f:	68 73 69 10 f0       	push   $0xf0106973
f0100994:	e8 c1 2c 00 00       	call   f010365a <cprintf>
f0100999:	83 c4 10             	add    $0x10,%esp
f010099c:	eb 95                	jmp    f0100933 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f010099e:	8d 7e 01             	lea    0x1(%esi),%edi
f01009a1:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01009a5:	eb 03                	jmp    f01009aa <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01009a7:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01009aa:	0f b6 03             	movzbl (%ebx),%eax
f01009ad:	84 c0                	test   %al,%al
f01009af:	74 ae                	je     f010095f <monitor+0x62>
f01009b1:	83 ec 08             	sub    $0x8,%esp
f01009b4:	0f be c0             	movsbl %al,%eax
f01009b7:	50                   	push   %eax
f01009b8:	68 6e 69 10 f0       	push   $0xf010696e
f01009bd:	e8 21 4f 00 00       	call   f01058e3 <strchr>
f01009c2:	83 c4 10             	add    $0x10,%esp
f01009c5:	85 c0                	test   %eax,%eax
f01009c7:	74 de                	je     f01009a7 <monitor+0xaa>
f01009c9:	eb 94                	jmp    f010095f <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f01009cb:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01009d2:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01009d3:	85 f6                	test   %esi,%esi
f01009d5:	0f 84 58 ff ff ff    	je     f0100933 <monitor+0x36>
f01009db:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01009e0:	83 ec 08             	sub    $0x8,%esp
f01009e3:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01009e6:	ff 34 85 80 6b 10 f0 	pushl  -0xfef9480(,%eax,4)
f01009ed:	ff 75 a8             	pushl  -0x58(%ebp)
f01009f0:	e8 90 4e 00 00       	call   f0105885 <strcmp>
f01009f5:	83 c4 10             	add    $0x10,%esp
f01009f8:	85 c0                	test   %eax,%eax
f01009fa:	75 21                	jne    f0100a1d <monitor+0x120>
			return commands[i].func(argc, argv, tf);
f01009fc:	83 ec 04             	sub    $0x4,%esp
f01009ff:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a02:	ff 75 08             	pushl  0x8(%ebp)
f0100a05:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a08:	52                   	push   %edx
f0100a09:	56                   	push   %esi
f0100a0a:	ff 14 85 88 6b 10 f0 	call   *-0xfef9478(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100a11:	83 c4 10             	add    $0x10,%esp
f0100a14:	85 c0                	test   %eax,%eax
f0100a16:	78 25                	js     f0100a3d <monitor+0x140>
f0100a18:	e9 16 ff ff ff       	jmp    f0100933 <monitor+0x36>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a1d:	83 c3 01             	add    $0x1,%ebx
f0100a20:	83 fb 03             	cmp    $0x3,%ebx
f0100a23:	75 bb                	jne    f01009e0 <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a25:	83 ec 08             	sub    $0x8,%esp
f0100a28:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a2b:	68 90 69 10 f0       	push   $0xf0106990
f0100a30:	e8 25 2c 00 00       	call   f010365a <cprintf>
f0100a35:	83 c4 10             	add    $0x10,%esp
f0100a38:	e9 f6 fe ff ff       	jmp    f0100933 <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a3d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a40:	5b                   	pop    %ebx
f0100a41:	5e                   	pop    %esi
f0100a42:	5f                   	pop    %edi
f0100a43:	5d                   	pop    %ebp
f0100a44:	c3                   	ret    

f0100a45 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a45:	55                   	push   %ebp
f0100a46:	89 e5                	mov    %esp,%ebp
f0100a48:	56                   	push   %esi
f0100a49:	53                   	push   %ebx
f0100a4a:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a4c:	83 ec 0c             	sub    $0xc,%esp
f0100a4f:	50                   	push   %eax
f0100a50:	e8 86 2a 00 00       	call   f01034db <mc146818_read>
f0100a55:	89 c6                	mov    %eax,%esi
f0100a57:	83 c3 01             	add    $0x1,%ebx
f0100a5a:	89 1c 24             	mov    %ebx,(%esp)
f0100a5d:	e8 79 2a 00 00       	call   f01034db <mc146818_read>
f0100a62:	c1 e0 08             	shl    $0x8,%eax
f0100a65:	09 f0                	or     %esi,%eax
}
f0100a67:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100a6a:	5b                   	pop    %ebx
f0100a6b:	5e                   	pop    %esi
f0100a6c:	5d                   	pop    %ebp
f0100a6d:	c3                   	ret    

f0100a6e <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100a6e:	55                   	push   %ebp
f0100a6f:	89 e5                	mov    %esp,%ebp
f0100a71:	53                   	push   %ebx
f0100a72:	83 ec 04             	sub    $0x4,%esp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100a75:	83 3d 38 c2 22 f0 00 	cmpl   $0x0,0xf022c238
f0100a7c:	75 11                	jne    f0100a8f <boot_alloc+0x21>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100a7e:	ba 07 f0 26 f0       	mov    $0xf026f007,%edx
f0100a83:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a89:	89 15 38 c2 22 f0    	mov    %edx,0xf022c238
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = ROUNDUP(nextfree, PGSIZE);
f0100a8f:	8b 0d 38 c2 22 f0    	mov    0xf022c238,%ecx
f0100a95:	8d 91 ff 0f 00 00    	lea    0xfff(%ecx),%edx
	//Finds the address of last location in boot_alloc.
	uint32_t alloc_space = (uint32_t) result - KERNBASE + n;
	//Calculates the total address space available.
	uint32_t total_space = (uint32_t) npages * PGSIZE;

	if(alloc_space > total_space)
f0100a9b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100aa1:	8d 9c 02 00 00 00 10 	lea    0x10000000(%edx,%eax,1),%ebx
f0100aa8:	8b 15 88 ce 22 f0    	mov    0xf022ce88,%edx
f0100aae:	c1 e2 0c             	shl    $0xc,%edx
f0100ab1:	39 d3                	cmp    %edx,%ebx
f0100ab3:	76 14                	jbe    f0100ac9 <boot_alloc+0x5b>
		panic( "boot_Alloc---OUT OF MEMORY \n");
f0100ab5:	83 ec 04             	sub    $0x4,%esp
f0100ab8:	68 a4 6b 10 f0       	push   $0xf0106ba4
f0100abd:	6a 74                	push   $0x74
f0100abf:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0100ac4:	e8 77 f5 ff ff       	call   f0100040 <_panic>

	if(n == 0) return nextfree;
f0100ac9:	85 c0                	test   %eax,%eax
f0100acb:	74 11                	je     f0100ade <boot_alloc+0x70>
	else if(n > 0){
		result = nextfree;
		nextfree = ROUNDUP((char *)(result + n) ,PGSIZE);
f0100acd:	8d 84 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%eax
f0100ad4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100ad9:	a3 38 c2 22 f0       	mov    %eax,0xf022c238
		return result;
	}


	return NULL;
}
f0100ade:	89 c8                	mov    %ecx,%eax
f0100ae0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100ae3:	c9                   	leave  
f0100ae4:	c3                   	ret    

f0100ae5 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100ae5:	89 d1                	mov    %edx,%ecx
f0100ae7:	c1 e9 16             	shr    $0x16,%ecx
f0100aea:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100aed:	a8 01                	test   $0x1,%al
f0100aef:	74 52                	je     f0100b43 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100af1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100af6:	89 c1                	mov    %eax,%ecx
f0100af8:	c1 e9 0c             	shr    $0xc,%ecx
f0100afb:	3b 0d 88 ce 22 f0    	cmp    0xf022ce88,%ecx
f0100b01:	72 1b                	jb     f0100b1e <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100b03:	55                   	push   %ebp
f0100b04:	89 e5                	mov    %esp,%ebp
f0100b06:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b09:	50                   	push   %eax
f0100b0a:	68 04 66 10 f0       	push   $0xf0106604
f0100b0f:	68 bd 03 00 00       	push   $0x3bd
f0100b14:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0100b19:	e8 22 f5 ff ff       	call   f0100040 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100b1e:	c1 ea 0c             	shr    $0xc,%edx
f0100b21:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b27:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100b2e:	89 c2                	mov    %eax,%edx
f0100b30:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b33:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b38:	85 d2                	test   %edx,%edx
f0100b3a:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100b3f:	0f 44 c2             	cmove  %edx,%eax
f0100b42:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100b43:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100b48:	c3                   	ret    

f0100b49 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100b49:	55                   	push   %ebp
f0100b4a:	89 e5                	mov    %esp,%ebp
f0100b4c:	57                   	push   %edi
f0100b4d:	56                   	push   %esi
f0100b4e:	53                   	push   %ebx
f0100b4f:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b52:	84 c0                	test   %al,%al
f0100b54:	0f 85 a0 02 00 00    	jne    f0100dfa <check_page_free_list+0x2b1>
f0100b5a:	e9 ad 02 00 00       	jmp    f0100e0c <check_page_free_list+0x2c3>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100b5f:	83 ec 04             	sub    $0x4,%esp
f0100b62:	68 d4 6e 10 f0       	push   $0xf0106ed4
f0100b67:	68 f0 02 00 00       	push   $0x2f0
f0100b6c:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0100b71:	e8 ca f4 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100b76:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100b79:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100b7c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b7f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100b82:	89 c2                	mov    %eax,%edx
f0100b84:	2b 15 90 ce 22 f0    	sub    0xf022ce90,%edx
f0100b8a:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100b90:	0f 95 c2             	setne  %dl
f0100b93:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100b96:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100b9a:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100b9c:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ba0:	8b 00                	mov    (%eax),%eax
f0100ba2:	85 c0                	test   %eax,%eax
f0100ba4:	75 dc                	jne    f0100b82 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100ba6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ba9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100baf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bb2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100bb5:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100bb7:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100bba:	a3 40 c2 22 f0       	mov    %eax,0xf022c240
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bbf:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100bc4:	8b 1d 40 c2 22 f0    	mov    0xf022c240,%ebx
f0100bca:	eb 53                	jmp    f0100c1f <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100bcc:	89 d8                	mov    %ebx,%eax
f0100bce:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f0100bd4:	c1 f8 03             	sar    $0x3,%eax
f0100bd7:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100bda:	89 c2                	mov    %eax,%edx
f0100bdc:	c1 ea 16             	shr    $0x16,%edx
f0100bdf:	39 f2                	cmp    %esi,%edx
f0100be1:	73 3a                	jae    f0100c1d <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100be3:	89 c2                	mov    %eax,%edx
f0100be5:	c1 ea 0c             	shr    $0xc,%edx
f0100be8:	3b 15 88 ce 22 f0    	cmp    0xf022ce88,%edx
f0100bee:	72 12                	jb     f0100c02 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bf0:	50                   	push   %eax
f0100bf1:	68 04 66 10 f0       	push   $0xf0106604
f0100bf6:	6a 58                	push   $0x58
f0100bf8:	68 cd 6b 10 f0       	push   $0xf0106bcd
f0100bfd:	e8 3e f4 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100c02:	83 ec 04             	sub    $0x4,%esp
f0100c05:	68 80 00 00 00       	push   $0x80
f0100c0a:	68 97 00 00 00       	push   $0x97
f0100c0f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c14:	50                   	push   %eax
f0100c15:	e8 06 4d 00 00       	call   f0105920 <memset>
f0100c1a:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c1d:	8b 1b                	mov    (%ebx),%ebx
f0100c1f:	85 db                	test   %ebx,%ebx
f0100c21:	75 a9                	jne    f0100bcc <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100c23:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c28:	e8 41 fe ff ff       	call   f0100a6e <boot_alloc>
f0100c2d:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c30:	8b 15 40 c2 22 f0    	mov    0xf022c240,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c36:	8b 0d 90 ce 22 f0    	mov    0xf022ce90,%ecx
		assert(pp < pages + npages);
f0100c3c:	a1 88 ce 22 f0       	mov    0xf022ce88,%eax
f0100c41:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100c44:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100c47:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c4a:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c4d:	be 00 00 00 00       	mov    $0x0,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c52:	e9 52 01 00 00       	jmp    f0100da9 <check_page_free_list+0x260>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c57:	39 ca                	cmp    %ecx,%edx
f0100c59:	73 19                	jae    f0100c74 <check_page_free_list+0x12b>
f0100c5b:	68 db 6b 10 f0       	push   $0xf0106bdb
f0100c60:	68 e7 6b 10 f0       	push   $0xf0106be7
f0100c65:	68 0a 03 00 00       	push   $0x30a
f0100c6a:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0100c6f:	e8 cc f3 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100c74:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100c77:	72 19                	jb     f0100c92 <check_page_free_list+0x149>
f0100c79:	68 fc 6b 10 f0       	push   $0xf0106bfc
f0100c7e:	68 e7 6b 10 f0       	push   $0xf0106be7
f0100c83:	68 0b 03 00 00       	push   $0x30b
f0100c88:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0100c8d:	e8 ae f3 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c92:	89 d0                	mov    %edx,%eax
f0100c94:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c97:	a8 07                	test   $0x7,%al
f0100c99:	74 19                	je     f0100cb4 <check_page_free_list+0x16b>
f0100c9b:	68 f8 6e 10 f0       	push   $0xf0106ef8
f0100ca0:	68 e7 6b 10 f0       	push   $0xf0106be7
f0100ca5:	68 0c 03 00 00       	push   $0x30c
f0100caa:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0100caf:	e8 8c f3 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100cb4:	c1 f8 03             	sar    $0x3,%eax
f0100cb7:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100cba:	85 c0                	test   %eax,%eax
f0100cbc:	75 19                	jne    f0100cd7 <check_page_free_list+0x18e>
f0100cbe:	68 10 6c 10 f0       	push   $0xf0106c10
f0100cc3:	68 e7 6b 10 f0       	push   $0xf0106be7
f0100cc8:	68 0f 03 00 00       	push   $0x30f
f0100ccd:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0100cd2:	e8 69 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100cd7:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100cdc:	75 19                	jne    f0100cf7 <check_page_free_list+0x1ae>
f0100cde:	68 21 6c 10 f0       	push   $0xf0106c21
f0100ce3:	68 e7 6b 10 f0       	push   $0xf0106be7
f0100ce8:	68 10 03 00 00       	push   $0x310
f0100ced:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0100cf2:	e8 49 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100cf7:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100cfc:	75 19                	jne    f0100d17 <check_page_free_list+0x1ce>
f0100cfe:	68 2c 6f 10 f0       	push   $0xf0106f2c
f0100d03:	68 e7 6b 10 f0       	push   $0xf0106be7
f0100d08:	68 11 03 00 00       	push   $0x311
f0100d0d:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0100d12:	e8 29 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d17:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100d1c:	75 19                	jne    f0100d37 <check_page_free_list+0x1ee>
f0100d1e:	68 3a 6c 10 f0       	push   $0xf0106c3a
f0100d23:	68 e7 6b 10 f0       	push   $0xf0106be7
f0100d28:	68 12 03 00 00       	push   $0x312
f0100d2d:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0100d32:	e8 09 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d37:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100d3c:	0f 86 f1 00 00 00    	jbe    f0100e33 <check_page_free_list+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d42:	89 c7                	mov    %eax,%edi
f0100d44:	c1 ef 0c             	shr    $0xc,%edi
f0100d47:	39 7d c8             	cmp    %edi,-0x38(%ebp)
f0100d4a:	77 12                	ja     f0100d5e <check_page_free_list+0x215>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d4c:	50                   	push   %eax
f0100d4d:	68 04 66 10 f0       	push   $0xf0106604
f0100d52:	6a 58                	push   $0x58
f0100d54:	68 cd 6b 10 f0       	push   $0xf0106bcd
f0100d59:	e8 e2 f2 ff ff       	call   f0100040 <_panic>
f0100d5e:	8d b8 00 00 00 f0    	lea    -0x10000000(%eax),%edi
f0100d64:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0100d67:	0f 86 b6 00 00 00    	jbe    f0100e23 <check_page_free_list+0x2da>
f0100d6d:	68 50 6f 10 f0       	push   $0xf0106f50
f0100d72:	68 e7 6b 10 f0       	push   $0xf0106be7
f0100d77:	68 13 03 00 00       	push   $0x313
f0100d7c:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0100d81:	e8 ba f2 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100d86:	68 54 6c 10 f0       	push   $0xf0106c54
f0100d8b:	68 e7 6b 10 f0       	push   $0xf0106be7
f0100d90:	68 15 03 00 00       	push   $0x315
f0100d95:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0100d9a:	e8 a1 f2 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d9f:	83 c6 01             	add    $0x1,%esi
f0100da2:	eb 03                	jmp    f0100da7 <check_page_free_list+0x25e>
		else
			++nfree_extmem;
f0100da4:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100da7:	8b 12                	mov    (%edx),%edx
f0100da9:	85 d2                	test   %edx,%edx
f0100dab:	0f 85 a6 fe ff ff    	jne    f0100c57 <check_page_free_list+0x10e>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100db1:	85 f6                	test   %esi,%esi
f0100db3:	7f 19                	jg     f0100dce <check_page_free_list+0x285>
f0100db5:	68 71 6c 10 f0       	push   $0xf0106c71
f0100dba:	68 e7 6b 10 f0       	push   $0xf0106be7
f0100dbf:	68 1d 03 00 00       	push   $0x31d
f0100dc4:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0100dc9:	e8 72 f2 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100dce:	85 db                	test   %ebx,%ebx
f0100dd0:	7f 19                	jg     f0100deb <check_page_free_list+0x2a2>
f0100dd2:	68 83 6c 10 f0       	push   $0xf0106c83
f0100dd7:	68 e7 6b 10 f0       	push   $0xf0106be7
f0100ddc:	68 1e 03 00 00       	push   $0x31e
f0100de1:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0100de6:	e8 55 f2 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100deb:	83 ec 0c             	sub    $0xc,%esp
f0100dee:	68 98 6f 10 f0       	push   $0xf0106f98
f0100df3:	e8 62 28 00 00       	call   f010365a <cprintf>
}
f0100df8:	eb 49                	jmp    f0100e43 <check_page_free_list+0x2fa>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100dfa:	a1 40 c2 22 f0       	mov    0xf022c240,%eax
f0100dff:	85 c0                	test   %eax,%eax
f0100e01:	0f 85 6f fd ff ff    	jne    f0100b76 <check_page_free_list+0x2d>
f0100e07:	e9 53 fd ff ff       	jmp    f0100b5f <check_page_free_list+0x16>
f0100e0c:	83 3d 40 c2 22 f0 00 	cmpl   $0x0,0xf022c240
f0100e13:	0f 84 46 fd ff ff    	je     f0100b5f <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e19:	be 00 04 00 00       	mov    $0x400,%esi
f0100e1e:	e9 a1 fd ff ff       	jmp    f0100bc4 <check_page_free_list+0x7b>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100e23:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100e28:	0f 85 76 ff ff ff    	jne    f0100da4 <check_page_free_list+0x25b>
f0100e2e:	e9 53 ff ff ff       	jmp    f0100d86 <check_page_free_list+0x23d>
f0100e33:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100e38:	0f 85 61 ff ff ff    	jne    f0100d9f <check_page_free_list+0x256>
f0100e3e:	e9 43 ff ff ff       	jmp    f0100d86 <check_page_free_list+0x23d>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0100e43:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e46:	5b                   	pop    %ebx
f0100e47:	5e                   	pop    %esi
f0100e48:	5f                   	pop    %edi
f0100e49:	5d                   	pop    %ebp
f0100e4a:	c3                   	ret    

f0100e4b <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100e4b:	55                   	push   %ebp
f0100e4c:	89 e5                	mov    %esp,%ebp
f0100e4e:	57                   	push   %edi
f0100e4f:	56                   	push   %esi
f0100e50:	53                   	push   %ebx
f0100e51:	83 ec 1c             	sub    $0x1c,%esp
	//     page tables and other data structures?
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	page_free_list = NULL;
f0100e54:	c7 05 40 c2 22 f0 00 	movl   $0x0,0xf022c240
f0100e5b:	00 00 00 
  uint32_t num_kpages = (((uint32_t) boot_alloc(0)) - KERNBASE) / PGSIZE;
f0100e5e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e63:	e8 06 fc ff ff       	call   f0100a6e <boot_alloc>
f0100e68:	05 00 00 00 10       	add    $0x10000000,%eax
f0100e6d:	c1 e8 0c             	shr    $0xc,%eax
  uint32_t num_pages_io_hole = 96;
	size_t i;
	for (i = 0; i < npages; i++) {
    if (i == 0 || // First page reserved for BIOS structures
        // Pages used up by the IO hole from 640K to 1MB
        (npages_basemem <= i && i < npages_basemem + num_pages_io_hole) ||
f0100e70:	8b 0d 44 c2 22 f0    	mov    0xf022c244,%ecx
f0100e76:	8d 59 60             	lea    0x60(%ecx),%ebx
	// free pages!
	page_free_list = NULL;
  uint32_t num_kpages = (((uint32_t) boot_alloc(0)) - KERNBASE) / PGSIZE;
  uint32_t num_pages_io_hole = 96;
	size_t i;
	for (i = 0; i < npages; i++) {
f0100e79:	bf 00 00 00 00       	mov    $0x0,%edi
f0100e7e:	be 00 00 00 00       	mov    $0x0,%esi
f0100e83:	ba 00 00 00 00       	mov    $0x0,%edx
    if (i == 0 || // First page reserved for BIOS structures
        // Pages used up by the IO hole from 640K to 1MB
        (npages_basemem <= i && i < npages_basemem + num_pages_io_hole) ||
        // Pages used up by the kernel and allocated to hold a page dir and
        // the pages array
        (npages_basemem + num_pages_io_hole <= i &&     i < npages_basemem + num_pages_io_hole + num_kpages) ||
f0100e88:	01 d8                	add    %ebx,%eax
f0100e8a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	// free pages!
	page_free_list = NULL;
  uint32_t num_kpages = (((uint32_t) boot_alloc(0)) - KERNBASE) / PGSIZE;
  uint32_t num_pages_io_hole = 96;
	size_t i;
	for (i = 0; i < npages; i++) {
f0100e8d:	eb 51                	jmp    f0100ee0 <page_init+0x95>
    if (i == 0 || // First page reserved for BIOS structures
f0100e8f:	85 d2                	test   %edx,%edx
f0100e91:	74 18                	je     f0100eab <page_init+0x60>
f0100e93:	39 ca                	cmp    %ecx,%edx
f0100e95:	72 06                	jb     f0100e9d <page_init+0x52>
        // Pages used up by the IO hole from 640K to 1MB
        (npages_basemem <= i && i < npages_basemem + num_pages_io_hole) ||
f0100e97:	39 da                	cmp    %ebx,%edx
f0100e99:	72 10                	jb     f0100eab <page_init+0x60>
f0100e9b:	eb 04                	jmp    f0100ea1 <page_init+0x56>
f0100e9d:	39 da                	cmp    %ebx,%edx
f0100e9f:	72 05                	jb     f0100ea6 <page_init+0x5b>
        // Pages used up by the kernel and allocated to hold a page dir and
        // the pages array
        (npages_basemem + num_pages_io_hole <= i &&     i < npages_basemem + num_pages_io_hole + num_kpages) ||
f0100ea1:	3b 55 e4             	cmp    -0x1c(%ebp),%edx
f0100ea4:	72 05                	jb     f0100eab <page_init+0x60>
f0100ea6:	83 fa 07             	cmp    $0x7,%edx
f0100ea9:	75 0e                	jne    f0100eb9 <page_init+0x6e>
	//page at MPENTRY_PADDR IS IN USE FOR THE AP BOOTING PROCEDURE
	(i == MPENTRY_PADDR/PGSIZE)) {
      	pages[i].pp_ref = 1;
f0100eab:	a1 90 ce 22 f0       	mov    0xf022ce90,%eax
f0100eb0:	66 c7 44 d0 04 01 00 	movw   $0x1,0x4(%eax,%edx,8)
      	continue;
f0100eb7:	eb 24                	jmp    f0100edd <page_init+0x92>
f0100eb9:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
    }
		pages[i].pp_ref = 0;
f0100ec0:	89 c7                	mov    %eax,%edi
f0100ec2:	03 3d 90 ce 22 f0    	add    0xf022ce90,%edi
f0100ec8:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)
		pages[i].pp_link = page_free_list;
f0100ece:	89 37                	mov    %esi,(%edi)
		page_free_list = &pages[i];
f0100ed0:	03 05 90 ce 22 f0    	add    0xf022ce90,%eax
f0100ed6:	89 c6                	mov    %eax,%esi
f0100ed8:	bf 01 00 00 00       	mov    $0x1,%edi
	// free pages!
	page_free_list = NULL;
  uint32_t num_kpages = (((uint32_t) boot_alloc(0)) - KERNBASE) / PGSIZE;
  uint32_t num_pages_io_hole = 96;
	size_t i;
	for (i = 0; i < npages; i++) {
f0100edd:	83 c2 01             	add    $0x1,%edx
f0100ee0:	3b 15 88 ce 22 f0    	cmp    0xf022ce88,%edx
f0100ee6:	72 a7                	jb     f0100e8f <page_init+0x44>
f0100ee8:	89 f8                	mov    %edi,%eax
f0100eea:	84 c0                	test   %al,%al
f0100eec:	74 06                	je     f0100ef4 <page_init+0xa9>
f0100eee:	89 35 40 c2 22 f0    	mov    %esi,0xf022c240
    }
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
}
}
f0100ef4:	83 c4 1c             	add    $0x1c,%esp
f0100ef7:	5b                   	pop    %ebx
f0100ef8:	5e                   	pop    %esi
f0100ef9:	5f                   	pop    %edi
f0100efa:	5d                   	pop    %ebp
f0100efb:	c3                   	ret    

f0100efc <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100efc:	55                   	push   %ebp
f0100efd:	89 e5                	mov    %esp,%ebp
f0100eff:	53                   	push   %ebx
f0100f00:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	if(page_free_list == NULL){
f0100f03:	8b 1d 40 c2 22 f0    	mov    0xf022c240,%ebx
f0100f09:	85 db                	test   %ebx,%ebx
f0100f0b:	74 58                	je     f0100f65 <page_alloc+0x69>
		return NULL;			//returns NULL if page_free_list points to NULL.
	}
	else{
		struct PageInfo *pp = page_free_list;
		page_free_list = page_free_list->pp_link;
f0100f0d:	8b 03                	mov    (%ebx),%eax
f0100f0f:	a3 40 c2 22 f0       	mov    %eax,0xf022c240
		pp->pp_link = NULL;
f0100f14:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		if(alloc_flags & ALLOC_ZERO)
f0100f1a:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100f1e:	74 45                	je     f0100f65 <page_alloc+0x69>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f20:	89 d8                	mov    %ebx,%eax
f0100f22:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f0100f28:	c1 f8 03             	sar    $0x3,%eax
f0100f2b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f2e:	89 c2                	mov    %eax,%edx
f0100f30:	c1 ea 0c             	shr    $0xc,%edx
f0100f33:	3b 15 88 ce 22 f0    	cmp    0xf022ce88,%edx
f0100f39:	72 12                	jb     f0100f4d <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f3b:	50                   	push   %eax
f0100f3c:	68 04 66 10 f0       	push   $0xf0106604
f0100f41:	6a 58                	push   $0x58
f0100f43:	68 cd 6b 10 f0       	push   $0xf0106bcd
f0100f48:	e8 f3 f0 ff ff       	call   f0100040 <_panic>
		memset( page2kva(pp), 0, PGSIZE);
f0100f4d:	83 ec 04             	sub    $0x4,%esp
f0100f50:	68 00 10 00 00       	push   $0x1000
f0100f55:	6a 00                	push   $0x0
f0100f57:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f5c:	50                   	push   %eax
f0100f5d:	e8 be 49 00 00       	call   f0105920 <memset>
f0100f62:	83 c4 10             	add    $0x10,%esp
		return pp;
		
	}
	
}
f0100f65:	89 d8                	mov    %ebx,%eax
f0100f67:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f6a:	c9                   	leave  
f0100f6b:	c3                   	ret    

f0100f6c <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100f6c:	55                   	push   %ebp
f0100f6d:	89 e5                	mov    %esp,%ebp
f0100f6f:	83 ec 08             	sub    $0x8,%esp
f0100f72:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if((pp->pp_ref != 0) || (pp->pp_link != NULL)){
f0100f75:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100f7a:	75 05                	jne    f0100f81 <page_free+0x15>
f0100f7c:	83 38 00             	cmpl   $0x0,(%eax)
f0100f7f:	74 17                	je     f0100f98 <page_free+0x2c>
	panic("page_free: Unable to Free Page");
f0100f81:	83 ec 04             	sub    $0x4,%esp
f0100f84:	68 bc 6f 10 f0       	push   $0xf0106fbc
f0100f89:	68 90 01 00 00       	push   $0x190
f0100f8e:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0100f93:	e8 a8 f0 ff ff       	call   f0100040 <_panic>
	}
	else{
	pp->pp_link = page_free_list;
f0100f98:	8b 15 40 c2 22 f0    	mov    0xf022c240,%edx
f0100f9e:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100fa0:	a3 40 c2 22 f0       	mov    %eax,0xf022c240
	}
}
f0100fa5:	c9                   	leave  
f0100fa6:	c3                   	ret    

f0100fa7 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100fa7:	55                   	push   %ebp
f0100fa8:	89 e5                	mov    %esp,%ebp
f0100faa:	83 ec 08             	sub    $0x8,%esp
f0100fad:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100fb0:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100fb4:	83 e8 01             	sub    $0x1,%eax
f0100fb7:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100fbb:	66 85 c0             	test   %ax,%ax
f0100fbe:	75 0c                	jne    f0100fcc <page_decref+0x25>
		page_free(pp);
f0100fc0:	83 ec 0c             	sub    $0xc,%esp
f0100fc3:	52                   	push   %edx
f0100fc4:	e8 a3 ff ff ff       	call   f0100f6c <page_free>
f0100fc9:	83 c4 10             	add    $0x10,%esp
}
f0100fcc:	c9                   	leave  
f0100fcd:	c3                   	ret    

f0100fce <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100fce:	55                   	push   %ebp
f0100fcf:	89 e5                	mov    %esp,%ebp
f0100fd1:	56                   	push   %esi
f0100fd2:	53                   	push   %ebx
f0100fd3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pgdir_entry = &pgdir[PDX(va)]; 
f0100fd6:	89 de                	mov    %ebx,%esi
f0100fd8:	c1 ee 16             	shr    $0x16,%esi
f0100fdb:	c1 e6 02             	shl    $0x2,%esi
f0100fde:	03 75 08             	add    0x8(%ebp),%esi
 
 
    if(*pgdir_entry & PTE_P) {  //if The relevant page table page exist and PTE_P is set
f0100fe1:	8b 06                	mov    (%esi),%eax
f0100fe3:	a8 01                	test   $0x1,%al
f0100fe5:	74 39                	je     f0101020 <pgdir_walk+0x52>
        pte_t *pt_va = KADDR(PTE_ADDR(*pgdir_entry));
f0100fe7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fec:	89 c2                	mov    %eax,%edx
f0100fee:	c1 ea 0c             	shr    $0xc,%edx
f0100ff1:	39 15 88 ce 22 f0    	cmp    %edx,0xf022ce88
f0100ff7:	77 15                	ja     f010100e <pgdir_walk+0x40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ff9:	50                   	push   %eax
f0100ffa:	68 04 66 10 f0       	push   $0xf0106604
f0100fff:	68 c1 01 00 00       	push   $0x1c1
f0101004:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101009:	e8 32 f0 ff ff       	call   f0100040 <_panic>
 
        return pt_va + PTX(va);   //page table + index
f010100e:	c1 eb 0a             	shr    $0xa,%ebx
f0101011:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0101017:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f010101e:	eb 74                	jmp    f0101094 <pgdir_walk+0xc6>
    } else {
        if(!create) {
f0101020:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101024:	74 62                	je     f0101088 <pgdir_walk+0xba>
            return NULL;    // If relevant page table page not exist yet and If create == false, then pgdir_walk returns NULL.
        } else {
            //allocates a new page table page with page_alloc.
            struct PageInfo *new_pgt = page_alloc(1);
f0101026:	83 ec 0c             	sub    $0xc,%esp
f0101029:	6a 01                	push   $0x1
f010102b:	e8 cc fe ff ff       	call   f0100efc <page_alloc>
         
            if(new_pgt == NULL) return NULL; //If the allocation fails, pgdir_walk returns NULL.                   
f0101030:	83 c4 10             	add    $0x10,%esp
f0101033:	85 c0                	test   %eax,%eax
f0101035:	74 58                	je     f010108f <pgdir_walk+0xc1>
            else  {
                new_pgt->pp_ref++;
f0101037:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010103c:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f0101042:	c1 f8 03             	sar    $0x3,%eax
f0101045:	c1 e0 0c             	shl    $0xc,%eax
                physaddr_t new_pgt_pa = page2pa(new_pgt);                                      
                *pgdir_entry = new_pgt_pa | PTE_W | PTE_U | PTE_P; //  write byte| user byte| present byte
f0101048:	89 c2                	mov    %eax,%edx
f010104a:	83 ca 07             	or     $0x7,%edx
f010104d:	89 16                	mov    %edx,(%esi)
                
		return (pte_t *)KADDR(PTE_ADDR(new_pgt_pa))  + PTX(va);   
f010104f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101054:	89 c2                	mov    %eax,%edx
f0101056:	c1 ea 0c             	shr    $0xc,%edx
f0101059:	3b 15 88 ce 22 f0    	cmp    0xf022ce88,%edx
f010105f:	72 15                	jb     f0101076 <pgdir_walk+0xa8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101061:	50                   	push   %eax
f0101062:	68 04 66 10 f0       	push   $0xf0106604
f0101067:	68 d1 01 00 00       	push   $0x1d1
f010106c:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101071:	e8 ca ef ff ff       	call   f0100040 <_panic>
f0101076:	c1 eb 0a             	shr    $0xa,%ebx
f0101079:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f010107f:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f0101086:	eb 0c                	jmp    f0101094 <pgdir_walk+0xc6>
        pte_t *pt_va = KADDR(PTE_ADDR(*pgdir_entry));
 
        return pt_va + PTX(va);   //page table + index
    } else {
        if(!create) {
            return NULL;    // If relevant page table page not exist yet and If create == false, then pgdir_walk returns NULL.
f0101088:	b8 00 00 00 00       	mov    $0x0,%eax
f010108d:	eb 05                	jmp    f0101094 <pgdir_walk+0xc6>
        } else {
            //allocates a new page table page with page_alloc.
            struct PageInfo *new_pgt = page_alloc(1);
         
            if(new_pgt == NULL) return NULL; //If the allocation fails, pgdir_walk returns NULL.                   
f010108f:	b8 00 00 00 00       	mov    $0x0,%eax
		return (pte_t *)KADDR(PTE_ADDR(new_pgt_pa))  + PTX(va);   
            }
         } 
      } 
	return NULL;
}
f0101094:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101097:	5b                   	pop    %ebx
f0101098:	5e                   	pop    %esi
f0101099:	5d                   	pop    %ebp
f010109a:	c3                   	ret    

f010109b <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f010109b:	55                   	push   %ebp
f010109c:	89 e5                	mov    %esp,%ebp
f010109e:	57                   	push   %edi
f010109f:	56                   	push   %esi
f01010a0:	53                   	push   %ebx
f01010a1:	83 ec 1c             	sub    $0x1c,%esp
f01010a4:	89 c7                	mov    %eax,%edi
f01010a6:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01010a9:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	uintptr_t unit;
	 pte_t *pgt_entry;
 
    for(unit = 0; unit < size; unit += PGSIZE) {
f01010ac:	bb 00 00 00 00       	mov    $0x0,%ebx
       
        
        pgt_entry = pgdir_walk(pgdir, (void *)va, 1); //pgdir_walk(pde_t *pgdir, const void *va, int create)
       
      
        *pgt_entry = pa | perm | PTE_P; //Use permission bits perm|PTE_P for the entries.
f01010b1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010b4:	83 c8 01             	or     $0x1,%eax
f01010b7:	89 45 dc             	mov    %eax,-0x24(%ebp)
{
	// Fill this function in
	uintptr_t unit;
	 pte_t *pgt_entry;
 
    for(unit = 0; unit < size; unit += PGSIZE) {
f01010ba:	eb 1f                	jmp    f01010db <boot_map_region+0x40>
       
        
        pgt_entry = pgdir_walk(pgdir, (void *)va, 1); //pgdir_walk(pde_t *pgdir, const void *va, int create)
f01010bc:	83 ec 04             	sub    $0x4,%esp
f01010bf:	6a 01                	push   $0x1
f01010c1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010c4:	01 d8                	add    %ebx,%eax
f01010c6:	50                   	push   %eax
f01010c7:	57                   	push   %edi
f01010c8:	e8 01 ff ff ff       	call   f0100fce <pgdir_walk>
       
      
        *pgt_entry = pa | perm | PTE_P; //Use permission bits perm|PTE_P for the entries.
f01010cd:	0b 75 dc             	or     -0x24(%ebp),%esi
f01010d0:	89 30                	mov    %esi,(%eax)
{
	// Fill this function in
	uintptr_t unit;
	 pte_t *pgt_entry;
 
    for(unit = 0; unit < size; unit += PGSIZE) {
f01010d2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01010d8:	83 c4 10             	add    $0x10,%esp
f01010db:	89 de                	mov    %ebx,%esi
f01010dd:	03 75 08             	add    0x8(%ebp),%esi
f01010e0:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f01010e3:	72 d7                	jb     f01010bc <boot_map_region+0x21>
       
        pa += PGSIZE;  // va and pa are both page-aligned.
        va += PGSIZE;
    }
	return;
}
f01010e5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010e8:	5b                   	pop    %ebx
f01010e9:	5e                   	pop    %esi
f01010ea:	5f                   	pop    %edi
f01010eb:	5d                   	pop    %ebp
f01010ec:	c3                   	ret    

f01010ed <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01010ed:	55                   	push   %ebp
f01010ee:	89 e5                	mov    %esp,%ebp
f01010f0:	53                   	push   %ebx
f01010f1:	83 ec 08             	sub    $0x8,%esp
f01010f4:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	//Gets the pointer to the corresponding page table entry
    pte_t *pgt_entry = pgdir_walk(pgdir, (void *)va, 0);  //not create
f01010f7:	6a 00                	push   $0x0
f01010f9:	ff 75 0c             	pushl  0xc(%ebp)
f01010fc:	ff 75 08             	pushl  0x8(%ebp)
f01010ff:	e8 ca fe ff ff       	call   f0100fce <pgdir_walk>
       
    if(pgt_entry == NULL || (*pgt_entry & PTE_P) == 0) {    //page not found
f0101104:	83 c4 10             	add    $0x10,%esp
f0101107:	85 c0                	test   %eax,%eax
f0101109:	74 37                	je     f0101142 <page_lookup+0x55>
f010110b:	f6 00 01             	testb  $0x1,(%eax)
f010110e:	74 39                	je     f0101149 <page_lookup+0x5c>
        //The page table entry pointer is empty, or the page table entry does not exist
        return NULL; //Return NULL if there is no page mapped at va.
    }
 
    if(pte_store != 0) {
f0101110:	85 db                	test   %ebx,%ebx
f0101112:	74 02                	je     f0101116 <page_lookup+0x29>
        //If pte_store is not 0, the address of the page table entry is stored
        *pte_store = pgt_entry;     //found and set
f0101114:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101116:	8b 00                	mov    (%eax),%eax
f0101118:	c1 e8 0c             	shr    $0xc,%eax
f010111b:	3b 05 88 ce 22 f0    	cmp    0xf022ce88,%eax
f0101121:	72 14                	jb     f0101137 <page_lookup+0x4a>
		panic("pa2page called with invalid pa");
f0101123:	83 ec 04             	sub    $0x4,%esp
f0101126:	68 dc 6f 10 f0       	push   $0xf0106fdc
f010112b:	6a 51                	push   $0x51
f010112d:	68 cd 6b 10 f0       	push   $0xf0106bcd
f0101132:	e8 09 ef ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0101137:	8b 15 90 ce 22 f0    	mov    0xf022ce90,%edx
f010113d:	8d 04 c2             	lea    (%edx,%eax,8),%eax
    }
    return pa2page(PTE_ADDR(*pgt_entry));
f0101140:	eb 0c                	jmp    f010114e <page_lookup+0x61>
	//Gets the pointer to the corresponding page table entry
    pte_t *pgt_entry = pgdir_walk(pgdir, (void *)va, 0);  //not create
       
    if(pgt_entry == NULL || (*pgt_entry & PTE_P) == 0) {    //page not found
        //The page table entry pointer is empty, or the page table entry does not exist
        return NULL; //Return NULL if there is no page mapped at va.
f0101142:	b8 00 00 00 00       	mov    $0x0,%eax
f0101147:	eb 05                	jmp    f010114e <page_lookup+0x61>
f0101149:	b8 00 00 00 00       	mov    $0x0,%eax
    if(pte_store != 0) {
        //If pte_store is not 0, the address of the page table entry is stored
        *pte_store = pgt_entry;     //found and set
    }
    return pa2page(PTE_ADDR(*pgt_entry));
}
f010114e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101151:	c9                   	leave  
f0101152:	c3                   	ret    

f0101153 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101153:	55                   	push   %ebp
f0101154:	89 e5                	mov    %esp,%ebp
f0101156:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f0101159:	e8 e4 4d 00 00       	call   f0105f42 <cpunum>
f010115e:	6b c0 74             	imul   $0x74,%eax,%eax
f0101161:	83 b8 28 d0 22 f0 00 	cmpl   $0x0,-0xfdd2fd8(%eax)
f0101168:	74 16                	je     f0101180 <tlb_invalidate+0x2d>
f010116a:	e8 d3 4d 00 00       	call   f0105f42 <cpunum>
f010116f:	6b c0 74             	imul   $0x74,%eax,%eax
f0101172:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0101178:	8b 55 08             	mov    0x8(%ebp),%edx
f010117b:	39 50 60             	cmp    %edx,0x60(%eax)
f010117e:	75 06                	jne    f0101186 <tlb_invalidate+0x33>
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101180:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101183:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f0101186:	c9                   	leave  
f0101187:	c3                   	ret    

f0101188 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101188:	55                   	push   %ebp
f0101189:	89 e5                	mov    %esp,%ebp
f010118b:	56                   	push   %esi
f010118c:	53                   	push   %ebx
f010118d:	83 ec 14             	sub    $0x14,%esp
f0101190:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101193:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pte_t *pgt_entry;
    struct PageInfo *pg_rm = page_lookup(pgdir, va, &pgt_entry);
f0101196:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101199:	50                   	push   %eax
f010119a:	56                   	push   %esi
f010119b:	53                   	push   %ebx
f010119c:	e8 4c ff ff ff       	call   f01010ed <page_lookup>
   
    if(pg_rm != NULL) {
f01011a1:	83 c4 10             	add    $0x10,%esp
f01011a4:	85 c0                	test   %eax,%eax
f01011a6:	74 1f                	je     f01011c7 <page_remove+0x3f>
        //   - The ref count on the physical page should decrement.
        //   - The physical page should be freed if the refcount reaches 0.
        page_decref(pg_rm); //znizi ref--
f01011a8:	83 ec 0c             	sub    $0xc,%esp
f01011ab:	50                   	push   %eax
f01011ac:	e8 f6 fd ff ff       	call   f0100fa7 <page_decref>
       
        //   - The pg table entry corresponding to 'va' should be set to 0.
        *pgt_entry = 0;
f01011b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011b4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
 
        //   - The TLB must be invalidated if you remove an entry from the page table.    
        tlb_invalidate(pgdir, va);
f01011ba:	83 c4 08             	add    $0x8,%esp
f01011bd:	56                   	push   %esi
f01011be:	53                   	push   %ebx
f01011bf:	e8 8f ff ff ff       	call   f0101153 <tlb_invalidate>
f01011c4:	83 c4 10             	add    $0x10,%esp
    }
    return; 
}
f01011c7:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01011ca:	5b                   	pop    %ebx
f01011cb:	5e                   	pop    %esi
f01011cc:	5d                   	pop    %ebp
f01011cd:	c3                   	ret    

f01011ce <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01011ce:	55                   	push   %ebp
f01011cf:	89 e5                	mov    %esp,%ebp
f01011d1:	57                   	push   %edi
f01011d2:	56                   	push   %esi
f01011d3:	53                   	push   %ebx
f01011d4:	83 ec 10             	sub    $0x10,%esp
f01011d7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01011da:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 1);  
f01011dd:	6a 01                	push   $0x1
f01011df:	57                   	push   %edi
f01011e0:	ff 75 08             	pushl  0x8(%ebp)
f01011e3:	e8 e6 fd ff ff       	call   f0100fce <pgdir_walk>
    if (!pte)   //page table not allocated
f01011e8:	83 c4 10             	add    $0x10,%esp
f01011eb:	85 c0                	test   %eax,%eax
f01011ed:	74 38                	je     f0101227 <page_insert+0x59>
f01011ef:	89 c6                	mov    %eax,%esi
        return -E_NO_MEM;  
   
    pp->pp_ref++;   //   - pp->pp_ref should be incremented if the insertion succeeds.
f01011f1:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
    if (*pte & PTE_P)  //   - If there is already a page mapped at 'va', it should be page_remove()d.  
f01011f6:	f6 00 01             	testb  $0x1,(%eax)
f01011f9:	74 0f                	je     f010120a <page_insert+0x3c>
        page_remove(pgdir, va);   //page colides, tle is invalidated in page_remove
f01011fb:	83 ec 08             	sub    $0x8,%esp
f01011fe:	57                   	push   %edi
f01011ff:	ff 75 08             	pushl  0x8(%ebp)
f0101202:	e8 81 ff ff ff       	call   f0101188 <page_remove>
f0101207:	83 c4 10             	add    $0x10,%esp
    *pte = page2pa(pp) | perm | PTE_P;  // should be set to 'perm|PTE_P'.
f010120a:	2b 1d 90 ce 22 f0    	sub    0xf022ce90,%ebx
f0101210:	c1 fb 03             	sar    $0x3,%ebx
f0101213:	c1 e3 0c             	shl    $0xc,%ebx
f0101216:	8b 45 14             	mov    0x14(%ebp),%eax
f0101219:	83 c8 01             	or     $0x1,%eax
f010121c:	09 c3                	or     %eax,%ebx
f010121e:	89 1e                	mov    %ebx,(%esi)
    return 0;
f0101220:	b8 00 00 00 00       	mov    $0x0,%eax
f0101225:	eb 05                	jmp    f010122c <page_insert+0x5e>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 1);  
    if (!pte)   //page table not allocated
        return -E_NO_MEM;  
f0101227:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    pp->pp_ref++;   //   - pp->pp_ref should be incremented if the insertion succeeds.
    if (*pte & PTE_P)  //   - If there is already a page mapped at 'va', it should be page_remove()d.  
        page_remove(pgdir, va);   //page colides, tle is invalidated in page_remove
    *pte = page2pa(pp) | perm | PTE_P;  // should be set to 'perm|PTE_P'.
    return 0;
}
f010122c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010122f:	5b                   	pop    %ebx
f0101230:	5e                   	pop    %esi
f0101231:	5f                   	pop    %edi
f0101232:	5d                   	pop    %ebp
f0101233:	c3                   	ret    

f0101234 <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f0101234:	55                   	push   %ebp
f0101235:	89 e5                	mov    %esp,%ebp
f0101237:	53                   	push   %ebx
f0101238:	83 ec 04             	sub    $0x4,%esp
	//
	// Hint: The staff solution uses boot_map_region.
	//
	// Your code here:
	//panic("mmio_map_region not implemented");
	uintptr_t va_start = base, va_end;
f010123b:	8b 1d 00 13 12 f0    	mov    0xf0121300,%ebx

	size = ROUNDUP(size, PGSIZE);
f0101241:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101244:	8d 88 ff 0f 00 00    	lea    0xfff(%eax),%ecx
f010124a:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
	va_end = base + size;
f0101250:	8d 04 0b             	lea    (%ebx,%ecx,1),%eax

	if (!(va_end >= MMIOBASE && va_end <= MMIOLIM))
f0101253:	8d 90 00 00 80 10    	lea    0x10800000(%eax),%edx
f0101259:	81 fa 00 00 40 00    	cmp    $0x400000,%edx
f010125f:	76 17                	jbe    f0101278 <mmio_map_region+0x44>
		panic("mmio_map_region: MMIO space overflow");
f0101261:	83 ec 04             	sub    $0x4,%esp
f0101264:	68 fc 6f 10 f0       	push   $0xf0106ffc
f0101269:	68 95 02 00 00       	push   $0x295
f010126e:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101273:	e8 c8 ed ff ff       	call   f0100040 <_panic>

	base = va_end;
f0101278:	a3 00 13 12 f0       	mov    %eax,0xf0121300

	boot_map_region(kern_pgdir, va_start, size, pa, PTE_W | PTE_PCD | PTE_PWT);
f010127d:	83 ec 08             	sub    $0x8,%esp
f0101280:	6a 1a                	push   $0x1a
f0101282:	ff 75 08             	pushl  0x8(%ebp)
f0101285:	89 da                	mov    %ebx,%edx
f0101287:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f010128c:	e8 0a fe ff ff       	call   f010109b <boot_map_region>
	
	return (void *) va_start;
}
f0101291:	89 d8                	mov    %ebx,%eax
f0101293:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101296:	c9                   	leave  
f0101297:	c3                   	ret    

f0101298 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101298:	55                   	push   %ebp
f0101299:	89 e5                	mov    %esp,%ebp
f010129b:	57                   	push   %edi
f010129c:	56                   	push   %esi
f010129d:	53                   	push   %ebx
f010129e:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f01012a1:	b8 15 00 00 00       	mov    $0x15,%eax
f01012a6:	e8 9a f7 ff ff       	call   f0100a45 <nvram_read>
f01012ab:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f01012ad:	b8 17 00 00 00       	mov    $0x17,%eax
f01012b2:	e8 8e f7 ff ff       	call   f0100a45 <nvram_read>
f01012b7:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01012b9:	b8 34 00 00 00       	mov    $0x34,%eax
f01012be:	e8 82 f7 ff ff       	call   f0100a45 <nvram_read>
f01012c3:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f01012c6:	85 c0                	test   %eax,%eax
f01012c8:	74 07                	je     f01012d1 <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f01012ca:	05 00 40 00 00       	add    $0x4000,%eax
f01012cf:	eb 0b                	jmp    f01012dc <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f01012d1:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01012d7:	85 f6                	test   %esi,%esi
f01012d9:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f01012dc:	89 c2                	mov    %eax,%edx
f01012de:	c1 ea 02             	shr    $0x2,%edx
f01012e1:	89 15 88 ce 22 f0    	mov    %edx,0xf022ce88
	npages_basemem = basemem / (PGSIZE / 1024);
f01012e7:	89 da                	mov    %ebx,%edx
f01012e9:	c1 ea 02             	shr    $0x2,%edx
f01012ec:	89 15 44 c2 22 f0    	mov    %edx,0xf022c244

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012f2:	89 c2                	mov    %eax,%edx
f01012f4:	29 da                	sub    %ebx,%edx
f01012f6:	52                   	push   %edx
f01012f7:	53                   	push   %ebx
f01012f8:	50                   	push   %eax
f01012f9:	68 24 70 10 f0       	push   $0xf0107024
f01012fe:	e8 57 23 00 00       	call   f010365a <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101303:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101308:	e8 61 f7 ff ff       	call   f0100a6e <boot_alloc>
f010130d:	a3 8c ce 22 f0       	mov    %eax,0xf022ce8c
	memset(kern_pgdir, 0, PGSIZE);
f0101312:	83 c4 0c             	add    $0xc,%esp
f0101315:	68 00 10 00 00       	push   $0x1000
f010131a:	6a 00                	push   $0x0
f010131c:	50                   	push   %eax
f010131d:	e8 fe 45 00 00       	call   f0105920 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101322:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101327:	83 c4 10             	add    $0x10,%esp
f010132a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010132f:	77 15                	ja     f0101346 <mem_init+0xae>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101331:	50                   	push   %eax
f0101332:	68 28 66 10 f0       	push   $0xf0106628
f0101337:	68 a2 00 00 00       	push   $0xa2
f010133c:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101341:	e8 fa ec ff ff       	call   f0100040 <_panic>
f0101346:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010134c:	83 ca 05             	or     $0x5,%edx
f010134f:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo *)boot_alloc(npages * sizeof(struct PageInfo));
f0101355:	a1 88 ce 22 f0       	mov    0xf022ce88,%eax
f010135a:	c1 e0 03             	shl    $0x3,%eax
f010135d:	e8 0c f7 ff ff       	call   f0100a6e <boot_alloc>
f0101362:	a3 90 ce 22 f0       	mov    %eax,0xf022ce90
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0101367:	83 ec 04             	sub    $0x4,%esp
f010136a:	8b 0d 88 ce 22 f0    	mov    0xf022ce88,%ecx
f0101370:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101377:	52                   	push   %edx
f0101378:	6a 00                	push   $0x0
f010137a:	50                   	push   %eax
f010137b:	e8 a0 45 00 00       	call   f0105920 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	uint32_t size_of_envs = NENV * sizeof(struct Env);
	envs = (struct Env *) boot_alloc(size_of_envs);
f0101380:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101385:	e8 e4 f6 ff ff       	call   f0100a6e <boot_alloc>
f010138a:	a3 48 c2 22 f0       	mov    %eax,0xf022c248
	memset(envs, 0 , size_of_envs);
f010138f:	83 c4 0c             	add    $0xc,%esp
f0101392:	68 00 f0 01 00       	push   $0x1f000
f0101397:	6a 00                	push   $0x0
f0101399:	50                   	push   %eax
f010139a:	e8 81 45 00 00       	call   f0105920 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010139f:	e8 a7 fa ff ff       	call   f0100e4b <page_init>

	check_page_free_list(1);
f01013a4:	b8 01 00 00 00       	mov    $0x1,%eax
f01013a9:	e8 9b f7 ff ff       	call   f0100b49 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01013ae:	83 c4 10             	add    $0x10,%esp
f01013b1:	83 3d 90 ce 22 f0 00 	cmpl   $0x0,0xf022ce90
f01013b8:	75 17                	jne    f01013d1 <mem_init+0x139>
		panic("'pages' is a null pointer!");
f01013ba:	83 ec 04             	sub    $0x4,%esp
f01013bd:	68 94 6c 10 f0       	push   $0xf0106c94
f01013c2:	68 31 03 00 00       	push   $0x331
f01013c7:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01013cc:	e8 6f ec ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013d1:	a1 40 c2 22 f0       	mov    0xf022c240,%eax
f01013d6:	bb 00 00 00 00       	mov    $0x0,%ebx
f01013db:	eb 05                	jmp    f01013e2 <mem_init+0x14a>
		++nfree;
f01013dd:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013e0:	8b 00                	mov    (%eax),%eax
f01013e2:	85 c0                	test   %eax,%eax
f01013e4:	75 f7                	jne    f01013dd <mem_init+0x145>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013e6:	83 ec 0c             	sub    $0xc,%esp
f01013e9:	6a 00                	push   $0x0
f01013eb:	e8 0c fb ff ff       	call   f0100efc <page_alloc>
f01013f0:	89 c7                	mov    %eax,%edi
f01013f2:	83 c4 10             	add    $0x10,%esp
f01013f5:	85 c0                	test   %eax,%eax
f01013f7:	75 19                	jne    f0101412 <mem_init+0x17a>
f01013f9:	68 af 6c 10 f0       	push   $0xf0106caf
f01013fe:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101403:	68 39 03 00 00       	push   $0x339
f0101408:	68 c1 6b 10 f0       	push   $0xf0106bc1
f010140d:	e8 2e ec ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101412:	83 ec 0c             	sub    $0xc,%esp
f0101415:	6a 00                	push   $0x0
f0101417:	e8 e0 fa ff ff       	call   f0100efc <page_alloc>
f010141c:	89 c6                	mov    %eax,%esi
f010141e:	83 c4 10             	add    $0x10,%esp
f0101421:	85 c0                	test   %eax,%eax
f0101423:	75 19                	jne    f010143e <mem_init+0x1a6>
f0101425:	68 c5 6c 10 f0       	push   $0xf0106cc5
f010142a:	68 e7 6b 10 f0       	push   $0xf0106be7
f010142f:	68 3a 03 00 00       	push   $0x33a
f0101434:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101439:	e8 02 ec ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010143e:	83 ec 0c             	sub    $0xc,%esp
f0101441:	6a 00                	push   $0x0
f0101443:	e8 b4 fa ff ff       	call   f0100efc <page_alloc>
f0101448:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010144b:	83 c4 10             	add    $0x10,%esp
f010144e:	85 c0                	test   %eax,%eax
f0101450:	75 19                	jne    f010146b <mem_init+0x1d3>
f0101452:	68 db 6c 10 f0       	push   $0xf0106cdb
f0101457:	68 e7 6b 10 f0       	push   $0xf0106be7
f010145c:	68 3b 03 00 00       	push   $0x33b
f0101461:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101466:	e8 d5 eb ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010146b:	39 f7                	cmp    %esi,%edi
f010146d:	75 19                	jne    f0101488 <mem_init+0x1f0>
f010146f:	68 f1 6c 10 f0       	push   $0xf0106cf1
f0101474:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101479:	68 3e 03 00 00       	push   $0x33e
f010147e:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101483:	e8 b8 eb ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101488:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010148b:	39 c6                	cmp    %eax,%esi
f010148d:	74 04                	je     f0101493 <mem_init+0x1fb>
f010148f:	39 c7                	cmp    %eax,%edi
f0101491:	75 19                	jne    f01014ac <mem_init+0x214>
f0101493:	68 60 70 10 f0       	push   $0xf0107060
f0101498:	68 e7 6b 10 f0       	push   $0xf0106be7
f010149d:	68 3f 03 00 00       	push   $0x33f
f01014a2:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01014a7:	e8 94 eb ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014ac:	8b 0d 90 ce 22 f0    	mov    0xf022ce90,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01014b2:	8b 15 88 ce 22 f0    	mov    0xf022ce88,%edx
f01014b8:	c1 e2 0c             	shl    $0xc,%edx
f01014bb:	89 f8                	mov    %edi,%eax
f01014bd:	29 c8                	sub    %ecx,%eax
f01014bf:	c1 f8 03             	sar    $0x3,%eax
f01014c2:	c1 e0 0c             	shl    $0xc,%eax
f01014c5:	39 d0                	cmp    %edx,%eax
f01014c7:	72 19                	jb     f01014e2 <mem_init+0x24a>
f01014c9:	68 03 6d 10 f0       	push   $0xf0106d03
f01014ce:	68 e7 6b 10 f0       	push   $0xf0106be7
f01014d3:	68 40 03 00 00       	push   $0x340
f01014d8:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01014dd:	e8 5e eb ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01014e2:	89 f0                	mov    %esi,%eax
f01014e4:	29 c8                	sub    %ecx,%eax
f01014e6:	c1 f8 03             	sar    $0x3,%eax
f01014e9:	c1 e0 0c             	shl    $0xc,%eax
f01014ec:	39 c2                	cmp    %eax,%edx
f01014ee:	77 19                	ja     f0101509 <mem_init+0x271>
f01014f0:	68 20 6d 10 f0       	push   $0xf0106d20
f01014f5:	68 e7 6b 10 f0       	push   $0xf0106be7
f01014fa:	68 41 03 00 00       	push   $0x341
f01014ff:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101504:	e8 37 eb ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101509:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010150c:	29 c8                	sub    %ecx,%eax
f010150e:	c1 f8 03             	sar    $0x3,%eax
f0101511:	c1 e0 0c             	shl    $0xc,%eax
f0101514:	39 c2                	cmp    %eax,%edx
f0101516:	77 19                	ja     f0101531 <mem_init+0x299>
f0101518:	68 3d 6d 10 f0       	push   $0xf0106d3d
f010151d:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101522:	68 42 03 00 00       	push   $0x342
f0101527:	68 c1 6b 10 f0       	push   $0xf0106bc1
f010152c:	e8 0f eb ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101531:	a1 40 c2 22 f0       	mov    0xf022c240,%eax
f0101536:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101539:	c7 05 40 c2 22 f0 00 	movl   $0x0,0xf022c240
f0101540:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101543:	83 ec 0c             	sub    $0xc,%esp
f0101546:	6a 00                	push   $0x0
f0101548:	e8 af f9 ff ff       	call   f0100efc <page_alloc>
f010154d:	83 c4 10             	add    $0x10,%esp
f0101550:	85 c0                	test   %eax,%eax
f0101552:	74 19                	je     f010156d <mem_init+0x2d5>
f0101554:	68 5a 6d 10 f0       	push   $0xf0106d5a
f0101559:	68 e7 6b 10 f0       	push   $0xf0106be7
f010155e:	68 49 03 00 00       	push   $0x349
f0101563:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101568:	e8 d3 ea ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f010156d:	83 ec 0c             	sub    $0xc,%esp
f0101570:	57                   	push   %edi
f0101571:	e8 f6 f9 ff ff       	call   f0100f6c <page_free>
	page_free(pp1);
f0101576:	89 34 24             	mov    %esi,(%esp)
f0101579:	e8 ee f9 ff ff       	call   f0100f6c <page_free>
	page_free(pp2);
f010157e:	83 c4 04             	add    $0x4,%esp
f0101581:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101584:	e8 e3 f9 ff ff       	call   f0100f6c <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101589:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101590:	e8 67 f9 ff ff       	call   f0100efc <page_alloc>
f0101595:	89 c6                	mov    %eax,%esi
f0101597:	83 c4 10             	add    $0x10,%esp
f010159a:	85 c0                	test   %eax,%eax
f010159c:	75 19                	jne    f01015b7 <mem_init+0x31f>
f010159e:	68 af 6c 10 f0       	push   $0xf0106caf
f01015a3:	68 e7 6b 10 f0       	push   $0xf0106be7
f01015a8:	68 50 03 00 00       	push   $0x350
f01015ad:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01015b2:	e8 89 ea ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01015b7:	83 ec 0c             	sub    $0xc,%esp
f01015ba:	6a 00                	push   $0x0
f01015bc:	e8 3b f9 ff ff       	call   f0100efc <page_alloc>
f01015c1:	89 c7                	mov    %eax,%edi
f01015c3:	83 c4 10             	add    $0x10,%esp
f01015c6:	85 c0                	test   %eax,%eax
f01015c8:	75 19                	jne    f01015e3 <mem_init+0x34b>
f01015ca:	68 c5 6c 10 f0       	push   $0xf0106cc5
f01015cf:	68 e7 6b 10 f0       	push   $0xf0106be7
f01015d4:	68 51 03 00 00       	push   $0x351
f01015d9:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01015de:	e8 5d ea ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01015e3:	83 ec 0c             	sub    $0xc,%esp
f01015e6:	6a 00                	push   $0x0
f01015e8:	e8 0f f9 ff ff       	call   f0100efc <page_alloc>
f01015ed:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015f0:	83 c4 10             	add    $0x10,%esp
f01015f3:	85 c0                	test   %eax,%eax
f01015f5:	75 19                	jne    f0101610 <mem_init+0x378>
f01015f7:	68 db 6c 10 f0       	push   $0xf0106cdb
f01015fc:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101601:	68 52 03 00 00       	push   $0x352
f0101606:	68 c1 6b 10 f0       	push   $0xf0106bc1
f010160b:	e8 30 ea ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101610:	39 fe                	cmp    %edi,%esi
f0101612:	75 19                	jne    f010162d <mem_init+0x395>
f0101614:	68 f1 6c 10 f0       	push   $0xf0106cf1
f0101619:	68 e7 6b 10 f0       	push   $0xf0106be7
f010161e:	68 54 03 00 00       	push   $0x354
f0101623:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101628:	e8 13 ea ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010162d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101630:	39 c7                	cmp    %eax,%edi
f0101632:	74 04                	je     f0101638 <mem_init+0x3a0>
f0101634:	39 c6                	cmp    %eax,%esi
f0101636:	75 19                	jne    f0101651 <mem_init+0x3b9>
f0101638:	68 60 70 10 f0       	push   $0xf0107060
f010163d:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101642:	68 55 03 00 00       	push   $0x355
f0101647:	68 c1 6b 10 f0       	push   $0xf0106bc1
f010164c:	e8 ef e9 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0101651:	83 ec 0c             	sub    $0xc,%esp
f0101654:	6a 00                	push   $0x0
f0101656:	e8 a1 f8 ff ff       	call   f0100efc <page_alloc>
f010165b:	83 c4 10             	add    $0x10,%esp
f010165e:	85 c0                	test   %eax,%eax
f0101660:	74 19                	je     f010167b <mem_init+0x3e3>
f0101662:	68 5a 6d 10 f0       	push   $0xf0106d5a
f0101667:	68 e7 6b 10 f0       	push   $0xf0106be7
f010166c:	68 56 03 00 00       	push   $0x356
f0101671:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101676:	e8 c5 e9 ff ff       	call   f0100040 <_panic>
f010167b:	89 f0                	mov    %esi,%eax
f010167d:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f0101683:	c1 f8 03             	sar    $0x3,%eax
f0101686:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101689:	89 c2                	mov    %eax,%edx
f010168b:	c1 ea 0c             	shr    $0xc,%edx
f010168e:	3b 15 88 ce 22 f0    	cmp    0xf022ce88,%edx
f0101694:	72 12                	jb     f01016a8 <mem_init+0x410>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101696:	50                   	push   %eax
f0101697:	68 04 66 10 f0       	push   $0xf0106604
f010169c:	6a 58                	push   $0x58
f010169e:	68 cd 6b 10 f0       	push   $0xf0106bcd
f01016a3:	e8 98 e9 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01016a8:	83 ec 04             	sub    $0x4,%esp
f01016ab:	68 00 10 00 00       	push   $0x1000
f01016b0:	6a 01                	push   $0x1
f01016b2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01016b7:	50                   	push   %eax
f01016b8:	e8 63 42 00 00       	call   f0105920 <memset>
	page_free(pp0);
f01016bd:	89 34 24             	mov    %esi,(%esp)
f01016c0:	e8 a7 f8 ff ff       	call   f0100f6c <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01016c5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01016cc:	e8 2b f8 ff ff       	call   f0100efc <page_alloc>
f01016d1:	83 c4 10             	add    $0x10,%esp
f01016d4:	85 c0                	test   %eax,%eax
f01016d6:	75 19                	jne    f01016f1 <mem_init+0x459>
f01016d8:	68 69 6d 10 f0       	push   $0xf0106d69
f01016dd:	68 e7 6b 10 f0       	push   $0xf0106be7
f01016e2:	68 5b 03 00 00       	push   $0x35b
f01016e7:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01016ec:	e8 4f e9 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f01016f1:	39 c6                	cmp    %eax,%esi
f01016f3:	74 19                	je     f010170e <mem_init+0x476>
f01016f5:	68 87 6d 10 f0       	push   $0xf0106d87
f01016fa:	68 e7 6b 10 f0       	push   $0xf0106be7
f01016ff:	68 5c 03 00 00       	push   $0x35c
f0101704:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101709:	e8 32 e9 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010170e:	89 f0                	mov    %esi,%eax
f0101710:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f0101716:	c1 f8 03             	sar    $0x3,%eax
f0101719:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010171c:	89 c2                	mov    %eax,%edx
f010171e:	c1 ea 0c             	shr    $0xc,%edx
f0101721:	3b 15 88 ce 22 f0    	cmp    0xf022ce88,%edx
f0101727:	72 12                	jb     f010173b <mem_init+0x4a3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101729:	50                   	push   %eax
f010172a:	68 04 66 10 f0       	push   $0xf0106604
f010172f:	6a 58                	push   $0x58
f0101731:	68 cd 6b 10 f0       	push   $0xf0106bcd
f0101736:	e8 05 e9 ff ff       	call   f0100040 <_panic>
f010173b:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101741:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101747:	80 38 00             	cmpb   $0x0,(%eax)
f010174a:	74 19                	je     f0101765 <mem_init+0x4cd>
f010174c:	68 97 6d 10 f0       	push   $0xf0106d97
f0101751:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101756:	68 5f 03 00 00       	push   $0x35f
f010175b:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101760:	e8 db e8 ff ff       	call   f0100040 <_panic>
f0101765:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101768:	39 d0                	cmp    %edx,%eax
f010176a:	75 db                	jne    f0101747 <mem_init+0x4af>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010176c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010176f:	a3 40 c2 22 f0       	mov    %eax,0xf022c240

	// free the pages we took
	page_free(pp0);
f0101774:	83 ec 0c             	sub    $0xc,%esp
f0101777:	56                   	push   %esi
f0101778:	e8 ef f7 ff ff       	call   f0100f6c <page_free>
	page_free(pp1);
f010177d:	89 3c 24             	mov    %edi,(%esp)
f0101780:	e8 e7 f7 ff ff       	call   f0100f6c <page_free>
	page_free(pp2);
f0101785:	83 c4 04             	add    $0x4,%esp
f0101788:	ff 75 d4             	pushl  -0x2c(%ebp)
f010178b:	e8 dc f7 ff ff       	call   f0100f6c <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101790:	a1 40 c2 22 f0       	mov    0xf022c240,%eax
f0101795:	83 c4 10             	add    $0x10,%esp
f0101798:	eb 05                	jmp    f010179f <mem_init+0x507>
		--nfree;
f010179a:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010179d:	8b 00                	mov    (%eax),%eax
f010179f:	85 c0                	test   %eax,%eax
f01017a1:	75 f7                	jne    f010179a <mem_init+0x502>
		--nfree;
	assert(nfree == 0);
f01017a3:	85 db                	test   %ebx,%ebx
f01017a5:	74 19                	je     f01017c0 <mem_init+0x528>
f01017a7:	68 a1 6d 10 f0       	push   $0xf0106da1
f01017ac:	68 e7 6b 10 f0       	push   $0xf0106be7
f01017b1:	68 6c 03 00 00       	push   $0x36c
f01017b6:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01017bb:	e8 80 e8 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01017c0:	83 ec 0c             	sub    $0xc,%esp
f01017c3:	68 80 70 10 f0       	push   $0xf0107080
f01017c8:	e8 8d 1e 00 00       	call   f010365a <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01017cd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017d4:	e8 23 f7 ff ff       	call   f0100efc <page_alloc>
f01017d9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01017dc:	83 c4 10             	add    $0x10,%esp
f01017df:	85 c0                	test   %eax,%eax
f01017e1:	75 19                	jne    f01017fc <mem_init+0x564>
f01017e3:	68 af 6c 10 f0       	push   $0xf0106caf
f01017e8:	68 e7 6b 10 f0       	push   $0xf0106be7
f01017ed:	68 d2 03 00 00       	push   $0x3d2
f01017f2:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01017f7:	e8 44 e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01017fc:	83 ec 0c             	sub    $0xc,%esp
f01017ff:	6a 00                	push   $0x0
f0101801:	e8 f6 f6 ff ff       	call   f0100efc <page_alloc>
f0101806:	89 c3                	mov    %eax,%ebx
f0101808:	83 c4 10             	add    $0x10,%esp
f010180b:	85 c0                	test   %eax,%eax
f010180d:	75 19                	jne    f0101828 <mem_init+0x590>
f010180f:	68 c5 6c 10 f0       	push   $0xf0106cc5
f0101814:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101819:	68 d3 03 00 00       	push   $0x3d3
f010181e:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101823:	e8 18 e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101828:	83 ec 0c             	sub    $0xc,%esp
f010182b:	6a 00                	push   $0x0
f010182d:	e8 ca f6 ff ff       	call   f0100efc <page_alloc>
f0101832:	89 c6                	mov    %eax,%esi
f0101834:	83 c4 10             	add    $0x10,%esp
f0101837:	85 c0                	test   %eax,%eax
f0101839:	75 19                	jne    f0101854 <mem_init+0x5bc>
f010183b:	68 db 6c 10 f0       	push   $0xf0106cdb
f0101840:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101845:	68 d4 03 00 00       	push   $0x3d4
f010184a:	68 c1 6b 10 f0       	push   $0xf0106bc1
f010184f:	e8 ec e7 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101854:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101857:	75 19                	jne    f0101872 <mem_init+0x5da>
f0101859:	68 f1 6c 10 f0       	push   $0xf0106cf1
f010185e:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101863:	68 d7 03 00 00       	push   $0x3d7
f0101868:	68 c1 6b 10 f0       	push   $0xf0106bc1
f010186d:	e8 ce e7 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101872:	39 c3                	cmp    %eax,%ebx
f0101874:	74 05                	je     f010187b <mem_init+0x5e3>
f0101876:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101879:	75 19                	jne    f0101894 <mem_init+0x5fc>
f010187b:	68 60 70 10 f0       	push   $0xf0107060
f0101880:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101885:	68 d8 03 00 00       	push   $0x3d8
f010188a:	68 c1 6b 10 f0       	push   $0xf0106bc1
f010188f:	e8 ac e7 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101894:	a1 40 c2 22 f0       	mov    0xf022c240,%eax
f0101899:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010189c:	c7 05 40 c2 22 f0 00 	movl   $0x0,0xf022c240
f01018a3:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01018a6:	83 ec 0c             	sub    $0xc,%esp
f01018a9:	6a 00                	push   $0x0
f01018ab:	e8 4c f6 ff ff       	call   f0100efc <page_alloc>
f01018b0:	83 c4 10             	add    $0x10,%esp
f01018b3:	85 c0                	test   %eax,%eax
f01018b5:	74 19                	je     f01018d0 <mem_init+0x638>
f01018b7:	68 5a 6d 10 f0       	push   $0xf0106d5a
f01018bc:	68 e7 6b 10 f0       	push   $0xf0106be7
f01018c1:	68 df 03 00 00       	push   $0x3df
f01018c6:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01018cb:	e8 70 e7 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01018d0:	83 ec 04             	sub    $0x4,%esp
f01018d3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01018d6:	50                   	push   %eax
f01018d7:	6a 00                	push   $0x0
f01018d9:	ff 35 8c ce 22 f0    	pushl  0xf022ce8c
f01018df:	e8 09 f8 ff ff       	call   f01010ed <page_lookup>
f01018e4:	83 c4 10             	add    $0x10,%esp
f01018e7:	85 c0                	test   %eax,%eax
f01018e9:	74 19                	je     f0101904 <mem_init+0x66c>
f01018eb:	68 a0 70 10 f0       	push   $0xf01070a0
f01018f0:	68 e7 6b 10 f0       	push   $0xf0106be7
f01018f5:	68 e2 03 00 00       	push   $0x3e2
f01018fa:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01018ff:	e8 3c e7 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101904:	6a 02                	push   $0x2
f0101906:	6a 00                	push   $0x0
f0101908:	53                   	push   %ebx
f0101909:	ff 35 8c ce 22 f0    	pushl  0xf022ce8c
f010190f:	e8 ba f8 ff ff       	call   f01011ce <page_insert>
f0101914:	83 c4 10             	add    $0x10,%esp
f0101917:	85 c0                	test   %eax,%eax
f0101919:	78 19                	js     f0101934 <mem_init+0x69c>
f010191b:	68 d8 70 10 f0       	push   $0xf01070d8
f0101920:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101925:	68 e5 03 00 00       	push   $0x3e5
f010192a:	68 c1 6b 10 f0       	push   $0xf0106bc1
f010192f:	e8 0c e7 ff ff       	call   f0100040 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101934:	83 ec 0c             	sub    $0xc,%esp
f0101937:	ff 75 d4             	pushl  -0x2c(%ebp)
f010193a:	e8 2d f6 ff ff       	call   f0100f6c <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010193f:	6a 02                	push   $0x2
f0101941:	6a 00                	push   $0x0
f0101943:	53                   	push   %ebx
f0101944:	ff 35 8c ce 22 f0    	pushl  0xf022ce8c
f010194a:	e8 7f f8 ff ff       	call   f01011ce <page_insert>
f010194f:	83 c4 20             	add    $0x20,%esp
f0101952:	85 c0                	test   %eax,%eax
f0101954:	74 19                	je     f010196f <mem_init+0x6d7>
f0101956:	68 08 71 10 f0       	push   $0xf0107108
f010195b:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101960:	68 e9 03 00 00       	push   $0x3e9
f0101965:	68 c1 6b 10 f0       	push   $0xf0106bc1
f010196a:	e8 d1 e6 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010196f:	8b 3d 8c ce 22 f0    	mov    0xf022ce8c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101975:	a1 90 ce 22 f0       	mov    0xf022ce90,%eax
f010197a:	89 c1                	mov    %eax,%ecx
f010197c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010197f:	8b 17                	mov    (%edi),%edx
f0101981:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101987:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010198a:	29 c8                	sub    %ecx,%eax
f010198c:	c1 f8 03             	sar    $0x3,%eax
f010198f:	c1 e0 0c             	shl    $0xc,%eax
f0101992:	39 c2                	cmp    %eax,%edx
f0101994:	74 19                	je     f01019af <mem_init+0x717>
f0101996:	68 38 71 10 f0       	push   $0xf0107138
f010199b:	68 e7 6b 10 f0       	push   $0xf0106be7
f01019a0:	68 ea 03 00 00       	push   $0x3ea
f01019a5:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01019aa:	e8 91 e6 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01019af:	ba 00 00 00 00       	mov    $0x0,%edx
f01019b4:	89 f8                	mov    %edi,%eax
f01019b6:	e8 2a f1 ff ff       	call   f0100ae5 <check_va2pa>
f01019bb:	89 da                	mov    %ebx,%edx
f01019bd:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01019c0:	c1 fa 03             	sar    $0x3,%edx
f01019c3:	c1 e2 0c             	shl    $0xc,%edx
f01019c6:	39 d0                	cmp    %edx,%eax
f01019c8:	74 19                	je     f01019e3 <mem_init+0x74b>
f01019ca:	68 60 71 10 f0       	push   $0xf0107160
f01019cf:	68 e7 6b 10 f0       	push   $0xf0106be7
f01019d4:	68 eb 03 00 00       	push   $0x3eb
f01019d9:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01019de:	e8 5d e6 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f01019e3:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01019e8:	74 19                	je     f0101a03 <mem_init+0x76b>
f01019ea:	68 ac 6d 10 f0       	push   $0xf0106dac
f01019ef:	68 e7 6b 10 f0       	push   $0xf0106be7
f01019f4:	68 ec 03 00 00       	push   $0x3ec
f01019f9:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01019fe:	e8 3d e6 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101a03:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a06:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101a0b:	74 19                	je     f0101a26 <mem_init+0x78e>
f0101a0d:	68 bd 6d 10 f0       	push   $0xf0106dbd
f0101a12:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101a17:	68 ed 03 00 00       	push   $0x3ed
f0101a1c:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101a21:	e8 1a e6 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a26:	6a 02                	push   $0x2
f0101a28:	68 00 10 00 00       	push   $0x1000
f0101a2d:	56                   	push   %esi
f0101a2e:	57                   	push   %edi
f0101a2f:	e8 9a f7 ff ff       	call   f01011ce <page_insert>
f0101a34:	83 c4 10             	add    $0x10,%esp
f0101a37:	85 c0                	test   %eax,%eax
f0101a39:	74 19                	je     f0101a54 <mem_init+0x7bc>
f0101a3b:	68 90 71 10 f0       	push   $0xf0107190
f0101a40:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101a45:	68 f0 03 00 00       	push   $0x3f0
f0101a4a:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101a4f:	e8 ec e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a54:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a59:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0101a5e:	e8 82 f0 ff ff       	call   f0100ae5 <check_va2pa>
f0101a63:	89 f2                	mov    %esi,%edx
f0101a65:	2b 15 90 ce 22 f0    	sub    0xf022ce90,%edx
f0101a6b:	c1 fa 03             	sar    $0x3,%edx
f0101a6e:	c1 e2 0c             	shl    $0xc,%edx
f0101a71:	39 d0                	cmp    %edx,%eax
f0101a73:	74 19                	je     f0101a8e <mem_init+0x7f6>
f0101a75:	68 cc 71 10 f0       	push   $0xf01071cc
f0101a7a:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101a7f:	68 f1 03 00 00       	push   $0x3f1
f0101a84:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101a89:	e8 b2 e5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101a8e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a93:	74 19                	je     f0101aae <mem_init+0x816>
f0101a95:	68 ce 6d 10 f0       	push   $0xf0106dce
f0101a9a:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101a9f:	68 f2 03 00 00       	push   $0x3f2
f0101aa4:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101aa9:	e8 92 e5 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101aae:	83 ec 0c             	sub    $0xc,%esp
f0101ab1:	6a 00                	push   $0x0
f0101ab3:	e8 44 f4 ff ff       	call   f0100efc <page_alloc>
f0101ab8:	83 c4 10             	add    $0x10,%esp
f0101abb:	85 c0                	test   %eax,%eax
f0101abd:	74 19                	je     f0101ad8 <mem_init+0x840>
f0101abf:	68 5a 6d 10 f0       	push   $0xf0106d5a
f0101ac4:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101ac9:	68 f5 03 00 00       	push   $0x3f5
f0101ace:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101ad3:	e8 68 e5 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ad8:	6a 02                	push   $0x2
f0101ada:	68 00 10 00 00       	push   $0x1000
f0101adf:	56                   	push   %esi
f0101ae0:	ff 35 8c ce 22 f0    	pushl  0xf022ce8c
f0101ae6:	e8 e3 f6 ff ff       	call   f01011ce <page_insert>
f0101aeb:	83 c4 10             	add    $0x10,%esp
f0101aee:	85 c0                	test   %eax,%eax
f0101af0:	74 19                	je     f0101b0b <mem_init+0x873>
f0101af2:	68 90 71 10 f0       	push   $0xf0107190
f0101af7:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101afc:	68 f8 03 00 00       	push   $0x3f8
f0101b01:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101b06:	e8 35 e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b0b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b10:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0101b15:	e8 cb ef ff ff       	call   f0100ae5 <check_va2pa>
f0101b1a:	89 f2                	mov    %esi,%edx
f0101b1c:	2b 15 90 ce 22 f0    	sub    0xf022ce90,%edx
f0101b22:	c1 fa 03             	sar    $0x3,%edx
f0101b25:	c1 e2 0c             	shl    $0xc,%edx
f0101b28:	39 d0                	cmp    %edx,%eax
f0101b2a:	74 19                	je     f0101b45 <mem_init+0x8ad>
f0101b2c:	68 cc 71 10 f0       	push   $0xf01071cc
f0101b31:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101b36:	68 f9 03 00 00       	push   $0x3f9
f0101b3b:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101b40:	e8 fb e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101b45:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b4a:	74 19                	je     f0101b65 <mem_init+0x8cd>
f0101b4c:	68 ce 6d 10 f0       	push   $0xf0106dce
f0101b51:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101b56:	68 fa 03 00 00       	push   $0x3fa
f0101b5b:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101b60:	e8 db e4 ff ff       	call   f0100040 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101b65:	83 ec 0c             	sub    $0xc,%esp
f0101b68:	6a 00                	push   $0x0
f0101b6a:	e8 8d f3 ff ff       	call   f0100efc <page_alloc>
f0101b6f:	83 c4 10             	add    $0x10,%esp
f0101b72:	85 c0                	test   %eax,%eax
f0101b74:	74 19                	je     f0101b8f <mem_init+0x8f7>
f0101b76:	68 5a 6d 10 f0       	push   $0xf0106d5a
f0101b7b:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101b80:	68 fe 03 00 00       	push   $0x3fe
f0101b85:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101b8a:	e8 b1 e4 ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101b8f:	8b 15 8c ce 22 f0    	mov    0xf022ce8c,%edx
f0101b95:	8b 02                	mov    (%edx),%eax
f0101b97:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101b9c:	89 c1                	mov    %eax,%ecx
f0101b9e:	c1 e9 0c             	shr    $0xc,%ecx
f0101ba1:	3b 0d 88 ce 22 f0    	cmp    0xf022ce88,%ecx
f0101ba7:	72 15                	jb     f0101bbe <mem_init+0x926>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ba9:	50                   	push   %eax
f0101baa:	68 04 66 10 f0       	push   $0xf0106604
f0101baf:	68 01 04 00 00       	push   $0x401
f0101bb4:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101bb9:	e8 82 e4 ff ff       	call   f0100040 <_panic>
f0101bbe:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101bc3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101bc6:	83 ec 04             	sub    $0x4,%esp
f0101bc9:	6a 00                	push   $0x0
f0101bcb:	68 00 10 00 00       	push   $0x1000
f0101bd0:	52                   	push   %edx
f0101bd1:	e8 f8 f3 ff ff       	call   f0100fce <pgdir_walk>
f0101bd6:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101bd9:	8d 51 04             	lea    0x4(%ecx),%edx
f0101bdc:	83 c4 10             	add    $0x10,%esp
f0101bdf:	39 d0                	cmp    %edx,%eax
f0101be1:	74 19                	je     f0101bfc <mem_init+0x964>
f0101be3:	68 fc 71 10 f0       	push   $0xf01071fc
f0101be8:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101bed:	68 02 04 00 00       	push   $0x402
f0101bf2:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101bf7:	e8 44 e4 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101bfc:	6a 06                	push   $0x6
f0101bfe:	68 00 10 00 00       	push   $0x1000
f0101c03:	56                   	push   %esi
f0101c04:	ff 35 8c ce 22 f0    	pushl  0xf022ce8c
f0101c0a:	e8 bf f5 ff ff       	call   f01011ce <page_insert>
f0101c0f:	83 c4 10             	add    $0x10,%esp
f0101c12:	85 c0                	test   %eax,%eax
f0101c14:	74 19                	je     f0101c2f <mem_init+0x997>
f0101c16:	68 3c 72 10 f0       	push   $0xf010723c
f0101c1b:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101c20:	68 05 04 00 00       	push   $0x405
f0101c25:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101c2a:	e8 11 e4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c2f:	8b 3d 8c ce 22 f0    	mov    0xf022ce8c,%edi
f0101c35:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c3a:	89 f8                	mov    %edi,%eax
f0101c3c:	e8 a4 ee ff ff       	call   f0100ae5 <check_va2pa>
f0101c41:	89 f2                	mov    %esi,%edx
f0101c43:	2b 15 90 ce 22 f0    	sub    0xf022ce90,%edx
f0101c49:	c1 fa 03             	sar    $0x3,%edx
f0101c4c:	c1 e2 0c             	shl    $0xc,%edx
f0101c4f:	39 d0                	cmp    %edx,%eax
f0101c51:	74 19                	je     f0101c6c <mem_init+0x9d4>
f0101c53:	68 cc 71 10 f0       	push   $0xf01071cc
f0101c58:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101c5d:	68 06 04 00 00       	push   $0x406
f0101c62:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101c67:	e8 d4 e3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101c6c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c71:	74 19                	je     f0101c8c <mem_init+0x9f4>
f0101c73:	68 ce 6d 10 f0       	push   $0xf0106dce
f0101c78:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101c7d:	68 07 04 00 00       	push   $0x407
f0101c82:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101c87:	e8 b4 e3 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101c8c:	83 ec 04             	sub    $0x4,%esp
f0101c8f:	6a 00                	push   $0x0
f0101c91:	68 00 10 00 00       	push   $0x1000
f0101c96:	57                   	push   %edi
f0101c97:	e8 32 f3 ff ff       	call   f0100fce <pgdir_walk>
f0101c9c:	83 c4 10             	add    $0x10,%esp
f0101c9f:	f6 00 04             	testb  $0x4,(%eax)
f0101ca2:	75 19                	jne    f0101cbd <mem_init+0xa25>
f0101ca4:	68 7c 72 10 f0       	push   $0xf010727c
f0101ca9:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101cae:	68 08 04 00 00       	push   $0x408
f0101cb3:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101cb8:	e8 83 e3 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101cbd:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0101cc2:	f6 00 04             	testb  $0x4,(%eax)
f0101cc5:	75 19                	jne    f0101ce0 <mem_init+0xa48>
f0101cc7:	68 df 6d 10 f0       	push   $0xf0106ddf
f0101ccc:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101cd1:	68 09 04 00 00       	push   $0x409
f0101cd6:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101cdb:	e8 60 e3 ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ce0:	6a 02                	push   $0x2
f0101ce2:	68 00 10 00 00       	push   $0x1000
f0101ce7:	56                   	push   %esi
f0101ce8:	50                   	push   %eax
f0101ce9:	e8 e0 f4 ff ff       	call   f01011ce <page_insert>
f0101cee:	83 c4 10             	add    $0x10,%esp
f0101cf1:	85 c0                	test   %eax,%eax
f0101cf3:	74 19                	je     f0101d0e <mem_init+0xa76>
f0101cf5:	68 90 71 10 f0       	push   $0xf0107190
f0101cfa:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101cff:	68 0c 04 00 00       	push   $0x40c
f0101d04:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101d09:	e8 32 e3 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101d0e:	83 ec 04             	sub    $0x4,%esp
f0101d11:	6a 00                	push   $0x0
f0101d13:	68 00 10 00 00       	push   $0x1000
f0101d18:	ff 35 8c ce 22 f0    	pushl  0xf022ce8c
f0101d1e:	e8 ab f2 ff ff       	call   f0100fce <pgdir_walk>
f0101d23:	83 c4 10             	add    $0x10,%esp
f0101d26:	f6 00 02             	testb  $0x2,(%eax)
f0101d29:	75 19                	jne    f0101d44 <mem_init+0xaac>
f0101d2b:	68 b0 72 10 f0       	push   $0xf01072b0
f0101d30:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101d35:	68 0d 04 00 00       	push   $0x40d
f0101d3a:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101d3f:	e8 fc e2 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d44:	83 ec 04             	sub    $0x4,%esp
f0101d47:	6a 00                	push   $0x0
f0101d49:	68 00 10 00 00       	push   $0x1000
f0101d4e:	ff 35 8c ce 22 f0    	pushl  0xf022ce8c
f0101d54:	e8 75 f2 ff ff       	call   f0100fce <pgdir_walk>
f0101d59:	83 c4 10             	add    $0x10,%esp
f0101d5c:	f6 00 04             	testb  $0x4,(%eax)
f0101d5f:	74 19                	je     f0101d7a <mem_init+0xae2>
f0101d61:	68 e4 72 10 f0       	push   $0xf01072e4
f0101d66:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101d6b:	68 0e 04 00 00       	push   $0x40e
f0101d70:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101d75:	e8 c6 e2 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101d7a:	6a 02                	push   $0x2
f0101d7c:	68 00 00 40 00       	push   $0x400000
f0101d81:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101d84:	ff 35 8c ce 22 f0    	pushl  0xf022ce8c
f0101d8a:	e8 3f f4 ff ff       	call   f01011ce <page_insert>
f0101d8f:	83 c4 10             	add    $0x10,%esp
f0101d92:	85 c0                	test   %eax,%eax
f0101d94:	78 19                	js     f0101daf <mem_init+0xb17>
f0101d96:	68 1c 73 10 f0       	push   $0xf010731c
f0101d9b:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101da0:	68 11 04 00 00       	push   $0x411
f0101da5:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101daa:	e8 91 e2 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101daf:	6a 02                	push   $0x2
f0101db1:	68 00 10 00 00       	push   $0x1000
f0101db6:	53                   	push   %ebx
f0101db7:	ff 35 8c ce 22 f0    	pushl  0xf022ce8c
f0101dbd:	e8 0c f4 ff ff       	call   f01011ce <page_insert>
f0101dc2:	83 c4 10             	add    $0x10,%esp
f0101dc5:	85 c0                	test   %eax,%eax
f0101dc7:	74 19                	je     f0101de2 <mem_init+0xb4a>
f0101dc9:	68 54 73 10 f0       	push   $0xf0107354
f0101dce:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101dd3:	68 14 04 00 00       	push   $0x414
f0101dd8:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101ddd:	e8 5e e2 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101de2:	83 ec 04             	sub    $0x4,%esp
f0101de5:	6a 00                	push   $0x0
f0101de7:	68 00 10 00 00       	push   $0x1000
f0101dec:	ff 35 8c ce 22 f0    	pushl  0xf022ce8c
f0101df2:	e8 d7 f1 ff ff       	call   f0100fce <pgdir_walk>
f0101df7:	83 c4 10             	add    $0x10,%esp
f0101dfa:	f6 00 04             	testb  $0x4,(%eax)
f0101dfd:	74 19                	je     f0101e18 <mem_init+0xb80>
f0101dff:	68 e4 72 10 f0       	push   $0xf01072e4
f0101e04:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101e09:	68 15 04 00 00       	push   $0x415
f0101e0e:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101e13:	e8 28 e2 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101e18:	8b 3d 8c ce 22 f0    	mov    0xf022ce8c,%edi
f0101e1e:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e23:	89 f8                	mov    %edi,%eax
f0101e25:	e8 bb ec ff ff       	call   f0100ae5 <check_va2pa>
f0101e2a:	89 c1                	mov    %eax,%ecx
f0101e2c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e2f:	89 d8                	mov    %ebx,%eax
f0101e31:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f0101e37:	c1 f8 03             	sar    $0x3,%eax
f0101e3a:	c1 e0 0c             	shl    $0xc,%eax
f0101e3d:	39 c1                	cmp    %eax,%ecx
f0101e3f:	74 19                	je     f0101e5a <mem_init+0xbc2>
f0101e41:	68 90 73 10 f0       	push   $0xf0107390
f0101e46:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101e4b:	68 18 04 00 00       	push   $0x418
f0101e50:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101e55:	e8 e6 e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e5a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e5f:	89 f8                	mov    %edi,%eax
f0101e61:	e8 7f ec ff ff       	call   f0100ae5 <check_va2pa>
f0101e66:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101e69:	74 19                	je     f0101e84 <mem_init+0xbec>
f0101e6b:	68 bc 73 10 f0       	push   $0xf01073bc
f0101e70:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101e75:	68 19 04 00 00       	push   $0x419
f0101e7a:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101e7f:	e8 bc e1 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101e84:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101e89:	74 19                	je     f0101ea4 <mem_init+0xc0c>
f0101e8b:	68 f5 6d 10 f0       	push   $0xf0106df5
f0101e90:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101e95:	68 1b 04 00 00       	push   $0x41b
f0101e9a:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101e9f:	e8 9c e1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101ea4:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ea9:	74 19                	je     f0101ec4 <mem_init+0xc2c>
f0101eab:	68 06 6e 10 f0       	push   $0xf0106e06
f0101eb0:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101eb5:	68 1c 04 00 00       	push   $0x41c
f0101eba:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101ebf:	e8 7c e1 ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101ec4:	83 ec 0c             	sub    $0xc,%esp
f0101ec7:	6a 00                	push   $0x0
f0101ec9:	e8 2e f0 ff ff       	call   f0100efc <page_alloc>
f0101ece:	83 c4 10             	add    $0x10,%esp
f0101ed1:	85 c0                	test   %eax,%eax
f0101ed3:	74 04                	je     f0101ed9 <mem_init+0xc41>
f0101ed5:	39 c6                	cmp    %eax,%esi
f0101ed7:	74 19                	je     f0101ef2 <mem_init+0xc5a>
f0101ed9:	68 ec 73 10 f0       	push   $0xf01073ec
f0101ede:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101ee3:	68 1f 04 00 00       	push   $0x41f
f0101ee8:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101eed:	e8 4e e1 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101ef2:	83 ec 08             	sub    $0x8,%esp
f0101ef5:	6a 00                	push   $0x0
f0101ef7:	ff 35 8c ce 22 f0    	pushl  0xf022ce8c
f0101efd:	e8 86 f2 ff ff       	call   f0101188 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f02:	8b 3d 8c ce 22 f0    	mov    0xf022ce8c,%edi
f0101f08:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f0d:	89 f8                	mov    %edi,%eax
f0101f0f:	e8 d1 eb ff ff       	call   f0100ae5 <check_va2pa>
f0101f14:	83 c4 10             	add    $0x10,%esp
f0101f17:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f1a:	74 19                	je     f0101f35 <mem_init+0xc9d>
f0101f1c:	68 10 74 10 f0       	push   $0xf0107410
f0101f21:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101f26:	68 23 04 00 00       	push   $0x423
f0101f2b:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101f30:	e8 0b e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101f35:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f3a:	89 f8                	mov    %edi,%eax
f0101f3c:	e8 a4 eb ff ff       	call   f0100ae5 <check_va2pa>
f0101f41:	89 da                	mov    %ebx,%edx
f0101f43:	2b 15 90 ce 22 f0    	sub    0xf022ce90,%edx
f0101f49:	c1 fa 03             	sar    $0x3,%edx
f0101f4c:	c1 e2 0c             	shl    $0xc,%edx
f0101f4f:	39 d0                	cmp    %edx,%eax
f0101f51:	74 19                	je     f0101f6c <mem_init+0xcd4>
f0101f53:	68 bc 73 10 f0       	push   $0xf01073bc
f0101f58:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101f5d:	68 24 04 00 00       	push   $0x424
f0101f62:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101f67:	e8 d4 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101f6c:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101f71:	74 19                	je     f0101f8c <mem_init+0xcf4>
f0101f73:	68 ac 6d 10 f0       	push   $0xf0106dac
f0101f78:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101f7d:	68 25 04 00 00       	push   $0x425
f0101f82:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101f87:	e8 b4 e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101f8c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f91:	74 19                	je     f0101fac <mem_init+0xd14>
f0101f93:	68 06 6e 10 f0       	push   $0xf0106e06
f0101f98:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101f9d:	68 26 04 00 00       	push   $0x426
f0101fa2:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101fa7:	e8 94 e0 ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101fac:	6a 00                	push   $0x0
f0101fae:	68 00 10 00 00       	push   $0x1000
f0101fb3:	53                   	push   %ebx
f0101fb4:	57                   	push   %edi
f0101fb5:	e8 14 f2 ff ff       	call   f01011ce <page_insert>
f0101fba:	83 c4 10             	add    $0x10,%esp
f0101fbd:	85 c0                	test   %eax,%eax
f0101fbf:	74 19                	je     f0101fda <mem_init+0xd42>
f0101fc1:	68 34 74 10 f0       	push   $0xf0107434
f0101fc6:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101fcb:	68 29 04 00 00       	push   $0x429
f0101fd0:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101fd5:	e8 66 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f0101fda:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101fdf:	75 19                	jne    f0101ffa <mem_init+0xd62>
f0101fe1:	68 17 6e 10 f0       	push   $0xf0106e17
f0101fe6:	68 e7 6b 10 f0       	push   $0xf0106be7
f0101feb:	68 2a 04 00 00       	push   $0x42a
f0101ff0:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0101ff5:	e8 46 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f0101ffa:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101ffd:	74 19                	je     f0102018 <mem_init+0xd80>
f0101fff:	68 23 6e 10 f0       	push   $0xf0106e23
f0102004:	68 e7 6b 10 f0       	push   $0xf0106be7
f0102009:	68 2b 04 00 00       	push   $0x42b
f010200e:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0102013:	e8 28 e0 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102018:	83 ec 08             	sub    $0x8,%esp
f010201b:	68 00 10 00 00       	push   $0x1000
f0102020:	ff 35 8c ce 22 f0    	pushl  0xf022ce8c
f0102026:	e8 5d f1 ff ff       	call   f0101188 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010202b:	8b 3d 8c ce 22 f0    	mov    0xf022ce8c,%edi
f0102031:	ba 00 00 00 00       	mov    $0x0,%edx
f0102036:	89 f8                	mov    %edi,%eax
f0102038:	e8 a8 ea ff ff       	call   f0100ae5 <check_va2pa>
f010203d:	83 c4 10             	add    $0x10,%esp
f0102040:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102043:	74 19                	je     f010205e <mem_init+0xdc6>
f0102045:	68 10 74 10 f0       	push   $0xf0107410
f010204a:	68 e7 6b 10 f0       	push   $0xf0106be7
f010204f:	68 2f 04 00 00       	push   $0x42f
f0102054:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0102059:	e8 e2 df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010205e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102063:	89 f8                	mov    %edi,%eax
f0102065:	e8 7b ea ff ff       	call   f0100ae5 <check_va2pa>
f010206a:	83 f8 ff             	cmp    $0xffffffff,%eax
f010206d:	74 19                	je     f0102088 <mem_init+0xdf0>
f010206f:	68 6c 74 10 f0       	push   $0xf010746c
f0102074:	68 e7 6b 10 f0       	push   $0xf0106be7
f0102079:	68 30 04 00 00       	push   $0x430
f010207e:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0102083:	e8 b8 df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102088:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010208d:	74 19                	je     f01020a8 <mem_init+0xe10>
f010208f:	68 38 6e 10 f0       	push   $0xf0106e38
f0102094:	68 e7 6b 10 f0       	push   $0xf0106be7
f0102099:	68 31 04 00 00       	push   $0x431
f010209e:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01020a3:	e8 98 df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01020a8:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01020ad:	74 19                	je     f01020c8 <mem_init+0xe30>
f01020af:	68 06 6e 10 f0       	push   $0xf0106e06
f01020b4:	68 e7 6b 10 f0       	push   $0xf0106be7
f01020b9:	68 32 04 00 00       	push   $0x432
f01020be:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01020c3:	e8 78 df ff ff       	call   f0100040 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01020c8:	83 ec 0c             	sub    $0xc,%esp
f01020cb:	6a 00                	push   $0x0
f01020cd:	e8 2a ee ff ff       	call   f0100efc <page_alloc>
f01020d2:	83 c4 10             	add    $0x10,%esp
f01020d5:	39 c3                	cmp    %eax,%ebx
f01020d7:	75 04                	jne    f01020dd <mem_init+0xe45>
f01020d9:	85 c0                	test   %eax,%eax
f01020db:	75 19                	jne    f01020f6 <mem_init+0xe5e>
f01020dd:	68 94 74 10 f0       	push   $0xf0107494
f01020e2:	68 e7 6b 10 f0       	push   $0xf0106be7
f01020e7:	68 35 04 00 00       	push   $0x435
f01020ec:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01020f1:	e8 4a df ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01020f6:	83 ec 0c             	sub    $0xc,%esp
f01020f9:	6a 00                	push   $0x0
f01020fb:	e8 fc ed ff ff       	call   f0100efc <page_alloc>
f0102100:	83 c4 10             	add    $0x10,%esp
f0102103:	85 c0                	test   %eax,%eax
f0102105:	74 19                	je     f0102120 <mem_init+0xe88>
f0102107:	68 5a 6d 10 f0       	push   $0xf0106d5a
f010210c:	68 e7 6b 10 f0       	push   $0xf0106be7
f0102111:	68 38 04 00 00       	push   $0x438
f0102116:	68 c1 6b 10 f0       	push   $0xf0106bc1
f010211b:	e8 20 df ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102120:	8b 0d 8c ce 22 f0    	mov    0xf022ce8c,%ecx
f0102126:	8b 11                	mov    (%ecx),%edx
f0102128:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010212e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102131:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f0102137:	c1 f8 03             	sar    $0x3,%eax
f010213a:	c1 e0 0c             	shl    $0xc,%eax
f010213d:	39 c2                	cmp    %eax,%edx
f010213f:	74 19                	je     f010215a <mem_init+0xec2>
f0102141:	68 38 71 10 f0       	push   $0xf0107138
f0102146:	68 e7 6b 10 f0       	push   $0xf0106be7
f010214b:	68 3b 04 00 00       	push   $0x43b
f0102150:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0102155:	e8 e6 de ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f010215a:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102160:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102163:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102168:	74 19                	je     f0102183 <mem_init+0xeeb>
f010216a:	68 bd 6d 10 f0       	push   $0xf0106dbd
f010216f:	68 e7 6b 10 f0       	push   $0xf0106be7
f0102174:	68 3d 04 00 00       	push   $0x43d
f0102179:	68 c1 6b 10 f0       	push   $0xf0106bc1
f010217e:	e8 bd de ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102183:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102186:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010218c:	83 ec 0c             	sub    $0xc,%esp
f010218f:	50                   	push   %eax
f0102190:	e8 d7 ed ff ff       	call   f0100f6c <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102195:	83 c4 0c             	add    $0xc,%esp
f0102198:	6a 01                	push   $0x1
f010219a:	68 00 10 40 00       	push   $0x401000
f010219f:	ff 35 8c ce 22 f0    	pushl  0xf022ce8c
f01021a5:	e8 24 ee ff ff       	call   f0100fce <pgdir_walk>
f01021aa:	89 c7                	mov    %eax,%edi
f01021ac:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01021af:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f01021b4:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01021b7:	8b 40 04             	mov    0x4(%eax),%eax
f01021ba:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01021bf:	8b 0d 88 ce 22 f0    	mov    0xf022ce88,%ecx
f01021c5:	89 c2                	mov    %eax,%edx
f01021c7:	c1 ea 0c             	shr    $0xc,%edx
f01021ca:	83 c4 10             	add    $0x10,%esp
f01021cd:	39 ca                	cmp    %ecx,%edx
f01021cf:	72 15                	jb     f01021e6 <mem_init+0xf4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01021d1:	50                   	push   %eax
f01021d2:	68 04 66 10 f0       	push   $0xf0106604
f01021d7:	68 44 04 00 00       	push   $0x444
f01021dc:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01021e1:	e8 5a de ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01021e6:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f01021eb:	39 c7                	cmp    %eax,%edi
f01021ed:	74 19                	je     f0102208 <mem_init+0xf70>
f01021ef:	68 49 6e 10 f0       	push   $0xf0106e49
f01021f4:	68 e7 6b 10 f0       	push   $0xf0106be7
f01021f9:	68 45 04 00 00       	push   $0x445
f01021fe:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0102203:	e8 38 de ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102208:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010220b:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0102212:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102215:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010221b:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f0102221:	c1 f8 03             	sar    $0x3,%eax
f0102224:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102227:	89 c2                	mov    %eax,%edx
f0102229:	c1 ea 0c             	shr    $0xc,%edx
f010222c:	39 d1                	cmp    %edx,%ecx
f010222e:	77 12                	ja     f0102242 <mem_init+0xfaa>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102230:	50                   	push   %eax
f0102231:	68 04 66 10 f0       	push   $0xf0106604
f0102236:	6a 58                	push   $0x58
f0102238:	68 cd 6b 10 f0       	push   $0xf0106bcd
f010223d:	e8 fe dd ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102242:	83 ec 04             	sub    $0x4,%esp
f0102245:	68 00 10 00 00       	push   $0x1000
f010224a:	68 ff 00 00 00       	push   $0xff
f010224f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102254:	50                   	push   %eax
f0102255:	e8 c6 36 00 00       	call   f0105920 <memset>
	page_free(pp0);
f010225a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010225d:	89 3c 24             	mov    %edi,(%esp)
f0102260:	e8 07 ed ff ff       	call   f0100f6c <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102265:	83 c4 0c             	add    $0xc,%esp
f0102268:	6a 01                	push   $0x1
f010226a:	6a 00                	push   $0x0
f010226c:	ff 35 8c ce 22 f0    	pushl  0xf022ce8c
f0102272:	e8 57 ed ff ff       	call   f0100fce <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102277:	89 fa                	mov    %edi,%edx
f0102279:	2b 15 90 ce 22 f0    	sub    0xf022ce90,%edx
f010227f:	c1 fa 03             	sar    $0x3,%edx
f0102282:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102285:	89 d0                	mov    %edx,%eax
f0102287:	c1 e8 0c             	shr    $0xc,%eax
f010228a:	83 c4 10             	add    $0x10,%esp
f010228d:	3b 05 88 ce 22 f0    	cmp    0xf022ce88,%eax
f0102293:	72 12                	jb     f01022a7 <mem_init+0x100f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102295:	52                   	push   %edx
f0102296:	68 04 66 10 f0       	push   $0xf0106604
f010229b:	6a 58                	push   $0x58
f010229d:	68 cd 6b 10 f0       	push   $0xf0106bcd
f01022a2:	e8 99 dd ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01022a7:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01022ad:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01022b0:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01022b6:	f6 00 01             	testb  $0x1,(%eax)
f01022b9:	74 19                	je     f01022d4 <mem_init+0x103c>
f01022bb:	68 61 6e 10 f0       	push   $0xf0106e61
f01022c0:	68 e7 6b 10 f0       	push   $0xf0106be7
f01022c5:	68 4f 04 00 00       	push   $0x44f
f01022ca:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01022cf:	e8 6c dd ff ff       	call   f0100040 <_panic>
f01022d4:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01022d7:	39 c2                	cmp    %eax,%edx
f01022d9:	75 db                	jne    f01022b6 <mem_init+0x101e>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01022db:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f01022e0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01022e6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022e9:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01022ef:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01022f2:	89 0d 40 c2 22 f0    	mov    %ecx,0xf022c240

	// free the pages we took
	page_free(pp0);
f01022f8:	83 ec 0c             	sub    $0xc,%esp
f01022fb:	50                   	push   %eax
f01022fc:	e8 6b ec ff ff       	call   f0100f6c <page_free>
	page_free(pp1);
f0102301:	89 1c 24             	mov    %ebx,(%esp)
f0102304:	e8 63 ec ff ff       	call   f0100f6c <page_free>
	page_free(pp2);
f0102309:	89 34 24             	mov    %esi,(%esp)
f010230c:	e8 5b ec ff ff       	call   f0100f6c <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f0102311:	83 c4 08             	add    $0x8,%esp
f0102314:	68 01 10 00 00       	push   $0x1001
f0102319:	6a 00                	push   $0x0
f010231b:	e8 14 ef ff ff       	call   f0101234 <mmio_map_region>
f0102320:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f0102322:	83 c4 08             	add    $0x8,%esp
f0102325:	68 00 10 00 00       	push   $0x1000
f010232a:	6a 00                	push   $0x0
f010232c:	e8 03 ef ff ff       	call   f0101234 <mmio_map_region>
f0102331:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f0102333:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f0102339:	83 c4 10             	add    $0x10,%esp
f010233c:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102342:	76 07                	jbe    f010234b <mem_init+0x10b3>
f0102344:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f0102349:	76 19                	jbe    f0102364 <mem_init+0x10cc>
f010234b:	68 b8 74 10 f0       	push   $0xf01074b8
f0102350:	68 e7 6b 10 f0       	push   $0xf0106be7
f0102355:	68 5f 04 00 00       	push   $0x45f
f010235a:	68 c1 6b 10 f0       	push   $0xf0106bc1
f010235f:	e8 dc dc ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f0102364:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f010236a:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f0102370:	77 08                	ja     f010237a <mem_init+0x10e2>
f0102372:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102378:	77 19                	ja     f0102393 <mem_init+0x10fb>
f010237a:	68 e0 74 10 f0       	push   $0xf01074e0
f010237f:	68 e7 6b 10 f0       	push   $0xf0106be7
f0102384:	68 60 04 00 00       	push   $0x460
f0102389:	68 c1 6b 10 f0       	push   $0xf0106bc1
f010238e:	e8 ad dc ff ff       	call   f0100040 <_panic>
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102393:	89 da                	mov    %ebx,%edx
f0102395:	09 f2                	or     %esi,%edx
f0102397:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f010239d:	74 19                	je     f01023b8 <mem_init+0x1120>
f010239f:	68 08 75 10 f0       	push   $0xf0107508
f01023a4:	68 e7 6b 10 f0       	push   $0xf0106be7
f01023a9:	68 62 04 00 00       	push   $0x462
f01023ae:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01023b3:	e8 88 dc ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f01023b8:	39 c6                	cmp    %eax,%esi
f01023ba:	73 19                	jae    f01023d5 <mem_init+0x113d>
f01023bc:	68 78 6e 10 f0       	push   $0xf0106e78
f01023c1:	68 e7 6b 10 f0       	push   $0xf0106be7
f01023c6:	68 64 04 00 00       	push   $0x464
f01023cb:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01023d0:	e8 6b dc ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f01023d5:	8b 3d 8c ce 22 f0    	mov    0xf022ce8c,%edi
f01023db:	89 da                	mov    %ebx,%edx
f01023dd:	89 f8                	mov    %edi,%eax
f01023df:	e8 01 e7 ff ff       	call   f0100ae5 <check_va2pa>
f01023e4:	85 c0                	test   %eax,%eax
f01023e6:	74 19                	je     f0102401 <mem_init+0x1169>
f01023e8:	68 30 75 10 f0       	push   $0xf0107530
f01023ed:	68 e7 6b 10 f0       	push   $0xf0106be7
f01023f2:	68 66 04 00 00       	push   $0x466
f01023f7:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01023fc:	e8 3f dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f0102401:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f0102407:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010240a:	89 c2                	mov    %eax,%edx
f010240c:	89 f8                	mov    %edi,%eax
f010240e:	e8 d2 e6 ff ff       	call   f0100ae5 <check_va2pa>
f0102413:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102418:	74 19                	je     f0102433 <mem_init+0x119b>
f010241a:	68 54 75 10 f0       	push   $0xf0107554
f010241f:	68 e7 6b 10 f0       	push   $0xf0106be7
f0102424:	68 67 04 00 00       	push   $0x467
f0102429:	68 c1 6b 10 f0       	push   $0xf0106bc1
f010242e:	e8 0d dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f0102433:	89 f2                	mov    %esi,%edx
f0102435:	89 f8                	mov    %edi,%eax
f0102437:	e8 a9 e6 ff ff       	call   f0100ae5 <check_va2pa>
f010243c:	85 c0                	test   %eax,%eax
f010243e:	74 19                	je     f0102459 <mem_init+0x11c1>
f0102440:	68 84 75 10 f0       	push   $0xf0107584
f0102445:	68 e7 6b 10 f0       	push   $0xf0106be7
f010244a:	68 68 04 00 00       	push   $0x468
f010244f:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0102454:	e8 e7 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f0102459:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f010245f:	89 f8                	mov    %edi,%eax
f0102461:	e8 7f e6 ff ff       	call   f0100ae5 <check_va2pa>
f0102466:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102469:	74 19                	je     f0102484 <mem_init+0x11ec>
f010246b:	68 a8 75 10 f0       	push   $0xf01075a8
f0102470:	68 e7 6b 10 f0       	push   $0xf0106be7
f0102475:	68 69 04 00 00       	push   $0x469
f010247a:	68 c1 6b 10 f0       	push   $0xf0106bc1
f010247f:	e8 bc db ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102484:	83 ec 04             	sub    $0x4,%esp
f0102487:	6a 00                	push   $0x0
f0102489:	53                   	push   %ebx
f010248a:	57                   	push   %edi
f010248b:	e8 3e eb ff ff       	call   f0100fce <pgdir_walk>
f0102490:	83 c4 10             	add    $0x10,%esp
f0102493:	f6 00 1a             	testb  $0x1a,(%eax)
f0102496:	75 19                	jne    f01024b1 <mem_init+0x1219>
f0102498:	68 d4 75 10 f0       	push   $0xf01075d4
f010249d:	68 e7 6b 10 f0       	push   $0xf0106be7
f01024a2:	68 6b 04 00 00       	push   $0x46b
f01024a7:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01024ac:	e8 8f db ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f01024b1:	83 ec 04             	sub    $0x4,%esp
f01024b4:	6a 00                	push   $0x0
f01024b6:	53                   	push   %ebx
f01024b7:	ff 35 8c ce 22 f0    	pushl  0xf022ce8c
f01024bd:	e8 0c eb ff ff       	call   f0100fce <pgdir_walk>
f01024c2:	8b 00                	mov    (%eax),%eax
f01024c4:	83 c4 10             	add    $0x10,%esp
f01024c7:	83 e0 04             	and    $0x4,%eax
f01024ca:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01024cd:	74 19                	je     f01024e8 <mem_init+0x1250>
f01024cf:	68 18 76 10 f0       	push   $0xf0107618
f01024d4:	68 e7 6b 10 f0       	push   $0xf0106be7
f01024d9:	68 6c 04 00 00       	push   $0x46c
f01024de:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01024e3:	e8 58 db ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f01024e8:	83 ec 04             	sub    $0x4,%esp
f01024eb:	6a 00                	push   $0x0
f01024ed:	53                   	push   %ebx
f01024ee:	ff 35 8c ce 22 f0    	pushl  0xf022ce8c
f01024f4:	e8 d5 ea ff ff       	call   f0100fce <pgdir_walk>
f01024f9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f01024ff:	83 c4 0c             	add    $0xc,%esp
f0102502:	6a 00                	push   $0x0
f0102504:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102507:	ff 35 8c ce 22 f0    	pushl  0xf022ce8c
f010250d:	e8 bc ea ff ff       	call   f0100fce <pgdir_walk>
f0102512:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f0102518:	83 c4 0c             	add    $0xc,%esp
f010251b:	6a 00                	push   $0x0
f010251d:	56                   	push   %esi
f010251e:	ff 35 8c ce 22 f0    	pushl  0xf022ce8c
f0102524:	e8 a5 ea ff ff       	call   f0100fce <pgdir_walk>
f0102529:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f010252f:	c7 04 24 8a 6e 10 f0 	movl   $0xf0106e8a,(%esp)
f0102536:	e8 1f 11 00 00       	call   f010365a <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U | PTE_P);
f010253b:	a1 90 ce 22 f0       	mov    0xf022ce90,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102540:	83 c4 10             	add    $0x10,%esp
f0102543:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102548:	77 15                	ja     f010255f <mem_init+0x12c7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010254a:	50                   	push   %eax
f010254b:	68 28 66 10 f0       	push   $0xf0106628
f0102550:	68 cc 00 00 00       	push   $0xcc
f0102555:	68 c1 6b 10 f0       	push   $0xf0106bc1
f010255a:	e8 e1 da ff ff       	call   f0100040 <_panic>
f010255f:	83 ec 08             	sub    $0x8,%esp
f0102562:	6a 05                	push   $0x5
f0102564:	05 00 00 00 10       	add    $0x10000000,%eax
f0102569:	50                   	push   %eax
f010256a:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010256f:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102574:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102579:	e8 1d eb ff ff       	call   f010109b <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS , PTSIZE , PADDR(envs), PTE_U | PTE_P);
f010257e:	a1 48 c2 22 f0       	mov    0xf022c248,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102583:	83 c4 10             	add    $0x10,%esp
f0102586:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010258b:	77 15                	ja     f01025a2 <mem_init+0x130a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010258d:	50                   	push   %eax
f010258e:	68 28 66 10 f0       	push   $0xf0106628
f0102593:	68 d5 00 00 00       	push   $0xd5
f0102598:	68 c1 6b 10 f0       	push   $0xf0106bc1
f010259d:	e8 9e da ff ff       	call   f0100040 <_panic>
f01025a2:	83 ec 08             	sub    $0x8,%esp
f01025a5:	6a 05                	push   $0x5
f01025a7:	05 00 00 00 10       	add    $0x10000000,%eax
f01025ac:	50                   	push   %eax
f01025ad:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01025b2:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01025b7:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f01025bc:	e8 da ea ff ff       	call   f010109b <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025c1:	83 c4 10             	add    $0x10,%esp
f01025c4:	b8 00 70 11 f0       	mov    $0xf0117000,%eax
f01025c9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01025ce:	77 15                	ja     f01025e5 <mem_init+0x134d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01025d0:	50                   	push   %eax
f01025d1:	68 28 66 10 f0       	push   $0xf0106628
f01025d6:	68 e2 00 00 00       	push   $0xe2
f01025db:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01025e0:	e8 5b da ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W | PTE_P);
f01025e5:	83 ec 08             	sub    $0x8,%esp
f01025e8:	6a 03                	push   $0x3
f01025ea:	68 00 70 11 00       	push   $0x117000
f01025ef:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01025f4:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01025f9:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f01025fe:	e8 98 ea ff ff       	call   f010109b <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff-KERNBASE, 0, PTE_W | PTE_P);
f0102603:	83 c4 08             	add    $0x8,%esp
f0102606:	6a 03                	push   $0x3
f0102608:	6a 00                	push   $0x0
f010260a:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f010260f:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102614:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102619:	e8 7d ea ff ff       	call   f010109b <boot_map_region>
f010261e:	c7 45 c4 00 e0 22 f0 	movl   $0xf022e000,-0x3c(%ebp)
f0102625:	83 c4 10             	add    $0x10,%esp
f0102628:	bb 00 e0 22 f0       	mov    $0xf022e000,%ebx
f010262d:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102632:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102638:	77 15                	ja     f010264f <mem_init+0x13b7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010263a:	53                   	push   %ebx
f010263b:	68 28 66 10 f0       	push   $0xf0106628
f0102640:	68 28 01 00 00       	push   $0x128
f0102645:	68 c1 6b 10 f0       	push   $0xf0106bc1
f010264a:	e8 f1 d9 ff ff       	call   f0100040 <_panic>
	//
	// LAB 4: Your code here:
	int i;
	for (i = 0; i < NCPU; i++) {
		intptr_t kstacktop_i = KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
		boot_map_region(kern_pgdir, kstacktop_i - KSTKSIZE, KSTKSIZE, 
f010264f:	83 ec 08             	sub    $0x8,%esp
f0102652:	6a 03                	push   $0x3
f0102654:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f010265a:	50                   	push   %eax
f010265b:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102660:	89 f2                	mov    %esi,%edx
f0102662:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102667:	e8 2f ea ff ff       	call   f010109b <boot_map_region>
f010266c:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f0102672:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	//             Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:
	int i;
	for (i = 0; i < NCPU; i++) {
f0102678:	83 c4 10             	add    $0x10,%esp
f010267b:	b8 00 e0 26 f0       	mov    $0xf026e000,%eax
f0102680:	39 d8                	cmp    %ebx,%eax
f0102682:	75 ae                	jne    f0102632 <mem_init+0x139a>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102684:	8b 3d 8c ce 22 f0    	mov    0xf022ce8c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010268a:	a1 88 ce 22 f0       	mov    0xf022ce88,%eax
f010268f:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102692:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102699:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010269e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01026a1:	8b 35 90 ce 22 f0    	mov    0xf022ce90,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026a7:	89 75 d0             	mov    %esi,-0x30(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01026aa:	bb 00 00 00 00       	mov    $0x0,%ebx
f01026af:	eb 55                	jmp    f0102706 <mem_init+0x146e>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01026b1:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f01026b7:	89 f8                	mov    %edi,%eax
f01026b9:	e8 27 e4 ff ff       	call   f0100ae5 <check_va2pa>
f01026be:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01026c5:	77 15                	ja     f01026dc <mem_init+0x1444>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026c7:	56                   	push   %esi
f01026c8:	68 28 66 10 f0       	push   $0xf0106628
f01026cd:	68 84 03 00 00       	push   $0x384
f01026d2:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01026d7:	e8 64 d9 ff ff       	call   f0100040 <_panic>
f01026dc:	8d 94 1e 00 00 00 10 	lea    0x10000000(%esi,%ebx,1),%edx
f01026e3:	39 c2                	cmp    %eax,%edx
f01026e5:	74 19                	je     f0102700 <mem_init+0x1468>
f01026e7:	68 4c 76 10 f0       	push   $0xf010764c
f01026ec:	68 e7 6b 10 f0       	push   $0xf0106be7
f01026f1:	68 84 03 00 00       	push   $0x384
f01026f6:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01026fb:	e8 40 d9 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102700:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102706:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102709:	77 a6                	ja     f01026b1 <mem_init+0x1419>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f010270b:	8b 35 48 c2 22 f0    	mov    0xf022c248,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102711:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0102714:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f0102719:	89 da                	mov    %ebx,%edx
f010271b:	89 f8                	mov    %edi,%eax
f010271d:	e8 c3 e3 ff ff       	call   f0100ae5 <check_va2pa>
f0102722:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f0102729:	77 15                	ja     f0102740 <mem_init+0x14a8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010272b:	56                   	push   %esi
f010272c:	68 28 66 10 f0       	push   $0xf0106628
f0102731:	68 89 03 00 00       	push   $0x389
f0102736:	68 c1 6b 10 f0       	push   $0xf0106bc1
f010273b:	e8 00 d9 ff ff       	call   f0100040 <_panic>
f0102740:	8d 94 1e 00 00 40 21 	lea    0x21400000(%esi,%ebx,1),%edx
f0102747:	39 d0                	cmp    %edx,%eax
f0102749:	74 19                	je     f0102764 <mem_init+0x14cc>
f010274b:	68 80 76 10 f0       	push   $0xf0107680
f0102750:	68 e7 6b 10 f0       	push   $0xf0106be7
f0102755:	68 89 03 00 00       	push   $0x389
f010275a:	68 c1 6b 10 f0       	push   $0xf0106bc1
f010275f:	e8 dc d8 ff ff       	call   f0100040 <_panic>
f0102764:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010276a:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f0102770:	75 a7                	jne    f0102719 <mem_init+0x1481>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102772:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0102775:	c1 e6 0c             	shl    $0xc,%esi
f0102778:	bb 00 00 00 00       	mov    $0x0,%ebx
f010277d:	eb 30                	jmp    f01027af <mem_init+0x1517>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010277f:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102785:	89 f8                	mov    %edi,%eax
f0102787:	e8 59 e3 ff ff       	call   f0100ae5 <check_va2pa>
f010278c:	39 c3                	cmp    %eax,%ebx
f010278e:	74 19                	je     f01027a9 <mem_init+0x1511>
f0102790:	68 b4 76 10 f0       	push   $0xf01076b4
f0102795:	68 e7 6b 10 f0       	push   $0xf0106be7
f010279a:	68 8d 03 00 00       	push   $0x38d
f010279f:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01027a4:	e8 97 d8 ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01027a9:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01027af:	39 f3                	cmp    %esi,%ebx
f01027b1:	72 cc                	jb     f010277f <mem_init+0x14e7>
f01027b3:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f01027b8:	89 75 cc             	mov    %esi,-0x34(%ebp)
f01027bb:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01027be:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01027c1:	8d 88 00 80 00 00    	lea    0x8000(%eax),%ecx
f01027c7:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f01027ca:	89 c3                	mov    %eax,%ebx
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f01027cc:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01027cf:	05 00 80 00 20       	add    $0x20008000,%eax
f01027d4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01027d7:	89 da                	mov    %ebx,%edx
f01027d9:	89 f8                	mov    %edi,%eax
f01027db:	e8 05 e3 ff ff       	call   f0100ae5 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01027e0:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f01027e6:	77 15                	ja     f01027fd <mem_init+0x1565>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01027e8:	56                   	push   %esi
f01027e9:	68 28 66 10 f0       	push   $0xf0106628
f01027ee:	68 95 03 00 00       	push   $0x395
f01027f3:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01027f8:	e8 43 d8 ff ff       	call   f0100040 <_panic>
f01027fd:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102800:	8d 94 0b 00 e0 22 f0 	lea    -0xfdd2000(%ebx,%ecx,1),%edx
f0102807:	39 d0                	cmp    %edx,%eax
f0102809:	74 19                	je     f0102824 <mem_init+0x158c>
f010280b:	68 dc 76 10 f0       	push   $0xf01076dc
f0102810:	68 e7 6b 10 f0       	push   $0xf0106be7
f0102815:	68 95 03 00 00       	push   $0x395
f010281a:	68 c1 6b 10 f0       	push   $0xf0106bc1
f010281f:	e8 1c d8 ff ff       	call   f0100040 <_panic>
f0102824:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010282a:	3b 5d d0             	cmp    -0x30(%ebp),%ebx
f010282d:	75 a8                	jne    f01027d7 <mem_init+0x153f>
f010282f:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102832:	8d 98 00 80 ff ff    	lea    -0x8000(%eax),%ebx
f0102838:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f010283b:	89 c6                	mov    %eax,%esi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f010283d:	89 da                	mov    %ebx,%edx
f010283f:	89 f8                	mov    %edi,%eax
f0102841:	e8 9f e2 ff ff       	call   f0100ae5 <check_va2pa>
f0102846:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102849:	74 19                	je     f0102864 <mem_init+0x15cc>
f010284b:	68 24 77 10 f0       	push   $0xf0107724
f0102850:	68 e7 6b 10 f0       	push   $0xf0106be7
f0102855:	68 97 03 00 00       	push   $0x397
f010285a:	68 c1 6b 10 f0       	push   $0xf0106bc1
f010285f:	e8 dc d7 ff ff       	call   f0100040 <_panic>
f0102864:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f010286a:	39 f3                	cmp    %esi,%ebx
f010286c:	75 cf                	jne    f010283d <mem_init+0x15a5>
f010286e:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102871:	81 6d cc 00 00 01 00 	subl   $0x10000,-0x34(%ebp)
f0102878:	81 45 c8 00 80 01 00 	addl   $0x18000,-0x38(%ebp)
f010287f:	81 c6 00 80 00 00    	add    $0x8000,%esi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f0102885:	b8 00 e0 26 f0       	mov    $0xf026e000,%eax
f010288a:	39 f0                	cmp    %esi,%eax
f010288c:	0f 85 2c ff ff ff    	jne    f01027be <mem_init+0x1526>
f0102892:	b8 00 00 00 00       	mov    $0x0,%eax
f0102897:	eb 2a                	jmp    f01028c3 <mem_init+0x162b>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102899:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f010289f:	83 fa 04             	cmp    $0x4,%edx
f01028a2:	77 1f                	ja     f01028c3 <mem_init+0x162b>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f01028a4:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f01028a8:	75 7e                	jne    f0102928 <mem_init+0x1690>
f01028aa:	68 a3 6e 10 f0       	push   $0xf0106ea3
f01028af:	68 e7 6b 10 f0       	push   $0xf0106be7
f01028b4:	68 a2 03 00 00       	push   $0x3a2
f01028b9:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01028be:	e8 7d d7 ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01028c3:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01028c8:	76 3f                	jbe    f0102909 <mem_init+0x1671>
				assert(pgdir[i] & PTE_P);
f01028ca:	8b 14 87             	mov    (%edi,%eax,4),%edx
f01028cd:	f6 c2 01             	test   $0x1,%dl
f01028d0:	75 19                	jne    f01028eb <mem_init+0x1653>
f01028d2:	68 a3 6e 10 f0       	push   $0xf0106ea3
f01028d7:	68 e7 6b 10 f0       	push   $0xf0106be7
f01028dc:	68 a6 03 00 00       	push   $0x3a6
f01028e1:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01028e6:	e8 55 d7 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f01028eb:	f6 c2 02             	test   $0x2,%dl
f01028ee:	75 38                	jne    f0102928 <mem_init+0x1690>
f01028f0:	68 b4 6e 10 f0       	push   $0xf0106eb4
f01028f5:	68 e7 6b 10 f0       	push   $0xf0106be7
f01028fa:	68 a7 03 00 00       	push   $0x3a7
f01028ff:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0102904:	e8 37 d7 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102909:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f010290d:	74 19                	je     f0102928 <mem_init+0x1690>
f010290f:	68 c5 6e 10 f0       	push   $0xf0106ec5
f0102914:	68 e7 6b 10 f0       	push   $0xf0106be7
f0102919:	68 a9 03 00 00       	push   $0x3a9
f010291e:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0102923:	e8 18 d7 ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102928:	83 c0 01             	add    $0x1,%eax
f010292b:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102930:	0f 86 63 ff ff ff    	jbe    f0102899 <mem_init+0x1601>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102936:	83 ec 0c             	sub    $0xc,%esp
f0102939:	68 48 77 10 f0       	push   $0xf0107748
f010293e:	e8 17 0d 00 00       	call   f010365a <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102943:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102948:	83 c4 10             	add    $0x10,%esp
f010294b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102950:	77 15                	ja     f0102967 <mem_init+0x16cf>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102952:	50                   	push   %eax
f0102953:	68 28 66 10 f0       	push   $0xf0106628
f0102958:	68 ff 00 00 00       	push   $0xff
f010295d:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0102962:	e8 d9 d6 ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102967:	05 00 00 00 10       	add    $0x10000000,%eax
f010296c:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f010296f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102974:	e8 d0 e1 ff ff       	call   f0100b49 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102979:	0f 20 c0             	mov    %cr0,%eax
f010297c:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f010297f:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102984:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102987:	83 ec 0c             	sub    $0xc,%esp
f010298a:	6a 00                	push   $0x0
f010298c:	e8 6b e5 ff ff       	call   f0100efc <page_alloc>
f0102991:	89 c3                	mov    %eax,%ebx
f0102993:	83 c4 10             	add    $0x10,%esp
f0102996:	85 c0                	test   %eax,%eax
f0102998:	75 19                	jne    f01029b3 <mem_init+0x171b>
f010299a:	68 af 6c 10 f0       	push   $0xf0106caf
f010299f:	68 e7 6b 10 f0       	push   $0xf0106be7
f01029a4:	68 81 04 00 00       	push   $0x481
f01029a9:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01029ae:	e8 8d d6 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01029b3:	83 ec 0c             	sub    $0xc,%esp
f01029b6:	6a 00                	push   $0x0
f01029b8:	e8 3f e5 ff ff       	call   f0100efc <page_alloc>
f01029bd:	89 c7                	mov    %eax,%edi
f01029bf:	83 c4 10             	add    $0x10,%esp
f01029c2:	85 c0                	test   %eax,%eax
f01029c4:	75 19                	jne    f01029df <mem_init+0x1747>
f01029c6:	68 c5 6c 10 f0       	push   $0xf0106cc5
f01029cb:	68 e7 6b 10 f0       	push   $0xf0106be7
f01029d0:	68 82 04 00 00       	push   $0x482
f01029d5:	68 c1 6b 10 f0       	push   $0xf0106bc1
f01029da:	e8 61 d6 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01029df:	83 ec 0c             	sub    $0xc,%esp
f01029e2:	6a 00                	push   $0x0
f01029e4:	e8 13 e5 ff ff       	call   f0100efc <page_alloc>
f01029e9:	89 c6                	mov    %eax,%esi
f01029eb:	83 c4 10             	add    $0x10,%esp
f01029ee:	85 c0                	test   %eax,%eax
f01029f0:	75 19                	jne    f0102a0b <mem_init+0x1773>
f01029f2:	68 db 6c 10 f0       	push   $0xf0106cdb
f01029f7:	68 e7 6b 10 f0       	push   $0xf0106be7
f01029fc:	68 83 04 00 00       	push   $0x483
f0102a01:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0102a06:	e8 35 d6 ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f0102a0b:	83 ec 0c             	sub    $0xc,%esp
f0102a0e:	53                   	push   %ebx
f0102a0f:	e8 58 e5 ff ff       	call   f0100f6c <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a14:	89 f8                	mov    %edi,%eax
f0102a16:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f0102a1c:	c1 f8 03             	sar    $0x3,%eax
f0102a1f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a22:	89 c2                	mov    %eax,%edx
f0102a24:	c1 ea 0c             	shr    $0xc,%edx
f0102a27:	83 c4 10             	add    $0x10,%esp
f0102a2a:	3b 15 88 ce 22 f0    	cmp    0xf022ce88,%edx
f0102a30:	72 12                	jb     f0102a44 <mem_init+0x17ac>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a32:	50                   	push   %eax
f0102a33:	68 04 66 10 f0       	push   $0xf0106604
f0102a38:	6a 58                	push   $0x58
f0102a3a:	68 cd 6b 10 f0       	push   $0xf0106bcd
f0102a3f:	e8 fc d5 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102a44:	83 ec 04             	sub    $0x4,%esp
f0102a47:	68 00 10 00 00       	push   $0x1000
f0102a4c:	6a 01                	push   $0x1
f0102a4e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a53:	50                   	push   %eax
f0102a54:	e8 c7 2e 00 00       	call   f0105920 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a59:	89 f0                	mov    %esi,%eax
f0102a5b:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f0102a61:	c1 f8 03             	sar    $0x3,%eax
f0102a64:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a67:	89 c2                	mov    %eax,%edx
f0102a69:	c1 ea 0c             	shr    $0xc,%edx
f0102a6c:	83 c4 10             	add    $0x10,%esp
f0102a6f:	3b 15 88 ce 22 f0    	cmp    0xf022ce88,%edx
f0102a75:	72 12                	jb     f0102a89 <mem_init+0x17f1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a77:	50                   	push   %eax
f0102a78:	68 04 66 10 f0       	push   $0xf0106604
f0102a7d:	6a 58                	push   $0x58
f0102a7f:	68 cd 6b 10 f0       	push   $0xf0106bcd
f0102a84:	e8 b7 d5 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102a89:	83 ec 04             	sub    $0x4,%esp
f0102a8c:	68 00 10 00 00       	push   $0x1000
f0102a91:	6a 02                	push   $0x2
f0102a93:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a98:	50                   	push   %eax
f0102a99:	e8 82 2e 00 00       	call   f0105920 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102a9e:	6a 02                	push   $0x2
f0102aa0:	68 00 10 00 00       	push   $0x1000
f0102aa5:	57                   	push   %edi
f0102aa6:	ff 35 8c ce 22 f0    	pushl  0xf022ce8c
f0102aac:	e8 1d e7 ff ff       	call   f01011ce <page_insert>
	assert(pp1->pp_ref == 1);
f0102ab1:	83 c4 20             	add    $0x20,%esp
f0102ab4:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102ab9:	74 19                	je     f0102ad4 <mem_init+0x183c>
f0102abb:	68 ac 6d 10 f0       	push   $0xf0106dac
f0102ac0:	68 e7 6b 10 f0       	push   $0xf0106be7
f0102ac5:	68 88 04 00 00       	push   $0x488
f0102aca:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0102acf:	e8 6c d5 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102ad4:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102adb:	01 01 01 
f0102ade:	74 19                	je     f0102af9 <mem_init+0x1861>
f0102ae0:	68 68 77 10 f0       	push   $0xf0107768
f0102ae5:	68 e7 6b 10 f0       	push   $0xf0106be7
f0102aea:	68 89 04 00 00       	push   $0x489
f0102aef:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0102af4:	e8 47 d5 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102af9:	6a 02                	push   $0x2
f0102afb:	68 00 10 00 00       	push   $0x1000
f0102b00:	56                   	push   %esi
f0102b01:	ff 35 8c ce 22 f0    	pushl  0xf022ce8c
f0102b07:	e8 c2 e6 ff ff       	call   f01011ce <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102b0c:	83 c4 10             	add    $0x10,%esp
f0102b0f:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102b16:	02 02 02 
f0102b19:	74 19                	je     f0102b34 <mem_init+0x189c>
f0102b1b:	68 8c 77 10 f0       	push   $0xf010778c
f0102b20:	68 e7 6b 10 f0       	push   $0xf0106be7
f0102b25:	68 8b 04 00 00       	push   $0x48b
f0102b2a:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0102b2f:	e8 0c d5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102b34:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102b39:	74 19                	je     f0102b54 <mem_init+0x18bc>
f0102b3b:	68 ce 6d 10 f0       	push   $0xf0106dce
f0102b40:	68 e7 6b 10 f0       	push   $0xf0106be7
f0102b45:	68 8c 04 00 00       	push   $0x48c
f0102b4a:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0102b4f:	e8 ec d4 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102b54:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102b59:	74 19                	je     f0102b74 <mem_init+0x18dc>
f0102b5b:	68 38 6e 10 f0       	push   $0xf0106e38
f0102b60:	68 e7 6b 10 f0       	push   $0xf0106be7
f0102b65:	68 8d 04 00 00       	push   $0x48d
f0102b6a:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0102b6f:	e8 cc d4 ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102b74:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102b7b:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b7e:	89 f0                	mov    %esi,%eax
f0102b80:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f0102b86:	c1 f8 03             	sar    $0x3,%eax
f0102b89:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b8c:	89 c2                	mov    %eax,%edx
f0102b8e:	c1 ea 0c             	shr    $0xc,%edx
f0102b91:	3b 15 88 ce 22 f0    	cmp    0xf022ce88,%edx
f0102b97:	72 12                	jb     f0102bab <mem_init+0x1913>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b99:	50                   	push   %eax
f0102b9a:	68 04 66 10 f0       	push   $0xf0106604
f0102b9f:	6a 58                	push   $0x58
f0102ba1:	68 cd 6b 10 f0       	push   $0xf0106bcd
f0102ba6:	e8 95 d4 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102bab:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102bb2:	03 03 03 
f0102bb5:	74 19                	je     f0102bd0 <mem_init+0x1938>
f0102bb7:	68 b0 77 10 f0       	push   $0xf01077b0
f0102bbc:	68 e7 6b 10 f0       	push   $0xf0106be7
f0102bc1:	68 8f 04 00 00       	push   $0x48f
f0102bc6:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0102bcb:	e8 70 d4 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102bd0:	83 ec 08             	sub    $0x8,%esp
f0102bd3:	68 00 10 00 00       	push   $0x1000
f0102bd8:	ff 35 8c ce 22 f0    	pushl  0xf022ce8c
f0102bde:	e8 a5 e5 ff ff       	call   f0101188 <page_remove>
	assert(pp2->pp_ref == 0);
f0102be3:	83 c4 10             	add    $0x10,%esp
f0102be6:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102beb:	74 19                	je     f0102c06 <mem_init+0x196e>
f0102bed:	68 06 6e 10 f0       	push   $0xf0106e06
f0102bf2:	68 e7 6b 10 f0       	push   $0xf0106be7
f0102bf7:	68 91 04 00 00       	push   $0x491
f0102bfc:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0102c01:	e8 3a d4 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102c06:	8b 0d 8c ce 22 f0    	mov    0xf022ce8c,%ecx
f0102c0c:	8b 11                	mov    (%ecx),%edx
f0102c0e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102c14:	89 d8                	mov    %ebx,%eax
f0102c16:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f0102c1c:	c1 f8 03             	sar    $0x3,%eax
f0102c1f:	c1 e0 0c             	shl    $0xc,%eax
f0102c22:	39 c2                	cmp    %eax,%edx
f0102c24:	74 19                	je     f0102c3f <mem_init+0x19a7>
f0102c26:	68 38 71 10 f0       	push   $0xf0107138
f0102c2b:	68 e7 6b 10 f0       	push   $0xf0106be7
f0102c30:	68 94 04 00 00       	push   $0x494
f0102c35:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0102c3a:	e8 01 d4 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102c3f:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102c45:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102c4a:	74 19                	je     f0102c65 <mem_init+0x19cd>
f0102c4c:	68 bd 6d 10 f0       	push   $0xf0106dbd
f0102c51:	68 e7 6b 10 f0       	push   $0xf0106be7
f0102c56:	68 96 04 00 00       	push   $0x496
f0102c5b:	68 c1 6b 10 f0       	push   $0xf0106bc1
f0102c60:	e8 db d3 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102c65:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102c6b:	83 ec 0c             	sub    $0xc,%esp
f0102c6e:	53                   	push   %ebx
f0102c6f:	e8 f8 e2 ff ff       	call   f0100f6c <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102c74:	c7 04 24 dc 77 10 f0 	movl   $0xf01077dc,(%esp)
f0102c7b:	e8 da 09 00 00       	call   f010365a <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102c80:	83 c4 10             	add    $0x10,%esp
f0102c83:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102c86:	5b                   	pop    %ebx
f0102c87:	5e                   	pop    %esi
f0102c88:	5f                   	pop    %edi
f0102c89:	5d                   	pop    %ebp
f0102c8a:	c3                   	ret    

f0102c8b <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102c8b:	55                   	push   %ebp
f0102c8c:	89 e5                	mov    %esp,%ebp
f0102c8e:	57                   	push   %edi
f0102c8f:	56                   	push   %esi
f0102c90:	53                   	push   %ebx
f0102c91:	83 ec 1c             	sub    $0x1c,%esp
f0102c94:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	pde_t*  now;
	perm |= PTE_P;
f0102c97:	8b 75 14             	mov    0x14(%ebp),%esi
f0102c9a:	83 ce 01             	or     $0x1,%esi
	int l = 1;
	uint32_t begin = ROUNDDOWN((uint32_t) va, PGSIZE);
f0102c9d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102ca0:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uint32_t end = ROUNDUP((uint32_t)(va) + len, PGSIZE);
f0102ca6:	8b 45 10             	mov    0x10(%ebp),%eax
f0102ca9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102cac:	8d 84 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%eax
f0102cb3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102cb8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
	// LAB 3: Your code here.
	pde_t*  now;
	perm |= PTE_P;
	int l = 1;
f0102cbb:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
	uint32_t begin = ROUNDDOWN((uint32_t) va, PGSIZE);
	uint32_t end = ROUNDUP((uint32_t)(va) + len, PGSIZE);
	for (; begin != end; begin += PGSIZE) {
f0102cc2:	eb 5c                	jmp    f0102d20 <user_mem_check+0x95>
		if (begin >= ULIM) { 
f0102cc4:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102cca:	76 15                	jbe    f0102ce1 <user_mem_check+0x56>
			if (l) begin = (uint32_t) va;
f0102ccc:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102cd0:	0f 45 5d 0c          	cmovne 0xc(%ebp),%ebx
			user_mem_check_addr = begin; 
f0102cd4:	89 1d 3c c2 22 f0    	mov    %ebx,0xf022c23c
			return -E_FAULT;
f0102cda:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102cdf:	eb 49                	jmp    f0102d2a <user_mem_check+0x9f>
		}
		now = pgdir_walk(env->env_pgdir, (void*)begin, 0);
f0102ce1:	83 ec 04             	sub    $0x4,%esp
f0102ce4:	6a 00                	push   $0x0
f0102ce6:	53                   	push   %ebx
f0102ce7:	ff 77 60             	pushl  0x60(%edi)
f0102cea:	e8 df e2 ff ff       	call   f0100fce <pgdir_walk>
		if (now == NULL || (*now & perm) != perm) {
f0102cef:	83 c4 10             	add    $0x10,%esp
f0102cf2:	85 c0                	test   %eax,%eax
f0102cf4:	74 08                	je     f0102cfe <user_mem_check+0x73>
f0102cf6:	89 f2                	mov    %esi,%edx
f0102cf8:	23 10                	and    (%eax),%edx
f0102cfa:	39 d6                	cmp    %edx,%esi
f0102cfc:	74 15                	je     f0102d13 <user_mem_check+0x88>
			if (l) begin = (uint32_t) va;
f0102cfe:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102d02:	0f 45 5d 0c          	cmovne 0xc(%ebp),%ebx
			user_mem_check_addr = begin;
f0102d06:	89 1d 3c c2 22 f0    	mov    %ebx,0xf022c23c
			return -E_FAULT;
f0102d0c:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102d11:	eb 17                	jmp    f0102d2a <user_mem_check+0x9f>
	pde_t*  now;
	perm |= PTE_P;
	int l = 1;
	uint32_t begin = ROUNDDOWN((uint32_t) va, PGSIZE);
	uint32_t end = ROUNDUP((uint32_t)(va) + len, PGSIZE);
	for (; begin != end; begin += PGSIZE) {
f0102d13:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		if (now == NULL || (*now & perm) != perm) {
			if (l) begin = (uint32_t) va;
			user_mem_check_addr = begin;
			return -E_FAULT;
		}
		l = 0;
f0102d19:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	pde_t*  now;
	perm |= PTE_P;
	int l = 1;
	uint32_t begin = ROUNDDOWN((uint32_t) va, PGSIZE);
	uint32_t end = ROUNDUP((uint32_t)(va) + len, PGSIZE);
	for (; begin != end; begin += PGSIZE) {
f0102d20:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102d23:	75 9f                	jne    f0102cc4 <user_mem_check+0x39>
		}
		l = 0;
	}


	return 0;
f0102d25:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102d2a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d2d:	5b                   	pop    %ebx
f0102d2e:	5e                   	pop    %esi
f0102d2f:	5f                   	pop    %edi
f0102d30:	5d                   	pop    %ebp
f0102d31:	c3                   	ret    

f0102d32 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102d32:	55                   	push   %ebp
f0102d33:	89 e5                	mov    %esp,%ebp
f0102d35:	53                   	push   %ebx
f0102d36:	83 ec 04             	sub    $0x4,%esp
f0102d39:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102d3c:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d3f:	83 c8 04             	or     $0x4,%eax
f0102d42:	50                   	push   %eax
f0102d43:	ff 75 10             	pushl  0x10(%ebp)
f0102d46:	ff 75 0c             	pushl  0xc(%ebp)
f0102d49:	53                   	push   %ebx
f0102d4a:	e8 3c ff ff ff       	call   f0102c8b <user_mem_check>
f0102d4f:	83 c4 10             	add    $0x10,%esp
f0102d52:	85 c0                	test   %eax,%eax
f0102d54:	79 21                	jns    f0102d77 <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102d56:	83 ec 04             	sub    $0x4,%esp
f0102d59:	ff 35 3c c2 22 f0    	pushl  0xf022c23c
f0102d5f:	ff 73 48             	pushl  0x48(%ebx)
f0102d62:	68 08 78 10 f0       	push   $0xf0107808
f0102d67:	e8 ee 08 00 00       	call   f010365a <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102d6c:	89 1c 24             	mov    %ebx,(%esp)
f0102d6f:	e8 11 06 00 00       	call   f0103385 <env_destroy>
f0102d74:	83 c4 10             	add    $0x10,%esp
	}
}
f0102d77:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102d7a:	c9                   	leave  
f0102d7b:	c3                   	ret    

f0102d7c <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102d7c:	55                   	push   %ebp
f0102d7d:	89 e5                	mov    %esp,%ebp
f0102d7f:	57                   	push   %edi
f0102d80:	56                   	push   %esi
f0102d81:	53                   	push   %ebx
f0102d82:	83 ec 0c             	sub    $0xc,%esp
f0102d85:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void *end = ROUNDUP(va+len, PGSIZE); 
f0102d87:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102d8e:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	void *start = ROUNDDOWN(va, PGSIZE);
f0102d94:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102d9a:	89 d3                	mov    %edx,%ebx
	struct PageInfo *pp = NULL;
	for(start; start< end; start += PGSIZE){
f0102d9c:	eb 3d                	jmp    f0102ddb <region_alloc+0x5f>
		pp = page_alloc(0);
f0102d9e:	83 ec 0c             	sub    $0xc,%esp
f0102da1:	6a 00                	push   $0x0
f0102da3:	e8 54 e1 ff ff       	call   f0100efc <page_alloc>
		if(pp == NULL)	panic("kern/env.c:line 291: region_alloc-Out Of Memory in region_alloc from page_alloc() function call");
f0102da8:	83 c4 10             	add    $0x10,%esp
f0102dab:	85 c0                	test   %eax,%eax
f0102dad:	75 17                	jne    f0102dc6 <region_alloc+0x4a>
f0102daf:	83 ec 04             	sub    $0x4,%esp
f0102db2:	68 40 78 10 f0       	push   $0xf0107840
f0102db7:	68 2e 01 00 00       	push   $0x12e
f0102dbc:	68 c3 78 10 f0       	push   $0xf01078c3
f0102dc1:	e8 7a d2 ff ff       	call   f0100040 <_panic>
		page_insert(e->env_pgdir, pp, start, PTE_W | PTE_U | PTE_P );
f0102dc6:	6a 07                	push   $0x7
f0102dc8:	53                   	push   %ebx
f0102dc9:	50                   	push   %eax
f0102dca:	ff 77 60             	pushl  0x60(%edi)
f0102dcd:	e8 fc e3 ff ff       	call   f01011ce <page_insert>
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void *end = ROUNDUP(va+len, PGSIZE); 
	void *start = ROUNDDOWN(va, PGSIZE);
	struct PageInfo *pp = NULL;
	for(start; start< end; start += PGSIZE){
f0102dd2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102dd8:	83 c4 10             	add    $0x10,%esp
f0102ddb:	39 f3                	cmp    %esi,%ebx
f0102ddd:	72 bf                	jb     f0102d9e <region_alloc+0x22>
		pp = page_alloc(0);
		if(pp == NULL)	panic("kern/env.c:line 291: region_alloc-Out Of Memory in region_alloc from page_alloc() function call");
		page_insert(e->env_pgdir, pp, start, PTE_W | PTE_U | PTE_P );
	}
}
f0102ddf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102de2:	5b                   	pop    %ebx
f0102de3:	5e                   	pop    %esi
f0102de4:	5f                   	pop    %edi
f0102de5:	5d                   	pop    %ebp
f0102de6:	c3                   	ret    

f0102de7 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102de7:	55                   	push   %ebp
f0102de8:	89 e5                	mov    %esp,%ebp
f0102dea:	56                   	push   %esi
f0102deb:	53                   	push   %ebx
f0102dec:	8b 45 08             	mov    0x8(%ebp),%eax
f0102def:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102df2:	85 c0                	test   %eax,%eax
f0102df4:	75 1a                	jne    f0102e10 <envid2env+0x29>
		*env_store = curenv;
f0102df6:	e8 47 31 00 00       	call   f0105f42 <cpunum>
f0102dfb:	6b c0 74             	imul   $0x74,%eax,%eax
f0102dfe:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0102e04:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102e07:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102e09:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e0e:	eb 70                	jmp    f0102e80 <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102e10:	89 c3                	mov    %eax,%ebx
f0102e12:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0102e18:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0102e1b:	03 1d 48 c2 22 f0    	add    0xf022c248,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102e21:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0102e25:	74 05                	je     f0102e2c <envid2env+0x45>
f0102e27:	3b 43 48             	cmp    0x48(%ebx),%eax
f0102e2a:	74 10                	je     f0102e3c <envid2env+0x55>
		*env_store = 0;
f0102e2c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e2f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102e35:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102e3a:	eb 44                	jmp    f0102e80 <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102e3c:	84 d2                	test   %dl,%dl
f0102e3e:	74 36                	je     f0102e76 <envid2env+0x8f>
f0102e40:	e8 fd 30 00 00       	call   f0105f42 <cpunum>
f0102e45:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e48:	3b 98 28 d0 22 f0    	cmp    -0xfdd2fd8(%eax),%ebx
f0102e4e:	74 26                	je     f0102e76 <envid2env+0x8f>
f0102e50:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0102e53:	e8 ea 30 00 00       	call   f0105f42 <cpunum>
f0102e58:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e5b:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0102e61:	3b 70 48             	cmp    0x48(%eax),%esi
f0102e64:	74 10                	je     f0102e76 <envid2env+0x8f>
		*env_store = 0;
f0102e66:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e69:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102e6f:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102e74:	eb 0a                	jmp    f0102e80 <envid2env+0x99>
	}

	*env_store = e;
f0102e76:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e79:	89 18                	mov    %ebx,(%eax)
	return 0;
f0102e7b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102e80:	5b                   	pop    %ebx
f0102e81:	5e                   	pop    %esi
f0102e82:	5d                   	pop    %ebp
f0102e83:	c3                   	ret    

f0102e84 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102e84:	55                   	push   %ebp
f0102e85:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f0102e87:	b8 20 13 12 f0       	mov    $0xf0121320,%eax
f0102e8c:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0102e8f:	b8 23 00 00 00       	mov    $0x23,%eax
f0102e94:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f0102e96:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f0102e98:	b8 10 00 00 00       	mov    $0x10,%eax
f0102e9d:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f0102e9f:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f0102ea1:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f0102ea3:	ea aa 2e 10 f0 08 00 	ljmp   $0x8,$0xf0102eaa
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f0102eaa:	b8 00 00 00 00       	mov    $0x0,%eax
f0102eaf:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102eb2:	5d                   	pop    %ebp
f0102eb3:	c3                   	ret    

f0102eb4 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102eb4:	55                   	push   %ebp
f0102eb5:	89 e5                	mov    %esp,%ebp
f0102eb7:	56                   	push   %esi
f0102eb8:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	int i = NENV-1;

	while(i >= 0){
	envs[i].env_status = ENV_FREE;
f0102eb9:	8b 35 48 c2 22 f0    	mov    0xf022c248,%esi
f0102ebf:	8b 15 4c c2 22 f0    	mov    0xf022c24c,%edx
f0102ec5:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f0102ecb:	8d 5e 84             	lea    -0x7c(%esi),%ebx
f0102ece:	89 c1                	mov    %eax,%ecx
f0102ed0:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
	envs[i].env_id = 0;
f0102ed7:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
	envs[i].env_link = env_free_list;
f0102ede:	89 50 44             	mov    %edx,0x44(%eax)
f0102ee1:	83 e8 7c             	sub    $0x7c,%eax
	env_free_list = &envs[i];
f0102ee4:	89 ca                	mov    %ecx,%edx
{
	// Set up envs array
	// LAB 3: Your code here.
	int i = NENV-1;

	while(i >= 0){
f0102ee6:	39 d8                	cmp    %ebx,%eax
f0102ee8:	75 e4                	jne    f0102ece <env_init+0x1a>
f0102eea:	89 35 4c c2 22 f0    	mov    %esi,0xf022c24c
	env_free_list = &envs[i];
	i--;
	}

	// Per-CPU part of the initialization
	env_init_percpu();
f0102ef0:	e8 8f ff ff ff       	call   f0102e84 <env_init_percpu>
}
f0102ef5:	5b                   	pop    %ebx
f0102ef6:	5e                   	pop    %esi
f0102ef7:	5d                   	pop    %ebp
f0102ef8:	c3                   	ret    

f0102ef9 <env_alloc>:
//	-E_NO_FREE_ENV if all NENV environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102ef9:	55                   	push   %ebp
f0102efa:	89 e5                	mov    %esp,%ebp
f0102efc:	53                   	push   %ebx
f0102efd:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102f00:	8b 1d 4c c2 22 f0    	mov    0xf022c24c,%ebx
f0102f06:	85 db                	test   %ebx,%ebx
f0102f08:	0f 84 62 01 00 00    	je     f0103070 <env_alloc+0x177>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102f0e:	83 ec 0c             	sub    $0xc,%esp
f0102f11:	6a 01                	push   $0x1
f0102f13:	e8 e4 df ff ff       	call   f0100efc <page_alloc>
f0102f18:	83 c4 10             	add    $0x10,%esp
f0102f1b:	85 c0                	test   %eax,%eax
f0102f1d:	0f 84 54 01 00 00    	je     f0103077 <env_alloc+0x17e>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f0102f23:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102f28:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f0102f2e:	c1 f8 03             	sar    $0x3,%eax
f0102f31:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102f34:	89 c2                	mov    %eax,%edx
f0102f36:	c1 ea 0c             	shr    $0xc,%edx
f0102f39:	3b 15 88 ce 22 f0    	cmp    0xf022ce88,%edx
f0102f3f:	72 12                	jb     f0102f53 <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102f41:	50                   	push   %eax
f0102f42:	68 04 66 10 f0       	push   $0xf0106604
f0102f47:	6a 58                	push   $0x58
f0102f49:	68 cd 6b 10 f0       	push   $0xf0106bcd
f0102f4e:	e8 ed d0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102f53:	2d 00 00 00 10       	sub    $0x10000000,%eax
	e->env_pgdir = (pde_t *)page2kva(p);
f0102f58:	89 43 60             	mov    %eax,0x60(%ebx)
	/*for(int i =0; i < NPDENTRIES; i++){
	e->env_pgdir[i] = kern_pgdir[i];
	}*/
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f0102f5b:	83 ec 04             	sub    $0x4,%esp
f0102f5e:	68 00 10 00 00       	push   $0x1000
f0102f63:	ff 35 8c ce 22 f0    	pushl  0xf022ce8c
f0102f69:	50                   	push   %eax
f0102f6a:	e8 66 2a 00 00       	call   f01059d5 <memcpy>

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102f6f:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f72:	83 c4 10             	add    $0x10,%esp
f0102f75:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102f7a:	77 15                	ja     f0102f91 <env_alloc+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f7c:	50                   	push   %eax
f0102f7d:	68 28 66 10 f0       	push   $0xf0106628
f0102f82:	68 cb 00 00 00       	push   $0xcb
f0102f87:	68 c3 78 10 f0       	push   $0xf01078c3
f0102f8c:	e8 af d0 ff ff       	call   f0100040 <_panic>
f0102f91:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102f97:	83 ca 05             	or     $0x5,%edx
f0102f9a:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102fa0:	8b 43 48             	mov    0x48(%ebx),%eax
f0102fa3:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102fa8:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102fad:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102fb2:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102fb5:	89 da                	mov    %ebx,%edx
f0102fb7:	2b 15 48 c2 22 f0    	sub    0xf022c248,%edx
f0102fbd:	c1 fa 02             	sar    $0x2,%edx
f0102fc0:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f0102fc6:	09 d0                	or     %edx,%eax
f0102fc8:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102fcb:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102fce:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102fd1:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102fd8:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102fdf:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102fe6:	83 ec 04             	sub    $0x4,%esp
f0102fe9:	6a 44                	push   $0x44
f0102feb:	6a 00                	push   $0x0
f0102fed:	53                   	push   %ebx
f0102fee:	e8 2d 29 00 00       	call   f0105920 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102ff3:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102ff9:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102fff:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0103005:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f010300c:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f0103012:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f0103019:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f010301d:	8b 43 44             	mov    0x44(%ebx),%eax
f0103020:	a3 4c c2 22 f0       	mov    %eax,0xf022c24c
	*newenv_store = e;
f0103025:	8b 45 08             	mov    0x8(%ebp),%eax
f0103028:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f010302a:	8b 5b 48             	mov    0x48(%ebx),%ebx
f010302d:	e8 10 2f 00 00       	call   f0105f42 <cpunum>
f0103032:	6b c0 74             	imul   $0x74,%eax,%eax
f0103035:	83 c4 10             	add    $0x10,%esp
f0103038:	ba 00 00 00 00       	mov    $0x0,%edx
f010303d:	83 b8 28 d0 22 f0 00 	cmpl   $0x0,-0xfdd2fd8(%eax)
f0103044:	74 11                	je     f0103057 <env_alloc+0x15e>
f0103046:	e8 f7 2e 00 00       	call   f0105f42 <cpunum>
f010304b:	6b c0 74             	imul   $0x74,%eax,%eax
f010304e:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103054:	8b 50 48             	mov    0x48(%eax),%edx
f0103057:	83 ec 04             	sub    $0x4,%esp
f010305a:	53                   	push   %ebx
f010305b:	52                   	push   %edx
f010305c:	68 ce 78 10 f0       	push   $0xf01078ce
f0103061:	e8 f4 05 00 00       	call   f010365a <cprintf>
	return 0;
f0103066:	83 c4 10             	add    $0x10,%esp
f0103069:	b8 00 00 00 00       	mov    $0x0,%eax
f010306e:	eb 0c                	jmp    f010307c <env_alloc+0x183>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103070:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103075:	eb 05                	jmp    f010307c <env_alloc+0x183>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0103077:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f010307c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010307f:	c9                   	leave  
f0103080:	c3                   	ret    

f0103081 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103081:	55                   	push   %ebp
f0103082:	89 e5                	mov    %esp,%ebp
f0103084:	57                   	push   %edi
f0103085:	56                   	push   %esi
f0103086:	53                   	push   %ebx
f0103087:	83 ec 34             	sub    $0x34,%esp
f010308a:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env * e;
	if( env_alloc(&e,0) < 0)	panic("env_alloc() failed at env_create()");
f010308d:	6a 00                	push   $0x0
f010308f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0103092:	50                   	push   %eax
f0103093:	e8 61 fe ff ff       	call   f0102ef9 <env_alloc>
f0103098:	83 c4 10             	add    $0x10,%esp
f010309b:	85 c0                	test   %eax,%eax
f010309d:	79 17                	jns    f01030b6 <env_create+0x35>
f010309f:	83 ec 04             	sub    $0x4,%esp
f01030a2:	68 a0 78 10 f0       	push   $0xf01078a0
f01030a7:	68 99 01 00 00       	push   $0x199
f01030ac:	68 c3 78 10 f0       	push   $0xf01078c3
f01030b1:	e8 8a cf ff ff       	call   f0100040 <_panic>
	load_icode(e, binary);
f01030b6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01030b9:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// LAB 3: Your code here.
	struct Elf *ELFHDR = (struct Elf *) binary;
	struct Proghdr *ph, *eph;

	if (ELFHDR->e_magic != ELF_MAGIC)
f01030bc:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f01030c2:	74 17                	je     f01030db <env_create+0x5a>
		panic("Not executable!");
f01030c4:	83 ec 04             	sub    $0x4,%esp
f01030c7:	68 e3 78 10 f0       	push   $0xf01078e3
f01030cc:	68 6d 01 00 00       	push   $0x16d
f01030d1:	68 c3 78 10 f0       	push   $0xf01078c3
f01030d6:	e8 65 cf ff ff       	call   f0100040 <_panic>
	
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
f01030db:	89 fb                	mov    %edi,%ebx
f01030dd:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + ELFHDR->e_phnum;
f01030e0:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f01030e4:	c1 e6 05             	shl    $0x5,%esi
f01030e7:	01 de                	add    %ebx,%esi
	
	//here above is just as same as main.c

	lcr3(PADDR(e->env_pgdir));
f01030e9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01030ec:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01030ef:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01030f4:	77 15                	ja     f010310b <env_create+0x8a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01030f6:	50                   	push   %eax
f01030f7:	68 28 66 10 f0       	push   $0xf0106628
f01030fc:	68 74 01 00 00       	push   $0x174
f0103101:	68 c3 78 10 f0       	push   $0xf01078c3
f0103106:	e8 35 cf ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f010310b:	05 00 00 00 10       	add    $0x10000000,%eax
f0103110:	0f 22 d8             	mov    %eax,%cr3
f0103113:	eb 3d                	jmp    f0103152 <env_create+0xd1>
	//it's silly to use kern_pgdir here.

	for (; ph < eph; ph++)
		if (ph->p_type == ELF_PROG_LOAD) {
f0103115:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103118:	75 35                	jne    f010314f <env_create+0xce>
			region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f010311a:	8b 4b 14             	mov    0x14(%ebx),%ecx
f010311d:	8b 53 08             	mov    0x8(%ebx),%edx
f0103120:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103123:	e8 54 fc ff ff       	call   f0102d7c <region_alloc>
			memset((void *)ph->p_va, 0, ph->p_memsz);
f0103128:	83 ec 04             	sub    $0x4,%esp
f010312b:	ff 73 14             	pushl  0x14(%ebx)
f010312e:	6a 00                	push   $0x0
f0103130:	ff 73 08             	pushl  0x8(%ebx)
f0103133:	e8 e8 27 00 00       	call   f0105920 <memset>
			memcpy((void *)ph->p_va, binary+ph->p_offset, ph->p_filesz);
f0103138:	83 c4 0c             	add    $0xc,%esp
f010313b:	ff 73 10             	pushl  0x10(%ebx)
f010313e:	89 f8                	mov    %edi,%eax
f0103140:	03 43 04             	add    0x4(%ebx),%eax
f0103143:	50                   	push   %eax
f0103144:	ff 73 08             	pushl  0x8(%ebx)
f0103147:	e8 89 28 00 00       	call   f01059d5 <memcpy>
f010314c:	83 c4 10             	add    $0x10,%esp
	//here above is just as same as main.c

	lcr3(PADDR(e->env_pgdir));
	//it's silly to use kern_pgdir here.

	for (; ph < eph; ph++)
f010314f:	83 c3 20             	add    $0x20,%ebx
f0103152:	39 de                	cmp    %ebx,%esi
f0103154:	77 bf                	ja     f0103115 <env_create+0x94>
			memset((void *)ph->p_va, 0, ph->p_memsz);
			memcpy((void *)ph->p_va, binary+ph->p_offset, ph->p_filesz);
		}

	//we can use this because kern_pgdir is a subset of e->env_pgdir
	lcr3(PADDR(kern_pgdir));
f0103156:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010315b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103160:	77 15                	ja     f0103177 <env_create+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103162:	50                   	push   %eax
f0103163:	68 28 66 10 f0       	push   $0xf0106628
f0103168:	68 7f 01 00 00       	push   $0x17f
f010316d:	68 c3 78 10 f0       	push   $0xf01078c3
f0103172:	e8 c9 ce ff ff       	call   f0100040 <_panic>
f0103177:	05 00 00 00 10       	add    $0x10000000,%eax
f010317c:	0f 22 d8             	mov    %eax,%cr3

	//we should set eip to make sure env_pop_tf runs correctly
	e->env_tf.tf_eip = ELFHDR->e_entry;
f010317f:	8b 47 18             	mov    0x18(%edi),%eax
f0103182:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103185:	89 47 30             	mov    %eax,0x30(%edi)
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.

	region_alloc(e, (void *) (USTACKTOP - PGSIZE), PGSIZE);
f0103188:	b9 00 10 00 00       	mov    $0x1000,%ecx
f010318d:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103192:	89 f8                	mov    %edi,%eax
f0103194:	e8 e3 fb ff ff       	call   f0102d7c <region_alloc>
{
	// LAB 3: Your code here.
	struct Env * e;
	if( env_alloc(&e,0) < 0)	panic("env_alloc() failed at env_create()");
	load_icode(e, binary);
	e->env_type = type;
f0103199:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010319c:	8b 55 0c             	mov    0xc(%ebp),%edx
f010319f:	89 50 50             	mov    %edx,0x50(%eax)
}
f01031a2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01031a5:	5b                   	pop    %ebx
f01031a6:	5e                   	pop    %esi
f01031a7:	5f                   	pop    %edi
f01031a8:	5d                   	pop    %ebp
f01031a9:	c3                   	ret    

f01031aa <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01031aa:	55                   	push   %ebp
f01031ab:	89 e5                	mov    %esp,%ebp
f01031ad:	57                   	push   %edi
f01031ae:	56                   	push   %esi
f01031af:	53                   	push   %ebx
f01031b0:	83 ec 1c             	sub    $0x1c,%esp
f01031b3:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01031b6:	e8 87 2d 00 00       	call   f0105f42 <cpunum>
f01031bb:	6b c0 74             	imul   $0x74,%eax,%eax
f01031be:	39 b8 28 d0 22 f0    	cmp    %edi,-0xfdd2fd8(%eax)
f01031c4:	75 29                	jne    f01031ef <env_free+0x45>
		lcr3(PADDR(kern_pgdir));
f01031c6:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01031cb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01031d0:	77 15                	ja     f01031e7 <env_free+0x3d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01031d2:	50                   	push   %eax
f01031d3:	68 28 66 10 f0       	push   $0xf0106628
f01031d8:	68 ac 01 00 00       	push   $0x1ac
f01031dd:	68 c3 78 10 f0       	push   $0xf01078c3
f01031e2:	e8 59 ce ff ff       	call   f0100040 <_panic>
f01031e7:	05 00 00 00 10       	add    $0x10000000,%eax
f01031ec:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01031ef:	8b 5f 48             	mov    0x48(%edi),%ebx
f01031f2:	e8 4b 2d 00 00       	call   f0105f42 <cpunum>
f01031f7:	6b c0 74             	imul   $0x74,%eax,%eax
f01031fa:	ba 00 00 00 00       	mov    $0x0,%edx
f01031ff:	83 b8 28 d0 22 f0 00 	cmpl   $0x0,-0xfdd2fd8(%eax)
f0103206:	74 11                	je     f0103219 <env_free+0x6f>
f0103208:	e8 35 2d 00 00       	call   f0105f42 <cpunum>
f010320d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103210:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103216:	8b 50 48             	mov    0x48(%eax),%edx
f0103219:	83 ec 04             	sub    $0x4,%esp
f010321c:	53                   	push   %ebx
f010321d:	52                   	push   %edx
f010321e:	68 f3 78 10 f0       	push   $0xf01078f3
f0103223:	e8 32 04 00 00       	call   f010365a <cprintf>
f0103228:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f010322b:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103232:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103235:	89 d0                	mov    %edx,%eax
f0103237:	c1 e0 02             	shl    $0x2,%eax
f010323a:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f010323d:	8b 47 60             	mov    0x60(%edi),%eax
f0103240:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0103243:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103249:	0f 84 a8 00 00 00    	je     f01032f7 <env_free+0x14d>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f010324f:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103255:	89 f0                	mov    %esi,%eax
f0103257:	c1 e8 0c             	shr    $0xc,%eax
f010325a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010325d:	39 05 88 ce 22 f0    	cmp    %eax,0xf022ce88
f0103263:	77 15                	ja     f010327a <env_free+0xd0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103265:	56                   	push   %esi
f0103266:	68 04 66 10 f0       	push   $0xf0106604
f010326b:	68 bb 01 00 00       	push   $0x1bb
f0103270:	68 c3 78 10 f0       	push   $0xf01078c3
f0103275:	e8 c6 cd ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f010327a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010327d:	c1 e0 16             	shl    $0x16,%eax
f0103280:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103283:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0103288:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f010328f:	01 
f0103290:	74 17                	je     f01032a9 <env_free+0xff>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103292:	83 ec 08             	sub    $0x8,%esp
f0103295:	89 d8                	mov    %ebx,%eax
f0103297:	c1 e0 0c             	shl    $0xc,%eax
f010329a:	0b 45 e4             	or     -0x1c(%ebp),%eax
f010329d:	50                   	push   %eax
f010329e:	ff 77 60             	pushl  0x60(%edi)
f01032a1:	e8 e2 de ff ff       	call   f0101188 <page_remove>
f01032a6:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01032a9:	83 c3 01             	add    $0x1,%ebx
f01032ac:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f01032b2:	75 d4                	jne    f0103288 <env_free+0xde>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01032b4:	8b 47 60             	mov    0x60(%edi),%eax
f01032b7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01032ba:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01032c1:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01032c4:	3b 05 88 ce 22 f0    	cmp    0xf022ce88,%eax
f01032ca:	72 14                	jb     f01032e0 <env_free+0x136>
		panic("pa2page called with invalid pa");
f01032cc:	83 ec 04             	sub    $0x4,%esp
f01032cf:	68 dc 6f 10 f0       	push   $0xf0106fdc
f01032d4:	6a 51                	push   $0x51
f01032d6:	68 cd 6b 10 f0       	push   $0xf0106bcd
f01032db:	e8 60 cd ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f01032e0:	83 ec 0c             	sub    $0xc,%esp
f01032e3:	a1 90 ce 22 f0       	mov    0xf022ce90,%eax
f01032e8:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01032eb:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01032ee:	50                   	push   %eax
f01032ef:	e8 b3 dc ff ff       	call   f0100fa7 <page_decref>
f01032f4:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01032f7:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f01032fb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01032fe:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0103303:	0f 85 29 ff ff ff    	jne    f0103232 <env_free+0x88>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103309:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010330c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103311:	77 15                	ja     f0103328 <env_free+0x17e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103313:	50                   	push   %eax
f0103314:	68 28 66 10 f0       	push   $0xf0106628
f0103319:	68 c9 01 00 00       	push   $0x1c9
f010331e:	68 c3 78 10 f0       	push   $0xf01078c3
f0103323:	e8 18 cd ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f0103328:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010332f:	05 00 00 00 10       	add    $0x10000000,%eax
f0103334:	c1 e8 0c             	shr    $0xc,%eax
f0103337:	3b 05 88 ce 22 f0    	cmp    0xf022ce88,%eax
f010333d:	72 14                	jb     f0103353 <env_free+0x1a9>
		panic("pa2page called with invalid pa");
f010333f:	83 ec 04             	sub    $0x4,%esp
f0103342:	68 dc 6f 10 f0       	push   $0xf0106fdc
f0103347:	6a 51                	push   $0x51
f0103349:	68 cd 6b 10 f0       	push   $0xf0106bcd
f010334e:	e8 ed cc ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f0103353:	83 ec 0c             	sub    $0xc,%esp
f0103356:	8b 15 90 ce 22 f0    	mov    0xf022ce90,%edx
f010335c:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f010335f:	50                   	push   %eax
f0103360:	e8 42 dc ff ff       	call   f0100fa7 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103365:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f010336c:	a1 4c c2 22 f0       	mov    0xf022c24c,%eax
f0103371:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103374:	89 3d 4c c2 22 f0    	mov    %edi,0xf022c24c
}
f010337a:	83 c4 10             	add    $0x10,%esp
f010337d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103380:	5b                   	pop    %ebx
f0103381:	5e                   	pop    %esi
f0103382:	5f                   	pop    %edi
f0103383:	5d                   	pop    %ebp
f0103384:	c3                   	ret    

f0103385 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f0103385:	55                   	push   %ebp
f0103386:	89 e5                	mov    %esp,%ebp
f0103388:	53                   	push   %ebx
f0103389:	83 ec 04             	sub    $0x4,%esp
f010338c:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f010338f:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f0103393:	75 19                	jne    f01033ae <env_destroy+0x29>
f0103395:	e8 a8 2b 00 00       	call   f0105f42 <cpunum>
f010339a:	6b c0 74             	imul   $0x74,%eax,%eax
f010339d:	3b 98 28 d0 22 f0    	cmp    -0xfdd2fd8(%eax),%ebx
f01033a3:	74 09                	je     f01033ae <env_destroy+0x29>
		e->env_status = ENV_DYING;
f01033a5:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f01033ac:	eb 33                	jmp    f01033e1 <env_destroy+0x5c>
	}

	env_free(e);
f01033ae:	83 ec 0c             	sub    $0xc,%esp
f01033b1:	53                   	push   %ebx
f01033b2:	e8 f3 fd ff ff       	call   f01031aa <env_free>

	if (curenv == e) {
f01033b7:	e8 86 2b 00 00       	call   f0105f42 <cpunum>
f01033bc:	6b c0 74             	imul   $0x74,%eax,%eax
f01033bf:	83 c4 10             	add    $0x10,%esp
f01033c2:	3b 98 28 d0 22 f0    	cmp    -0xfdd2fd8(%eax),%ebx
f01033c8:	75 17                	jne    f01033e1 <env_destroy+0x5c>
		curenv = NULL;
f01033ca:	e8 73 2b 00 00       	call   f0105f42 <cpunum>
f01033cf:	6b c0 74             	imul   $0x74,%eax,%eax
f01033d2:	c7 80 28 d0 22 f0 00 	movl   $0x0,-0xfdd2fd8(%eax)
f01033d9:	00 00 00 
		sched_yield();
f01033dc:	e8 54 15 00 00       	call   f0104935 <sched_yield>
	}
}
f01033e1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01033e4:	c9                   	leave  
f01033e5:	c3                   	ret    

f01033e6 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01033e6:	55                   	push   %ebp
f01033e7:	89 e5                	mov    %esp,%ebp
f01033e9:	53                   	push   %ebx
f01033ea:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f01033ed:	e8 50 2b 00 00       	call   f0105f42 <cpunum>
f01033f2:	6b c0 74             	imul   $0x74,%eax,%eax
f01033f5:	8b 98 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%ebx
f01033fb:	e8 42 2b 00 00       	call   f0105f42 <cpunum>
f0103400:	89 43 5c             	mov    %eax,0x5c(%ebx)

	asm volatile(
f0103403:	8b 65 08             	mov    0x8(%ebp),%esp
f0103406:	61                   	popa   
f0103407:	07                   	pop    %es
f0103408:	1f                   	pop    %ds
f0103409:	83 c4 08             	add    $0x8,%esp
f010340c:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f010340d:	83 ec 04             	sub    $0x4,%esp
f0103410:	68 09 79 10 f0       	push   $0xf0107909
f0103415:	68 00 02 00 00       	push   $0x200
f010341a:	68 c3 78 10 f0       	push   $0xf01078c3
f010341f:	e8 1c cc ff ff       	call   f0100040 <_panic>

f0103424 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103424:	55                   	push   %ebp
f0103425:	89 e5                	mov    %esp,%ebp
f0103427:	53                   	push   %ebx
f0103428:	83 ec 04             	sub    $0x4,%esp
f010342b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv && curenv->env_status == ENV_RUNNING)	curenv->env_status = ENV_RUNNABLE;
f010342e:	e8 0f 2b 00 00       	call   f0105f42 <cpunum>
f0103433:	6b c0 74             	imul   $0x74,%eax,%eax
f0103436:	83 b8 28 d0 22 f0 00 	cmpl   $0x0,-0xfdd2fd8(%eax)
f010343d:	74 29                	je     f0103468 <env_run+0x44>
f010343f:	e8 fe 2a 00 00       	call   f0105f42 <cpunum>
f0103444:	6b c0 74             	imul   $0x74,%eax,%eax
f0103447:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f010344d:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103451:	75 15                	jne    f0103468 <env_run+0x44>
f0103453:	e8 ea 2a 00 00       	call   f0105f42 <cpunum>
f0103458:	6b c0 74             	imul   $0x74,%eax,%eax
f010345b:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103461:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	curenv = e;
f0103468:	e8 d5 2a 00 00       	call   f0105f42 <cpunum>
f010346d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103470:	89 98 28 d0 22 f0    	mov    %ebx,-0xfdd2fd8(%eax)
	curenv->env_status = ENV_RUNNING;
f0103476:	e8 c7 2a 00 00       	call   f0105f42 <cpunum>
f010347b:	6b c0 74             	imul   $0x74,%eax,%eax
f010347e:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103484:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f010348b:	e8 b2 2a 00 00       	call   f0105f42 <cpunum>
f0103490:	6b c0 74             	imul   $0x74,%eax,%eax
f0103493:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103499:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(e->env_pgdir));
f010349d:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01034a0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01034a5:	77 15                	ja     f01034bc <env_run+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01034a7:	50                   	push   %eax
f01034a8:	68 28 66 10 f0       	push   $0xf0106628
f01034ad:	68 22 02 00 00       	push   $0x222
f01034b2:	68 c3 78 10 f0       	push   $0xf01078c3
f01034b7:	e8 84 cb ff ff       	call   f0100040 <_panic>
f01034bc:	05 00 00 00 10       	add    $0x10000000,%eax
f01034c1:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01034c4:	83 ec 0c             	sub    $0xc,%esp
f01034c7:	68 c0 17 12 f0       	push   $0xf01217c0
f01034cc:	e8 7c 2d 00 00       	call   f010624d <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01034d1:	f3 90                	pause  

	unlock_kernel();

	env_pop_tf(&e->env_tf);
f01034d3:	89 1c 24             	mov    %ebx,(%esp)
f01034d6:	e8 0b ff ff ff       	call   f01033e6 <env_pop_tf>

f01034db <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01034db:	55                   	push   %ebp
f01034dc:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01034de:	ba 70 00 00 00       	mov    $0x70,%edx
f01034e3:	8b 45 08             	mov    0x8(%ebp),%eax
f01034e6:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01034e7:	ba 71 00 00 00       	mov    $0x71,%edx
f01034ec:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01034ed:	0f b6 c0             	movzbl %al,%eax
}
f01034f0:	5d                   	pop    %ebp
f01034f1:	c3                   	ret    

f01034f2 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01034f2:	55                   	push   %ebp
f01034f3:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01034f5:	ba 70 00 00 00       	mov    $0x70,%edx
f01034fa:	8b 45 08             	mov    0x8(%ebp),%eax
f01034fd:	ee                   	out    %al,(%dx)
f01034fe:	ba 71 00 00 00       	mov    $0x71,%edx
f0103503:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103506:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103507:	5d                   	pop    %ebp
f0103508:	c3                   	ret    

f0103509 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0103509:	55                   	push   %ebp
f010350a:	89 e5                	mov    %esp,%ebp
f010350c:	56                   	push   %esi
f010350d:	53                   	push   %ebx
f010350e:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103511:	66 a3 a8 13 12 f0    	mov    %ax,0xf01213a8
	if (!didinit)
f0103517:	80 3d 50 c2 22 f0 00 	cmpb   $0x0,0xf022c250
f010351e:	74 5a                	je     f010357a <irq_setmask_8259A+0x71>
f0103520:	89 c6                	mov    %eax,%esi
f0103522:	ba 21 00 00 00       	mov    $0x21,%edx
f0103527:	ee                   	out    %al,(%dx)
f0103528:	66 c1 e8 08          	shr    $0x8,%ax
f010352c:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103531:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
f0103532:	83 ec 0c             	sub    $0xc,%esp
f0103535:	68 15 79 10 f0       	push   $0xf0107915
f010353a:	e8 1b 01 00 00       	call   f010365a <cprintf>
f010353f:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f0103542:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103547:	0f b7 f6             	movzwl %si,%esi
f010354a:	f7 d6                	not    %esi
f010354c:	0f a3 de             	bt     %ebx,%esi
f010354f:	73 11                	jae    f0103562 <irq_setmask_8259A+0x59>
			cprintf(" %d", i);
f0103551:	83 ec 08             	sub    $0x8,%esp
f0103554:	53                   	push   %ebx
f0103555:	68 d3 7d 10 f0       	push   $0xf0107dd3
f010355a:	e8 fb 00 00 00       	call   f010365a <cprintf>
f010355f:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f0103562:	83 c3 01             	add    $0x1,%ebx
f0103565:	83 fb 10             	cmp    $0x10,%ebx
f0103568:	75 e2                	jne    f010354c <irq_setmask_8259A+0x43>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f010356a:	83 ec 0c             	sub    $0xc,%esp
f010356d:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0103572:	e8 e3 00 00 00       	call   f010365a <cprintf>
f0103577:	83 c4 10             	add    $0x10,%esp
}
f010357a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010357d:	5b                   	pop    %ebx
f010357e:	5e                   	pop    %esi
f010357f:	5d                   	pop    %ebp
f0103580:	c3                   	ret    

f0103581 <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f0103581:	c6 05 50 c2 22 f0 01 	movb   $0x1,0xf022c250
f0103588:	ba 21 00 00 00       	mov    $0x21,%edx
f010358d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103592:	ee                   	out    %al,(%dx)
f0103593:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103598:	ee                   	out    %al,(%dx)
f0103599:	ba 20 00 00 00       	mov    $0x20,%edx
f010359e:	b8 11 00 00 00       	mov    $0x11,%eax
f01035a3:	ee                   	out    %al,(%dx)
f01035a4:	ba 21 00 00 00       	mov    $0x21,%edx
f01035a9:	b8 20 00 00 00       	mov    $0x20,%eax
f01035ae:	ee                   	out    %al,(%dx)
f01035af:	b8 04 00 00 00       	mov    $0x4,%eax
f01035b4:	ee                   	out    %al,(%dx)
f01035b5:	b8 03 00 00 00       	mov    $0x3,%eax
f01035ba:	ee                   	out    %al,(%dx)
f01035bb:	ba a0 00 00 00       	mov    $0xa0,%edx
f01035c0:	b8 11 00 00 00       	mov    $0x11,%eax
f01035c5:	ee                   	out    %al,(%dx)
f01035c6:	ba a1 00 00 00       	mov    $0xa1,%edx
f01035cb:	b8 28 00 00 00       	mov    $0x28,%eax
f01035d0:	ee                   	out    %al,(%dx)
f01035d1:	b8 02 00 00 00       	mov    $0x2,%eax
f01035d6:	ee                   	out    %al,(%dx)
f01035d7:	b8 01 00 00 00       	mov    $0x1,%eax
f01035dc:	ee                   	out    %al,(%dx)
f01035dd:	ba 20 00 00 00       	mov    $0x20,%edx
f01035e2:	b8 68 00 00 00       	mov    $0x68,%eax
f01035e7:	ee                   	out    %al,(%dx)
f01035e8:	b8 0a 00 00 00       	mov    $0xa,%eax
f01035ed:	ee                   	out    %al,(%dx)
f01035ee:	ba a0 00 00 00       	mov    $0xa0,%edx
f01035f3:	b8 68 00 00 00       	mov    $0x68,%eax
f01035f8:	ee                   	out    %al,(%dx)
f01035f9:	b8 0a 00 00 00       	mov    $0xa,%eax
f01035fe:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f01035ff:	0f b7 05 a8 13 12 f0 	movzwl 0xf01213a8,%eax
f0103606:	66 83 f8 ff          	cmp    $0xffff,%ax
f010360a:	74 13                	je     f010361f <pic_init+0x9e>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f010360c:	55                   	push   %ebp
f010360d:	89 e5                	mov    %esp,%ebp
f010360f:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f0103612:	0f b7 c0             	movzwl %ax,%eax
f0103615:	50                   	push   %eax
f0103616:	e8 ee fe ff ff       	call   f0103509 <irq_setmask_8259A>
f010361b:	83 c4 10             	add    $0x10,%esp
}
f010361e:	c9                   	leave  
f010361f:	f3 c3                	repz ret 

f0103621 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103621:	55                   	push   %ebp
f0103622:	89 e5                	mov    %esp,%ebp
f0103624:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0103627:	ff 75 08             	pushl  0x8(%ebp)
f010362a:	e8 35 d1 ff ff       	call   f0100764 <cputchar>
	*cnt++;
}
f010362f:	83 c4 10             	add    $0x10,%esp
f0103632:	c9                   	leave  
f0103633:	c3                   	ret    

f0103634 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103634:	55                   	push   %ebp
f0103635:	89 e5                	mov    %esp,%ebp
f0103637:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010363a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103641:	ff 75 0c             	pushl  0xc(%ebp)
f0103644:	ff 75 08             	pushl  0x8(%ebp)
f0103647:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010364a:	50                   	push   %eax
f010364b:	68 21 36 10 f0       	push   $0xf0103621
f0103650:	e8 5f 1c 00 00       	call   f01052b4 <vprintfmt>
	return cnt;
}
f0103655:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103658:	c9                   	leave  
f0103659:	c3                   	ret    

f010365a <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010365a:	55                   	push   %ebp
f010365b:	89 e5                	mov    %esp,%ebp
f010365d:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103660:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103663:	50                   	push   %eax
f0103664:	ff 75 08             	pushl  0x8(%ebp)
f0103667:	e8 c8 ff ff ff       	call   f0103634 <vcprintf>
	va_end(ap);

	return cnt;
}
f010366c:	c9                   	leave  
f010366d:	c3                   	ret    

f010366e <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f010366e:	55                   	push   %ebp
f010366f:	89 e5                	mov    %esp,%ebp
f0103671:	57                   	push   %edi
f0103672:	56                   	push   %esi
f0103673:	53                   	push   %ebx
f0103674:	83 ec 0c             	sub    $0xc,%esp
	// wrong, you may not get a fault until you try to return from
	// user space on that CPU.
	//
	// LAB 4: Your code here:

	int i = cpunum();
f0103677:	e8 c6 28 00 00       	call   f0105f42 <cpunum>
f010367c:	89 c3                	mov    %eax,%ebx

	thiscpu->cpu_ts.ts_esp0 = KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
f010367e:	e8 bf 28 00 00       	call   f0105f42 <cpunum>
f0103683:	6b c0 74             	imul   $0x74,%eax,%eax
f0103686:	89 d9                	mov    %ebx,%ecx
f0103688:	c1 e1 10             	shl    $0x10,%ecx
f010368b:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0103690:	29 ca                	sub    %ecx,%edx
f0103692:	89 90 30 d0 22 f0    	mov    %edx,-0xfdd2fd0(%eax)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;		
f0103698:	e8 a5 28 00 00       	call   f0105f42 <cpunum>
f010369d:	6b c0 74             	imul   $0x74,%eax,%eax
f01036a0:	66 c7 80 34 d0 22 f0 	movw   $0x10,-0xfdd2fcc(%eax)
f01036a7:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3) + i] = SEG16(STS_T32A, (uint32_t)(&(thiscpu->cpu_ts)), 
f01036a9:	83 c3 05             	add    $0x5,%ebx
f01036ac:	e8 91 28 00 00       	call   f0105f42 <cpunum>
f01036b1:	89 c7                	mov    %eax,%edi
f01036b3:	e8 8a 28 00 00       	call   f0105f42 <cpunum>
f01036b8:	89 c6                	mov    %eax,%esi
f01036ba:	e8 83 28 00 00       	call   f0105f42 <cpunum>
f01036bf:	66 c7 04 dd 40 13 12 	movw   $0x67,-0xfedecc0(,%ebx,8)
f01036c6:	f0 67 00 
f01036c9:	6b ff 74             	imul   $0x74,%edi,%edi
f01036cc:	81 c7 2c d0 22 f0    	add    $0xf022d02c,%edi
f01036d2:	66 89 3c dd 42 13 12 	mov    %di,-0xfedecbe(,%ebx,8)
f01036d9:	f0 
f01036da:	6b d6 74             	imul   $0x74,%esi,%edx
f01036dd:	81 c2 2c d0 22 f0    	add    $0xf022d02c,%edx
f01036e3:	c1 ea 10             	shr    $0x10,%edx
f01036e6:	88 14 dd 44 13 12 f0 	mov    %dl,-0xfedecbc(,%ebx,8)
f01036ed:	c6 04 dd 46 13 12 f0 	movb   $0x40,-0xfedecba(,%ebx,8)
f01036f4:	40 
f01036f5:	6b c0 74             	imul   $0x74,%eax,%eax
f01036f8:	05 2c d0 22 f0       	add    $0xf022d02c,%eax
f01036fd:	c1 e8 18             	shr    $0x18,%eax
f0103700:	88 04 dd 47 13 12 f0 	mov    %al,-0xfedecb9(,%ebx,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3) + i].sd_s = 0;
f0103707:	c6 04 dd 45 13 12 f0 	movb   $0x89,-0xfedecbb(,%ebx,8)
f010370e:	89 
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f010370f:	c1 e3 03             	shl    $0x3,%ebx
f0103712:	0f 00 db             	ltr    %bx
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f0103715:	b8 ac 13 12 f0       	mov    $0xf01213ac,%eax
f010371a:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);*/
}
f010371d:	83 c4 0c             	add    $0xc,%esp
f0103720:	5b                   	pop    %ebx
f0103721:	5e                   	pop    %esi
f0103722:	5f                   	pop    %edi
f0103723:	5d                   	pop    %ebp
f0103724:	c3                   	ret    

f0103725 <trap_init>:
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	int i;
	
	for (i = 0; i < 256; i++) {
f0103725:	b8 00 00 00 00       	mov    $0x0,%eax
		SETGATE(idt[i], 0, GD_KT, handlers[i], 0);
f010372a:	8b 14 85 b2 13 12 f0 	mov    -0xfedec4e(,%eax,4),%edx
f0103731:	66 89 14 c5 60 c2 22 	mov    %dx,-0xfdd3da0(,%eax,8)
f0103738:	f0 
f0103739:	66 c7 04 c5 62 c2 22 	movw   $0x8,-0xfdd3d9e(,%eax,8)
f0103740:	f0 08 00 
f0103743:	c6 04 c5 64 c2 22 f0 	movb   $0x0,-0xfdd3d9c(,%eax,8)
f010374a:	00 
f010374b:	c6 04 c5 65 c2 22 f0 	movb   $0x8e,-0xfdd3d9b(,%eax,8)
f0103752:	8e 
f0103753:	c1 ea 10             	shr    $0x10,%edx
f0103756:	66 89 14 c5 66 c2 22 	mov    %dx,-0xfdd3d9a(,%eax,8)
f010375d:	f0 
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	int i;
	
	for (i = 0; i < 256; i++) {
f010375e:	83 c0 01             	add    $0x1,%eax
f0103761:	3d 00 01 00 00       	cmp    $0x100,%eax
f0103766:	75 c2                	jne    f010372a <trap_init+0x5>

extern unsigned handlers[];

void
trap_init(void)
{
f0103768:	55                   	push   %ebp
f0103769:	89 e5                	mov    %esp,%ebp
f010376b:	83 ec 08             	sub    $0x8,%esp
	int i;
	
	for (i = 0; i < 256; i++) {
		SETGATE(idt[i], 0, GD_KT, handlers[i], 0);
	}
	SETGATE(idt[T_BRKPT], 0, GD_KT, handlers[T_BRKPT], 3);
f010376e:	a1 be 13 12 f0       	mov    0xf01213be,%eax
f0103773:	66 a3 78 c2 22 f0    	mov    %ax,0xf022c278
f0103779:	66 c7 05 7a c2 22 f0 	movw   $0x8,0xf022c27a
f0103780:	08 00 
f0103782:	c6 05 7c c2 22 f0 00 	movb   $0x0,0xf022c27c
f0103789:	c6 05 7d c2 22 f0 ee 	movb   $0xee,0xf022c27d
f0103790:	c1 e8 10             	shr    $0x10,%eax
f0103793:	66 a3 7e c2 22 f0    	mov    %ax,0xf022c27e
	SETGATE(idt[T_SYSCALL], 0, GD_KT, handlers[T_SYSCALL], 3);
f0103799:	a1 72 14 12 f0       	mov    0xf0121472,%eax
f010379e:	66 a3 e0 c3 22 f0    	mov    %ax,0xf022c3e0
f01037a4:	66 c7 05 e2 c3 22 f0 	movw   $0x8,0xf022c3e2
f01037ab:	08 00 
f01037ad:	c6 05 e4 c3 22 f0 00 	movb   $0x0,0xf022c3e4
f01037b4:	c6 05 e5 c3 22 f0 ee 	movb   $0xee,0xf022c3e5
f01037bb:	c1 e8 10             	shr    $0x10,%eax
f01037be:	66 a3 e6 c3 22 f0    	mov    %ax,0xf022c3e6

	// Per-CPU setup 
	trap_init_percpu();
f01037c4:	e8 a5 fe ff ff       	call   f010366e <trap_init_percpu>
}
f01037c9:	c9                   	leave  
f01037ca:	c3                   	ret    

f01037cb <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01037cb:	55                   	push   %ebp
f01037cc:	89 e5                	mov    %esp,%ebp
f01037ce:	53                   	push   %ebx
f01037cf:	83 ec 0c             	sub    $0xc,%esp
f01037d2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01037d5:	ff 33                	pushl  (%ebx)
f01037d7:	68 29 79 10 f0       	push   $0xf0107929
f01037dc:	e8 79 fe ff ff       	call   f010365a <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01037e1:	83 c4 08             	add    $0x8,%esp
f01037e4:	ff 73 04             	pushl  0x4(%ebx)
f01037e7:	68 38 79 10 f0       	push   $0xf0107938
f01037ec:	e8 69 fe ff ff       	call   f010365a <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01037f1:	83 c4 08             	add    $0x8,%esp
f01037f4:	ff 73 08             	pushl  0x8(%ebx)
f01037f7:	68 47 79 10 f0       	push   $0xf0107947
f01037fc:	e8 59 fe ff ff       	call   f010365a <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103801:	83 c4 08             	add    $0x8,%esp
f0103804:	ff 73 0c             	pushl  0xc(%ebx)
f0103807:	68 56 79 10 f0       	push   $0xf0107956
f010380c:	e8 49 fe ff ff       	call   f010365a <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103811:	83 c4 08             	add    $0x8,%esp
f0103814:	ff 73 10             	pushl  0x10(%ebx)
f0103817:	68 65 79 10 f0       	push   $0xf0107965
f010381c:	e8 39 fe ff ff       	call   f010365a <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103821:	83 c4 08             	add    $0x8,%esp
f0103824:	ff 73 14             	pushl  0x14(%ebx)
f0103827:	68 74 79 10 f0       	push   $0xf0107974
f010382c:	e8 29 fe ff ff       	call   f010365a <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103831:	83 c4 08             	add    $0x8,%esp
f0103834:	ff 73 18             	pushl  0x18(%ebx)
f0103837:	68 83 79 10 f0       	push   $0xf0107983
f010383c:	e8 19 fe ff ff       	call   f010365a <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103841:	83 c4 08             	add    $0x8,%esp
f0103844:	ff 73 1c             	pushl  0x1c(%ebx)
f0103847:	68 92 79 10 f0       	push   $0xf0107992
f010384c:	e8 09 fe ff ff       	call   f010365a <cprintf>
}
f0103851:	83 c4 10             	add    $0x10,%esp
f0103854:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103857:	c9                   	leave  
f0103858:	c3                   	ret    

f0103859 <print_trapframe>:
	lidt(&idt_pd);*/
}

void
print_trapframe(struct Trapframe *tf)
{
f0103859:	55                   	push   %ebp
f010385a:	89 e5                	mov    %esp,%ebp
f010385c:	56                   	push   %esi
f010385d:	53                   	push   %ebx
f010385e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103861:	e8 dc 26 00 00       	call   f0105f42 <cpunum>
f0103866:	83 ec 04             	sub    $0x4,%esp
f0103869:	50                   	push   %eax
f010386a:	53                   	push   %ebx
f010386b:	68 f6 79 10 f0       	push   $0xf01079f6
f0103870:	e8 e5 fd ff ff       	call   f010365a <cprintf>
	print_regs(&tf->tf_regs);
f0103875:	89 1c 24             	mov    %ebx,(%esp)
f0103878:	e8 4e ff ff ff       	call   f01037cb <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f010387d:	83 c4 08             	add    $0x8,%esp
f0103880:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103884:	50                   	push   %eax
f0103885:	68 14 7a 10 f0       	push   $0xf0107a14
f010388a:	e8 cb fd ff ff       	call   f010365a <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f010388f:	83 c4 08             	add    $0x8,%esp
f0103892:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103896:	50                   	push   %eax
f0103897:	68 27 7a 10 f0       	push   $0xf0107a27
f010389c:	e8 b9 fd ff ff       	call   f010365a <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01038a1:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f01038a4:	83 c4 10             	add    $0x10,%esp
f01038a7:	83 f8 13             	cmp    $0x13,%eax
f01038aa:	77 09                	ja     f01038b5 <print_trapframe+0x5c>
		return excnames[trapno];
f01038ac:	8b 14 85 c0 7c 10 f0 	mov    -0xfef8340(,%eax,4),%edx
f01038b3:	eb 1f                	jmp    f01038d4 <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f01038b5:	83 f8 30             	cmp    $0x30,%eax
f01038b8:	74 15                	je     f01038cf <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f01038ba:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f01038bd:	83 fa 10             	cmp    $0x10,%edx
f01038c0:	b9 c0 79 10 f0       	mov    $0xf01079c0,%ecx
f01038c5:	ba ad 79 10 f0       	mov    $0xf01079ad,%edx
f01038ca:	0f 43 d1             	cmovae %ecx,%edx
f01038cd:	eb 05                	jmp    f01038d4 <print_trapframe+0x7b>
	};

	if (trapno < ARRAY_SIZE(excnames))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f01038cf:	ba a1 79 10 f0       	mov    $0xf01079a1,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01038d4:	83 ec 04             	sub    $0x4,%esp
f01038d7:	52                   	push   %edx
f01038d8:	50                   	push   %eax
f01038d9:	68 3a 7a 10 f0       	push   $0xf0107a3a
f01038de:	e8 77 fd ff ff       	call   f010365a <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01038e3:	83 c4 10             	add    $0x10,%esp
f01038e6:	3b 1d 60 ca 22 f0    	cmp    0xf022ca60,%ebx
f01038ec:	75 1a                	jne    f0103908 <print_trapframe+0xaf>
f01038ee:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01038f2:	75 14                	jne    f0103908 <print_trapframe+0xaf>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f01038f4:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f01038f7:	83 ec 08             	sub    $0x8,%esp
f01038fa:	50                   	push   %eax
f01038fb:	68 4c 7a 10 f0       	push   $0xf0107a4c
f0103900:	e8 55 fd ff ff       	call   f010365a <cprintf>
f0103905:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103908:	83 ec 08             	sub    $0x8,%esp
f010390b:	ff 73 2c             	pushl  0x2c(%ebx)
f010390e:	68 5b 7a 10 f0       	push   $0xf0107a5b
f0103913:	e8 42 fd ff ff       	call   f010365a <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103918:	83 c4 10             	add    $0x10,%esp
f010391b:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f010391f:	75 49                	jne    f010396a <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103921:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103924:	89 c2                	mov    %eax,%edx
f0103926:	83 e2 01             	and    $0x1,%edx
f0103929:	ba da 79 10 f0       	mov    $0xf01079da,%edx
f010392e:	b9 cf 79 10 f0       	mov    $0xf01079cf,%ecx
f0103933:	0f 44 ca             	cmove  %edx,%ecx
f0103936:	89 c2                	mov    %eax,%edx
f0103938:	83 e2 02             	and    $0x2,%edx
f010393b:	ba ec 79 10 f0       	mov    $0xf01079ec,%edx
f0103940:	be e6 79 10 f0       	mov    $0xf01079e6,%esi
f0103945:	0f 45 d6             	cmovne %esi,%edx
f0103948:	83 e0 04             	and    $0x4,%eax
f010394b:	be 40 7b 10 f0       	mov    $0xf0107b40,%esi
f0103950:	b8 f1 79 10 f0       	mov    $0xf01079f1,%eax
f0103955:	0f 44 c6             	cmove  %esi,%eax
f0103958:	51                   	push   %ecx
f0103959:	52                   	push   %edx
f010395a:	50                   	push   %eax
f010395b:	68 69 7a 10 f0       	push   $0xf0107a69
f0103960:	e8 f5 fc ff ff       	call   f010365a <cprintf>
f0103965:	83 c4 10             	add    $0x10,%esp
f0103968:	eb 10                	jmp    f010397a <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f010396a:	83 ec 0c             	sub    $0xc,%esp
f010396d:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0103972:	e8 e3 fc ff ff       	call   f010365a <cprintf>
f0103977:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f010397a:	83 ec 08             	sub    $0x8,%esp
f010397d:	ff 73 30             	pushl  0x30(%ebx)
f0103980:	68 78 7a 10 f0       	push   $0xf0107a78
f0103985:	e8 d0 fc ff ff       	call   f010365a <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f010398a:	83 c4 08             	add    $0x8,%esp
f010398d:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103991:	50                   	push   %eax
f0103992:	68 87 7a 10 f0       	push   $0xf0107a87
f0103997:	e8 be fc ff ff       	call   f010365a <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f010399c:	83 c4 08             	add    $0x8,%esp
f010399f:	ff 73 38             	pushl  0x38(%ebx)
f01039a2:	68 9a 7a 10 f0       	push   $0xf0107a9a
f01039a7:	e8 ae fc ff ff       	call   f010365a <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f01039ac:	83 c4 10             	add    $0x10,%esp
f01039af:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f01039b3:	74 25                	je     f01039da <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01039b5:	83 ec 08             	sub    $0x8,%esp
f01039b8:	ff 73 3c             	pushl  0x3c(%ebx)
f01039bb:	68 a9 7a 10 f0       	push   $0xf0107aa9
f01039c0:	e8 95 fc ff ff       	call   f010365a <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01039c5:	83 c4 08             	add    $0x8,%esp
f01039c8:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f01039cc:	50                   	push   %eax
f01039cd:	68 b8 7a 10 f0       	push   $0xf0107ab8
f01039d2:	e8 83 fc ff ff       	call   f010365a <cprintf>
f01039d7:	83 c4 10             	add    $0x10,%esp
	}
}
f01039da:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01039dd:	5b                   	pop    %ebx
f01039de:	5e                   	pop    %esi
f01039df:	5d                   	pop    %ebp
f01039e0:	c3                   	ret    

f01039e1 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f01039e1:	55                   	push   %ebp
f01039e2:	89 e5                	mov    %esp,%ebp
f01039e4:	57                   	push   %edi
f01039e5:	56                   	push   %esi
f01039e6:	53                   	push   %ebx
f01039e7:	83 ec 3c             	sub    $0x3c,%esp
f01039ea:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01039ed:	0f 20 d6             	mov    %cr2,%esi
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if((tf->tf_cs & 3) == 0)
f01039f0:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f01039f4:	75 17                	jne    f0103a0d <page_fault_handler+0x2c>
		panic("Page fault in kernel mode");	
f01039f6:	83 ec 04             	sub    $0x4,%esp
f01039f9:	68 cb 7a 10 f0       	push   $0xf0107acb
f01039fe:	68 3d 01 00 00       	push   $0x13d
f0103a03:	68 e5 7a 10 f0       	push   $0xf0107ae5
f0103a08:	e8 33 c6 ff ff       	call   f0100040 <_panic>
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	if (curenv->env_pgfault_upcall != NULL) {
f0103a0d:	e8 30 25 00 00       	call   f0105f42 <cpunum>
f0103a12:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a15:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103a1b:	83 78 64 00          	cmpl   $0x0,0x64(%eax)
f0103a1f:	0f 84 fa 00 00 00    	je     f0103b1f <page_fault_handler+0x13e>
		struct UTrapframe utf;
		
		utf.utf_fault_va = fault_va;
		utf.utf_err = tf->tf_err;
f0103a25:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103a28:	89 45 dc             	mov    %eax,-0x24(%ebp)
		utf.utf_regs = tf->tf_regs;
f0103a2b:	8b 03                	mov    (%ebx),%eax
f0103a2d:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0103a30:	8b 43 04             	mov    0x4(%ebx),%eax
f0103a33:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103a36:	8b 43 08             	mov    0x8(%ebx),%eax
f0103a39:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103a3c:	8b 43 0c             	mov    0xc(%ebx),%eax
f0103a3f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103a42:	8b 43 10             	mov    0x10(%ebx),%eax
f0103a45:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103a48:	8b 43 14             	mov    0x14(%ebx),%eax
f0103a4b:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0103a4e:	8b 43 18             	mov    0x18(%ebx),%eax
f0103a51:	89 45 bc             	mov    %eax,-0x44(%ebp)
f0103a54:	8b 43 1c             	mov    0x1c(%ebx),%eax
f0103a57:	89 45 b8             	mov    %eax,-0x48(%ebp)
		utf.utf_eip = tf->tf_eip;
f0103a5a:	8b 43 30             	mov    0x30(%ebx),%eax
f0103a5d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		utf.utf_eflags = tf->tf_eflags;
f0103a60:	8b 43 38             	mov    0x38(%ebx),%eax
f0103a63:	89 45 cc             	mov    %eax,-0x34(%ebp)
		utf.utf_esp = tf->tf_esp;
f0103a66:	8b 7b 3c             	mov    0x3c(%ebx),%edi

		// if tf->tf_esp is already on the user level exception stack
		if (tf->tf_esp >= UXSTACKTOP - PGSIZE && tf->tf_esp < UXSTACKTOP)
f0103a69:	8d 87 00 10 40 11    	lea    0x11401000(%edi),%eax
f0103a6f:	3d ff 0f 00 00       	cmp    $0xfff,%eax
f0103a74:	77 08                	ja     f0103a7e <page_fault_handler+0x9d>
			tf->tf_esp -= 4;
f0103a76:	8d 47 fc             	lea    -0x4(%edi),%eax
f0103a79:	89 43 3c             	mov    %eax,0x3c(%ebx)
f0103a7c:	eb 07                	jmp    f0103a85 <page_fault_handler+0xa4>
		else  
			tf->tf_esp = UXSTACKTOP;
f0103a7e:	c7 43 3c 00 00 c0 ee 	movl   $0xeec00000,0x3c(%ebx)
		
		tf->tf_esp -= sizeof(utf);
f0103a85:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103a88:	83 e8 34             	sub    $0x34,%eax
f0103a8b:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0103a8e:	89 43 3c             	mov    %eax,0x3c(%ebx)
		user_mem_assert(curenv, (void *) tf->tf_esp, sizeof(utf), PTE_U|PTE_W|PTE_P);
f0103a91:	e8 ac 24 00 00       	call   f0105f42 <cpunum>
f0103a96:	6a 07                	push   $0x7
f0103a98:	6a 34                	push   $0x34
f0103a9a:	ff 75 c4             	pushl  -0x3c(%ebp)
f0103a9d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103aa0:	ff b0 28 d0 22 f0    	pushl  -0xfdd2fd8(%eax)
f0103aa6:	e8 87 f2 ff ff       	call   f0102d32 <user_mem_assert>
		*((struct UTrapframe *) tf->tf_esp) = utf;
f0103aab:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103aae:	89 30                	mov    %esi,(%eax)
f0103ab0:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103ab3:	89 50 04             	mov    %edx,0x4(%eax)
f0103ab6:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0103ab9:	89 48 08             	mov    %ecx,0x8(%eax)
f0103abc:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0103abf:	89 50 0c             	mov    %edx,0xc(%eax)
f0103ac2:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0103ac5:	89 48 10             	mov    %ecx,0x10(%eax)
f0103ac8:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103acb:	89 50 14             	mov    %edx,0x14(%eax)
f0103ace:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103ad1:	89 48 18             	mov    %ecx,0x18(%eax)
f0103ad4:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0103ad7:	89 50 1c             	mov    %edx,0x1c(%eax)
f0103ada:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0103add:	89 48 20             	mov    %ecx,0x20(%eax)
f0103ae0:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0103ae3:	89 50 24             	mov    %edx,0x24(%eax)
f0103ae6:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0103ae9:	89 48 28             	mov    %ecx,0x28(%eax)
f0103aec:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0103aef:	89 50 2c             	mov    %edx,0x2c(%eax)
f0103af2:	89 78 30             	mov    %edi,0x30(%eax)

		tf->tf_eip = (uintptr_t) curenv->env_pgfault_upcall;
f0103af5:	e8 48 24 00 00       	call   f0105f42 <cpunum>
f0103afa:	6b c0 74             	imul   $0x74,%eax,%eax
f0103afd:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103b03:	8b 40 64             	mov    0x64(%eax),%eax
f0103b06:	89 43 30             	mov    %eax,0x30(%ebx)

		env_run(curenv);
f0103b09:	e8 34 24 00 00       	call   f0105f42 <cpunum>
f0103b0e:	83 c4 04             	add    $0x4,%esp
f0103b11:	6b c0 74             	imul   $0x74,%eax,%eax
f0103b14:	ff b0 28 d0 22 f0    	pushl  -0xfdd2fd8(%eax)
f0103b1a:	e8 05 f9 ff ff       	call   f0103424 <env_run>
} 

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103b1f:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f0103b22:	e8 1b 24 00 00       	call   f0105f42 <cpunum>

		env_run(curenv);
} 

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103b27:	57                   	push   %edi
f0103b28:	56                   	push   %esi
		curenv->env_id, fault_va, tf->tf_eip);
f0103b29:	6b c0 74             	imul   $0x74,%eax,%eax

		env_run(curenv);
} 

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103b2c:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103b32:	ff 70 48             	pushl  0x48(%eax)
f0103b35:	68 8c 7c 10 f0       	push   $0xf0107c8c
f0103b3a:	e8 1b fb ff ff       	call   f010365a <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103b3f:	89 1c 24             	mov    %ebx,(%esp)
f0103b42:	e8 12 fd ff ff       	call   f0103859 <print_trapframe>
	env_destroy(curenv);
f0103b47:	e8 f6 23 00 00       	call   f0105f42 <cpunum>
f0103b4c:	83 c4 04             	add    $0x4,%esp
f0103b4f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103b52:	ff b0 28 d0 22 f0    	pushl  -0xfdd2fd8(%eax)
f0103b58:	e8 28 f8 ff ff       	call   f0103385 <env_destroy>
}
f0103b5d:	83 c4 10             	add    $0x10,%esp
f0103b60:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103b63:	5b                   	pop    %ebx
f0103b64:	5e                   	pop    %esi
f0103b65:	5f                   	pop    %edi
f0103b66:	5d                   	pop    %ebp
f0103b67:	c3                   	ret    

f0103b68 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103b68:	55                   	push   %ebp
f0103b69:	89 e5                	mov    %esp,%ebp
f0103b6b:	57                   	push   %edi
f0103b6c:	56                   	push   %esi
f0103b6d:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103b70:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103b71:	83 3d 80 ce 22 f0 00 	cmpl   $0x0,0xf022ce80
f0103b78:	74 01                	je     f0103b7b <trap+0x13>
		asm volatile("hlt");
f0103b7a:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0103b7b:	e8 c2 23 00 00       	call   f0105f42 <cpunum>
f0103b80:	6b d0 74             	imul   $0x74,%eax,%edx
f0103b83:	81 c2 20 d0 22 f0    	add    $0xf022d020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0103b89:	b8 01 00 00 00       	mov    $0x1,%eax
f0103b8e:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0103b92:	83 f8 02             	cmp    $0x2,%eax
f0103b95:	75 10                	jne    f0103ba7 <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0103b97:	83 ec 0c             	sub    $0xc,%esp
f0103b9a:	68 c0 17 12 f0       	push   $0xf01217c0
f0103b9f:	e8 0c 26 00 00       	call   f01061b0 <spin_lock>
f0103ba4:	83 c4 10             	add    $0x10,%esp

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103ba7:	9c                   	pushf  
f0103ba8:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103ba9:	f6 c4 02             	test   $0x2,%ah
f0103bac:	74 19                	je     f0103bc7 <trap+0x5f>
f0103bae:	68 f1 7a 10 f0       	push   $0xf0107af1
f0103bb3:	68 e7 6b 10 f0       	push   $0xf0106be7
f0103bb8:	68 07 01 00 00       	push   $0x107
f0103bbd:	68 e5 7a 10 f0       	push   $0xf0107ae5
f0103bc2:	e8 79 c4 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0103bc7:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103bcb:	83 e0 03             	and    $0x3,%eax
f0103bce:	66 83 f8 03          	cmp    $0x3,%ax
f0103bd2:	0f 85 a0 00 00 00    	jne    f0103c78 <trap+0x110>
f0103bd8:	83 ec 0c             	sub    $0xc,%esp
f0103bdb:	68 c0 17 12 f0       	push   $0xf01217c0
f0103be0:	e8 cb 25 00 00       	call   f01061b0 <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel();
		assert(curenv);
f0103be5:	e8 58 23 00 00       	call   f0105f42 <cpunum>
f0103bea:	6b c0 74             	imul   $0x74,%eax,%eax
f0103bed:	83 c4 10             	add    $0x10,%esp
f0103bf0:	83 b8 28 d0 22 f0 00 	cmpl   $0x0,-0xfdd2fd8(%eax)
f0103bf7:	75 19                	jne    f0103c12 <trap+0xaa>
f0103bf9:	68 0a 7b 10 f0       	push   $0xf0107b0a
f0103bfe:	68 e7 6b 10 f0       	push   $0xf0106be7
f0103c03:	68 0f 01 00 00       	push   $0x10f
f0103c08:	68 e5 7a 10 f0       	push   $0xf0107ae5
f0103c0d:	e8 2e c4 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0103c12:	e8 2b 23 00 00       	call   f0105f42 <cpunum>
f0103c17:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c1a:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103c20:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0103c24:	75 2d                	jne    f0103c53 <trap+0xeb>
			env_free(curenv);
f0103c26:	e8 17 23 00 00       	call   f0105f42 <cpunum>
f0103c2b:	83 ec 0c             	sub    $0xc,%esp
f0103c2e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c31:	ff b0 28 d0 22 f0    	pushl  -0xfdd2fd8(%eax)
f0103c37:	e8 6e f5 ff ff       	call   f01031aa <env_free>
			curenv = NULL;
f0103c3c:	e8 01 23 00 00       	call   f0105f42 <cpunum>
f0103c41:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c44:	c7 80 28 d0 22 f0 00 	movl   $0x0,-0xfdd2fd8(%eax)
f0103c4b:	00 00 00 
			sched_yield();
f0103c4e:	e8 e2 0c 00 00       	call   f0104935 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103c53:	e8 ea 22 00 00       	call   f0105f42 <cpunum>
f0103c58:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c5b:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103c61:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103c66:	89 c7                	mov    %eax,%edi
f0103c68:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103c6a:	e8 d3 22 00 00       	call   f0105f42 <cpunum>
f0103c6f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c72:	8b b0 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103c78:	89 35 60 ca 22 f0    	mov    %esi,0xf022ca60
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch (tf->tf_trapno) {
f0103c7e:	8b 46 28             	mov    0x28(%esi),%eax
f0103c81:	83 f8 0e             	cmp    $0xe,%eax
f0103c84:	74 0c                	je     f0103c92 <trap+0x12a>
f0103c86:	83 f8 30             	cmp    $0x30,%eax
f0103c89:	74 29                	je     f0103cb4 <trap+0x14c>
f0103c8b:	83 f8 03             	cmp    $0x3,%eax
f0103c8e:	75 45                	jne    f0103cd5 <trap+0x16d>
f0103c90:	eb 11                	jmp    f0103ca3 <trap+0x13b>
	
	case T_PGFLT:
		page_fault_handler(tf);
f0103c92:	83 ec 0c             	sub    $0xc,%esp
f0103c95:	56                   	push   %esi
f0103c96:	e8 46 fd ff ff       	call   f01039e1 <page_fault_handler>
f0103c9b:	83 c4 10             	add    $0x10,%esp
f0103c9e:	e9 94 00 00 00       	jmp    f0103d37 <trap+0x1cf>
		break;
	case T_BRKPT:
		monitor(tf);
f0103ca3:	83 ec 0c             	sub    $0xc,%esp
f0103ca6:	56                   	push   %esi
f0103ca7:	e8 51 cc ff ff       	call   f01008fd <monitor>
f0103cac:	83 c4 10             	add    $0x10,%esp
f0103caf:	e9 83 00 00 00       	jmp    f0103d37 <trap+0x1cf>
		break;
	case T_SYSCALL:
		tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax, tf->tf_regs.reg_edx, tf->tf_regs.reg_ecx, tf->tf_regs.reg_ebx, tf->tf_regs.reg_edi, tf->tf_regs.reg_esi);
f0103cb4:	83 ec 08             	sub    $0x8,%esp
f0103cb7:	ff 76 04             	pushl  0x4(%esi)
f0103cba:	ff 36                	pushl  (%esi)
f0103cbc:	ff 76 10             	pushl  0x10(%esi)
f0103cbf:	ff 76 18             	pushl  0x18(%esi)
f0103cc2:	ff 76 14             	pushl  0x14(%esi)
f0103cc5:	ff 76 1c             	pushl  0x1c(%esi)
f0103cc8:	e8 1b 0d 00 00       	call   f01049e8 <syscall>
f0103ccd:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103cd0:	83 c4 20             	add    $0x20,%esp
f0103cd3:	eb 62                	jmp    f0103d37 <trap+0x1cf>
	default:	

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0103cd5:	83 f8 27             	cmp    $0x27,%eax
f0103cd8:	75 1a                	jne    f0103cf4 <trap+0x18c>
		cprintf("Spurious interrupt on irq 7\n");
f0103cda:	83 ec 0c             	sub    $0xc,%esp
f0103cdd:	68 11 7b 10 f0       	push   $0xf0107b11
f0103ce2:	e8 73 f9 ff ff       	call   f010365a <cprintf>
		print_trapframe(tf);
f0103ce7:	89 34 24             	mov    %esi,(%esp)
f0103cea:	e8 6a fb ff ff       	call   f0103859 <print_trapframe>
f0103cef:	83 c4 10             	add    $0x10,%esp
f0103cf2:	eb 43                	jmp    f0103d37 <trap+0x1cf>
	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103cf4:	83 ec 0c             	sub    $0xc,%esp
f0103cf7:	56                   	push   %esi
f0103cf8:	e8 5c fb ff ff       	call   f0103859 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103cfd:	83 c4 10             	add    $0x10,%esp
f0103d00:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103d05:	75 17                	jne    f0103d1e <trap+0x1b6>
		panic("unhandled trap in kernel");
f0103d07:	83 ec 04             	sub    $0x4,%esp
f0103d0a:	68 2e 7b 10 f0       	push   $0xf0107b2e
f0103d0f:	68 ec 00 00 00       	push   $0xec
f0103d14:	68 e5 7a 10 f0       	push   $0xf0107ae5
f0103d19:	e8 22 c3 ff ff       	call   f0100040 <_panic>
	else {
		env_destroy(curenv);
f0103d1e:	e8 1f 22 00 00       	call   f0105f42 <cpunum>
f0103d23:	83 ec 0c             	sub    $0xc,%esp
f0103d26:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d29:	ff b0 28 d0 22 f0    	pushl  -0xfdd2fd8(%eax)
f0103d2f:	e8 51 f6 ff ff       	call   f0103385 <env_destroy>
f0103d34:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0103d37:	e8 06 22 00 00       	call   f0105f42 <cpunum>
f0103d3c:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d3f:	83 b8 28 d0 22 f0 00 	cmpl   $0x0,-0xfdd2fd8(%eax)
f0103d46:	74 2a                	je     f0103d72 <trap+0x20a>
f0103d48:	e8 f5 21 00 00       	call   f0105f42 <cpunum>
f0103d4d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d50:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103d56:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103d5a:	75 16                	jne    f0103d72 <trap+0x20a>
		env_run(curenv);
f0103d5c:	e8 e1 21 00 00       	call   f0105f42 <cpunum>
f0103d61:	83 ec 0c             	sub    $0xc,%esp
f0103d64:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d67:	ff b0 28 d0 22 f0    	pushl  -0xfdd2fd8(%eax)
f0103d6d:	e8 b2 f6 ff ff       	call   f0103424 <env_run>
	else
		sched_yield();
f0103d72:	e8 be 0b 00 00       	call   f0104935 <sched_yield>
f0103d77:	90                   	nop

f0103d78 <handler0>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(handler0, 0)
f0103d78:	6a 00                	push   $0x0
f0103d7a:	6a 00                	push   $0x0
f0103d7c:	e9 d0 0a 00 00       	jmp    f0104851 <_alltraps>
f0103d81:	90                   	nop

f0103d82 <handler1>:
TRAPHANDLER_NOEC(handler1, 1)
f0103d82:	6a 00                	push   $0x0
f0103d84:	6a 01                	push   $0x1
f0103d86:	e9 c6 0a 00 00       	jmp    f0104851 <_alltraps>
f0103d8b:	90                   	nop

f0103d8c <handler2>:
TRAPHANDLER_NOEC(handler2, 2)
f0103d8c:	6a 00                	push   $0x0
f0103d8e:	6a 02                	push   $0x2
f0103d90:	e9 bc 0a 00 00       	jmp    f0104851 <_alltraps>
f0103d95:	90                   	nop

f0103d96 <handler3>:
TRAPHANDLER_NOEC(handler3, 3)
f0103d96:	6a 00                	push   $0x0
f0103d98:	6a 03                	push   $0x3
f0103d9a:	e9 b2 0a 00 00       	jmp    f0104851 <_alltraps>
f0103d9f:	90                   	nop

f0103da0 <handler4>:
TRAPHANDLER_NOEC(handler4, 4)
f0103da0:	6a 00                	push   $0x0
f0103da2:	6a 04                	push   $0x4
f0103da4:	e9 a8 0a 00 00       	jmp    f0104851 <_alltraps>
f0103da9:	90                   	nop

f0103daa <handler5>:
TRAPHANDLER_NOEC(handler5, 5)
f0103daa:	6a 00                	push   $0x0
f0103dac:	6a 05                	push   $0x5
f0103dae:	e9 9e 0a 00 00       	jmp    f0104851 <_alltraps>
f0103db3:	90                   	nop

f0103db4 <handler6>:
TRAPHANDLER_NOEC(handler6, 6)
f0103db4:	6a 00                	push   $0x0
f0103db6:	6a 06                	push   $0x6
f0103db8:	e9 94 0a 00 00       	jmp    f0104851 <_alltraps>
f0103dbd:	90                   	nop

f0103dbe <handler7>:
TRAPHANDLER_NOEC(handler7, 7)
f0103dbe:	6a 00                	push   $0x0
f0103dc0:	6a 07                	push   $0x7
f0103dc2:	e9 8a 0a 00 00       	jmp    f0104851 <_alltraps>
f0103dc7:	90                   	nop

f0103dc8 <handler8>:
TRAPHANDLER(handler8, 8)
f0103dc8:	6a 08                	push   $0x8
f0103dca:	e9 82 0a 00 00       	jmp    f0104851 <_alltraps>
f0103dcf:	90                   	nop

f0103dd0 <handler9>:
TRAPHANDLER_NOEC(handler9, 9)
f0103dd0:	6a 00                	push   $0x0
f0103dd2:	6a 09                	push   $0x9
f0103dd4:	e9 78 0a 00 00       	jmp    f0104851 <_alltraps>
f0103dd9:	90                   	nop

f0103dda <handler10>:
TRAPHANDLER(handler10, 10)
f0103dda:	6a 0a                	push   $0xa
f0103ddc:	e9 70 0a 00 00       	jmp    f0104851 <_alltraps>
f0103de1:	90                   	nop

f0103de2 <handler11>:
TRAPHANDLER(handler11, 11)
f0103de2:	6a 0b                	push   $0xb
f0103de4:	e9 68 0a 00 00       	jmp    f0104851 <_alltraps>
f0103de9:	90                   	nop

f0103dea <handler12>:
TRAPHANDLER(handler12, 12)
f0103dea:	6a 0c                	push   $0xc
f0103dec:	e9 60 0a 00 00       	jmp    f0104851 <_alltraps>
f0103df1:	90                   	nop

f0103df2 <handler13>:
TRAPHANDLER(handler13, 13)
f0103df2:	6a 0d                	push   $0xd
f0103df4:	e9 58 0a 00 00       	jmp    f0104851 <_alltraps>
f0103df9:	90                   	nop

f0103dfa <handler14>:
TRAPHANDLER(handler14, 14)
f0103dfa:	6a 0e                	push   $0xe
f0103dfc:	e9 50 0a 00 00       	jmp    f0104851 <_alltraps>
f0103e01:	90                   	nop

f0103e02 <handler15>:
TRAPHANDLER_NOEC(handler15, 15)
f0103e02:	6a 00                	push   $0x0
f0103e04:	6a 0f                	push   $0xf
f0103e06:	e9 46 0a 00 00       	jmp    f0104851 <_alltraps>
f0103e0b:	90                   	nop

f0103e0c <handler16>:
TRAPHANDLER_NOEC(handler16, 16)
f0103e0c:	6a 00                	push   $0x0
f0103e0e:	6a 10                	push   $0x10
f0103e10:	e9 3c 0a 00 00       	jmp    f0104851 <_alltraps>
f0103e15:	90                   	nop

f0103e16 <handler17>:
TRAPHANDLER_NOEC(handler17, 17)
f0103e16:	6a 00                	push   $0x0
f0103e18:	6a 11                	push   $0x11
f0103e1a:	e9 32 0a 00 00       	jmp    f0104851 <_alltraps>
f0103e1f:	90                   	nop

f0103e20 <handler18>:
TRAPHANDLER_NOEC(handler18, 18)
f0103e20:	6a 00                	push   $0x0
f0103e22:	6a 12                	push   $0x12
f0103e24:	e9 28 0a 00 00       	jmp    f0104851 <_alltraps>
f0103e29:	90                   	nop

f0103e2a <handler19>:
TRAPHANDLER_NOEC(handler19, 19)
f0103e2a:	6a 00                	push   $0x0
f0103e2c:	6a 13                	push   $0x13
f0103e2e:	e9 1e 0a 00 00       	jmp    f0104851 <_alltraps>
f0103e33:	90                   	nop

f0103e34 <handler20>:
TRAPHANDLER_NOEC(handler20, 20)
f0103e34:	6a 00                	push   $0x0
f0103e36:	6a 14                	push   $0x14
f0103e38:	e9 14 0a 00 00       	jmp    f0104851 <_alltraps>
f0103e3d:	90                   	nop

f0103e3e <handler21>:
TRAPHANDLER_NOEC(handler21, 21)
f0103e3e:	6a 00                	push   $0x0
f0103e40:	6a 15                	push   $0x15
f0103e42:	e9 0a 0a 00 00       	jmp    f0104851 <_alltraps>
f0103e47:	90                   	nop

f0103e48 <handler22>:
TRAPHANDLER_NOEC(handler22, 22)
f0103e48:	6a 00                	push   $0x0
f0103e4a:	6a 16                	push   $0x16
f0103e4c:	e9 00 0a 00 00       	jmp    f0104851 <_alltraps>
f0103e51:	90                   	nop

f0103e52 <handler23>:
TRAPHANDLER_NOEC(handler23, 23)
f0103e52:	6a 00                	push   $0x0
f0103e54:	6a 17                	push   $0x17
f0103e56:	e9 f6 09 00 00       	jmp    f0104851 <_alltraps>
f0103e5b:	90                   	nop

f0103e5c <handler24>:
TRAPHANDLER_NOEC(handler24, 24)
f0103e5c:	6a 00                	push   $0x0
f0103e5e:	6a 18                	push   $0x18
f0103e60:	e9 ec 09 00 00       	jmp    f0104851 <_alltraps>
f0103e65:	90                   	nop

f0103e66 <handler25>:
TRAPHANDLER_NOEC(handler25, 25)
f0103e66:	6a 00                	push   $0x0
f0103e68:	6a 19                	push   $0x19
f0103e6a:	e9 e2 09 00 00       	jmp    f0104851 <_alltraps>
f0103e6f:	90                   	nop

f0103e70 <handler26>:
TRAPHANDLER_NOEC(handler26, 26)
f0103e70:	6a 00                	push   $0x0
f0103e72:	6a 1a                	push   $0x1a
f0103e74:	e9 d8 09 00 00       	jmp    f0104851 <_alltraps>
f0103e79:	90                   	nop

f0103e7a <handler27>:
TRAPHANDLER_NOEC(handler27, 27)
f0103e7a:	6a 00                	push   $0x0
f0103e7c:	6a 1b                	push   $0x1b
f0103e7e:	e9 ce 09 00 00       	jmp    f0104851 <_alltraps>
f0103e83:	90                   	nop

f0103e84 <handler28>:
TRAPHANDLER_NOEC(handler28, 28)
f0103e84:	6a 00                	push   $0x0
f0103e86:	6a 1c                	push   $0x1c
f0103e88:	e9 c4 09 00 00       	jmp    f0104851 <_alltraps>
f0103e8d:	90                   	nop

f0103e8e <handler29>:
TRAPHANDLER_NOEC(handler29, 29)
f0103e8e:	6a 00                	push   $0x0
f0103e90:	6a 1d                	push   $0x1d
f0103e92:	e9 ba 09 00 00       	jmp    f0104851 <_alltraps>
f0103e97:	90                   	nop

f0103e98 <handler30>:
TRAPHANDLER_NOEC(handler30, 30)
f0103e98:	6a 00                	push   $0x0
f0103e9a:	6a 1e                	push   $0x1e
f0103e9c:	e9 b0 09 00 00       	jmp    f0104851 <_alltraps>
f0103ea1:	90                   	nop

f0103ea2 <handler31>:
TRAPHANDLER_NOEC(handler31, 31)
f0103ea2:	6a 00                	push   $0x0
f0103ea4:	6a 1f                	push   $0x1f
f0103ea6:	e9 a6 09 00 00       	jmp    f0104851 <_alltraps>
f0103eab:	90                   	nop

f0103eac <handler32>:
TRAPHANDLER_NOEC(handler32, 32)
f0103eac:	6a 00                	push   $0x0
f0103eae:	6a 20                	push   $0x20
f0103eb0:	e9 9c 09 00 00       	jmp    f0104851 <_alltraps>
f0103eb5:	90                   	nop

f0103eb6 <handler33>:
TRAPHANDLER_NOEC(handler33, 33)
f0103eb6:	6a 00                	push   $0x0
f0103eb8:	6a 21                	push   $0x21
f0103eba:	e9 92 09 00 00       	jmp    f0104851 <_alltraps>
f0103ebf:	90                   	nop

f0103ec0 <handler34>:
TRAPHANDLER_NOEC(handler34, 34)
f0103ec0:	6a 00                	push   $0x0
f0103ec2:	6a 22                	push   $0x22
f0103ec4:	e9 88 09 00 00       	jmp    f0104851 <_alltraps>
f0103ec9:	90                   	nop

f0103eca <handler35>:
TRAPHANDLER_NOEC(handler35, 35)
f0103eca:	6a 00                	push   $0x0
f0103ecc:	6a 23                	push   $0x23
f0103ece:	e9 7e 09 00 00       	jmp    f0104851 <_alltraps>
f0103ed3:	90                   	nop

f0103ed4 <handler36>:
TRAPHANDLER_NOEC(handler36, 36)
f0103ed4:	6a 00                	push   $0x0
f0103ed6:	6a 24                	push   $0x24
f0103ed8:	e9 74 09 00 00       	jmp    f0104851 <_alltraps>
f0103edd:	90                   	nop

f0103ede <handler37>:
TRAPHANDLER_NOEC(handler37, 37)
f0103ede:	6a 00                	push   $0x0
f0103ee0:	6a 25                	push   $0x25
f0103ee2:	e9 6a 09 00 00       	jmp    f0104851 <_alltraps>
f0103ee7:	90                   	nop

f0103ee8 <handler38>:
TRAPHANDLER_NOEC(handler38, 38)
f0103ee8:	6a 00                	push   $0x0
f0103eea:	6a 26                	push   $0x26
f0103eec:	e9 60 09 00 00       	jmp    f0104851 <_alltraps>
f0103ef1:	90                   	nop

f0103ef2 <handler39>:
TRAPHANDLER_NOEC(handler39, 39)
f0103ef2:	6a 00                	push   $0x0
f0103ef4:	6a 27                	push   $0x27
f0103ef6:	e9 56 09 00 00       	jmp    f0104851 <_alltraps>
f0103efb:	90                   	nop

f0103efc <handler40>:
TRAPHANDLER_NOEC(handler40, 40)
f0103efc:	6a 00                	push   $0x0
f0103efe:	6a 28                	push   $0x28
f0103f00:	e9 4c 09 00 00       	jmp    f0104851 <_alltraps>
f0103f05:	90                   	nop

f0103f06 <handler41>:
TRAPHANDLER_NOEC(handler41, 41)
f0103f06:	6a 00                	push   $0x0
f0103f08:	6a 29                	push   $0x29
f0103f0a:	e9 42 09 00 00       	jmp    f0104851 <_alltraps>
f0103f0f:	90                   	nop

f0103f10 <handler42>:
TRAPHANDLER_NOEC(handler42, 42)
f0103f10:	6a 00                	push   $0x0
f0103f12:	6a 2a                	push   $0x2a
f0103f14:	e9 38 09 00 00       	jmp    f0104851 <_alltraps>
f0103f19:	90                   	nop

f0103f1a <handler43>:
TRAPHANDLER_NOEC(handler43, 43)
f0103f1a:	6a 00                	push   $0x0
f0103f1c:	6a 2b                	push   $0x2b
f0103f1e:	e9 2e 09 00 00       	jmp    f0104851 <_alltraps>
f0103f23:	90                   	nop

f0103f24 <handler44>:
TRAPHANDLER_NOEC(handler44, 44)
f0103f24:	6a 00                	push   $0x0
f0103f26:	6a 2c                	push   $0x2c
f0103f28:	e9 24 09 00 00       	jmp    f0104851 <_alltraps>
f0103f2d:	90                   	nop

f0103f2e <handler45>:
TRAPHANDLER_NOEC(handler45, 45)
f0103f2e:	6a 00                	push   $0x0
f0103f30:	6a 2d                	push   $0x2d
f0103f32:	e9 1a 09 00 00       	jmp    f0104851 <_alltraps>
f0103f37:	90                   	nop

f0103f38 <handler46>:
TRAPHANDLER_NOEC(handler46, 46)
f0103f38:	6a 00                	push   $0x0
f0103f3a:	6a 2e                	push   $0x2e
f0103f3c:	e9 10 09 00 00       	jmp    f0104851 <_alltraps>
f0103f41:	90                   	nop

f0103f42 <handler47>:
TRAPHANDLER_NOEC(handler47, 47)
f0103f42:	6a 00                	push   $0x0
f0103f44:	6a 2f                	push   $0x2f
f0103f46:	e9 06 09 00 00       	jmp    f0104851 <_alltraps>
f0103f4b:	90                   	nop

f0103f4c <handler48>:
TRAPHANDLER_NOEC(handler48, 48)
f0103f4c:	6a 00                	push   $0x0
f0103f4e:	6a 30                	push   $0x30
f0103f50:	e9 fc 08 00 00       	jmp    f0104851 <_alltraps>
f0103f55:	90                   	nop

f0103f56 <handler49>:
TRAPHANDLER_NOEC(handler49, 49)
f0103f56:	6a 00                	push   $0x0
f0103f58:	6a 31                	push   $0x31
f0103f5a:	e9 f2 08 00 00       	jmp    f0104851 <_alltraps>
f0103f5f:	90                   	nop

f0103f60 <handler50>:
TRAPHANDLER_NOEC(handler50, 50)
f0103f60:	6a 00                	push   $0x0
f0103f62:	6a 32                	push   $0x32
f0103f64:	e9 e8 08 00 00       	jmp    f0104851 <_alltraps>
f0103f69:	90                   	nop

f0103f6a <handler51>:
TRAPHANDLER_NOEC(handler51, 51)
f0103f6a:	6a 00                	push   $0x0
f0103f6c:	6a 33                	push   $0x33
f0103f6e:	e9 de 08 00 00       	jmp    f0104851 <_alltraps>
f0103f73:	90                   	nop

f0103f74 <handler52>:
TRAPHANDLER_NOEC(handler52, 52)
f0103f74:	6a 00                	push   $0x0
f0103f76:	6a 34                	push   $0x34
f0103f78:	e9 d4 08 00 00       	jmp    f0104851 <_alltraps>
f0103f7d:	90                   	nop

f0103f7e <handler53>:
TRAPHANDLER_NOEC(handler53, 53)
f0103f7e:	6a 00                	push   $0x0
f0103f80:	6a 35                	push   $0x35
f0103f82:	e9 ca 08 00 00       	jmp    f0104851 <_alltraps>
f0103f87:	90                   	nop

f0103f88 <handler54>:
TRAPHANDLER_NOEC(handler54, 54)
f0103f88:	6a 00                	push   $0x0
f0103f8a:	6a 36                	push   $0x36
f0103f8c:	e9 c0 08 00 00       	jmp    f0104851 <_alltraps>
f0103f91:	90                   	nop

f0103f92 <handler55>:
TRAPHANDLER_NOEC(handler55, 55)
f0103f92:	6a 00                	push   $0x0
f0103f94:	6a 37                	push   $0x37
f0103f96:	e9 b6 08 00 00       	jmp    f0104851 <_alltraps>
f0103f9b:	90                   	nop

f0103f9c <handler56>:
TRAPHANDLER_NOEC(handler56, 56)
f0103f9c:	6a 00                	push   $0x0
f0103f9e:	6a 38                	push   $0x38
f0103fa0:	e9 ac 08 00 00       	jmp    f0104851 <_alltraps>
f0103fa5:	90                   	nop

f0103fa6 <handler57>:
TRAPHANDLER_NOEC(handler57, 57)
f0103fa6:	6a 00                	push   $0x0
f0103fa8:	6a 39                	push   $0x39
f0103faa:	e9 a2 08 00 00       	jmp    f0104851 <_alltraps>
f0103faf:	90                   	nop

f0103fb0 <handler58>:
TRAPHANDLER_NOEC(handler58, 58)
f0103fb0:	6a 00                	push   $0x0
f0103fb2:	6a 3a                	push   $0x3a
f0103fb4:	e9 98 08 00 00       	jmp    f0104851 <_alltraps>
f0103fb9:	90                   	nop

f0103fba <handler59>:
TRAPHANDLER_NOEC(handler59, 59)
f0103fba:	6a 00                	push   $0x0
f0103fbc:	6a 3b                	push   $0x3b
f0103fbe:	e9 8e 08 00 00       	jmp    f0104851 <_alltraps>
f0103fc3:	90                   	nop

f0103fc4 <handler60>:
TRAPHANDLER_NOEC(handler60, 60)
f0103fc4:	6a 00                	push   $0x0
f0103fc6:	6a 3c                	push   $0x3c
f0103fc8:	e9 84 08 00 00       	jmp    f0104851 <_alltraps>
f0103fcd:	90                   	nop

f0103fce <handler61>:
TRAPHANDLER_NOEC(handler61, 61)
f0103fce:	6a 00                	push   $0x0
f0103fd0:	6a 3d                	push   $0x3d
f0103fd2:	e9 7a 08 00 00       	jmp    f0104851 <_alltraps>
f0103fd7:	90                   	nop

f0103fd8 <handler62>:
TRAPHANDLER_NOEC(handler62, 62)
f0103fd8:	6a 00                	push   $0x0
f0103fda:	6a 3e                	push   $0x3e
f0103fdc:	e9 70 08 00 00       	jmp    f0104851 <_alltraps>
f0103fe1:	90                   	nop

f0103fe2 <handler63>:
TRAPHANDLER_NOEC(handler63, 63)
f0103fe2:	6a 00                	push   $0x0
f0103fe4:	6a 3f                	push   $0x3f
f0103fe6:	e9 66 08 00 00       	jmp    f0104851 <_alltraps>
f0103feb:	90                   	nop

f0103fec <handler64>:
TRAPHANDLER_NOEC(handler64, 64)
f0103fec:	6a 00                	push   $0x0
f0103fee:	6a 40                	push   $0x40
f0103ff0:	e9 5c 08 00 00       	jmp    f0104851 <_alltraps>
f0103ff5:	90                   	nop

f0103ff6 <handler65>:
TRAPHANDLER_NOEC(handler65, 65)
f0103ff6:	6a 00                	push   $0x0
f0103ff8:	6a 41                	push   $0x41
f0103ffa:	e9 52 08 00 00       	jmp    f0104851 <_alltraps>
f0103fff:	90                   	nop

f0104000 <handler66>:
TRAPHANDLER_NOEC(handler66, 66)
f0104000:	6a 00                	push   $0x0
f0104002:	6a 42                	push   $0x42
f0104004:	e9 48 08 00 00       	jmp    f0104851 <_alltraps>
f0104009:	90                   	nop

f010400a <handler67>:
TRAPHANDLER_NOEC(handler67, 67)
f010400a:	6a 00                	push   $0x0
f010400c:	6a 43                	push   $0x43
f010400e:	e9 3e 08 00 00       	jmp    f0104851 <_alltraps>
f0104013:	90                   	nop

f0104014 <handler68>:
TRAPHANDLER_NOEC(handler68, 68)
f0104014:	6a 00                	push   $0x0
f0104016:	6a 44                	push   $0x44
f0104018:	e9 34 08 00 00       	jmp    f0104851 <_alltraps>
f010401d:	90                   	nop

f010401e <handler69>:
TRAPHANDLER_NOEC(handler69, 69)
f010401e:	6a 00                	push   $0x0
f0104020:	6a 45                	push   $0x45
f0104022:	e9 2a 08 00 00       	jmp    f0104851 <_alltraps>
f0104027:	90                   	nop

f0104028 <handler70>:
TRAPHANDLER_NOEC(handler70, 70)
f0104028:	6a 00                	push   $0x0
f010402a:	6a 46                	push   $0x46
f010402c:	e9 20 08 00 00       	jmp    f0104851 <_alltraps>
f0104031:	90                   	nop

f0104032 <handler71>:
TRAPHANDLER_NOEC(handler71, 71)
f0104032:	6a 00                	push   $0x0
f0104034:	6a 47                	push   $0x47
f0104036:	e9 16 08 00 00       	jmp    f0104851 <_alltraps>
f010403b:	90                   	nop

f010403c <handler72>:
TRAPHANDLER_NOEC(handler72, 72)
f010403c:	6a 00                	push   $0x0
f010403e:	6a 48                	push   $0x48
f0104040:	e9 0c 08 00 00       	jmp    f0104851 <_alltraps>
f0104045:	90                   	nop

f0104046 <handler73>:
TRAPHANDLER_NOEC(handler73, 73)
f0104046:	6a 00                	push   $0x0
f0104048:	6a 49                	push   $0x49
f010404a:	e9 02 08 00 00       	jmp    f0104851 <_alltraps>
f010404f:	90                   	nop

f0104050 <handler74>:
TRAPHANDLER_NOEC(handler74, 74)
f0104050:	6a 00                	push   $0x0
f0104052:	6a 4a                	push   $0x4a
f0104054:	e9 f8 07 00 00       	jmp    f0104851 <_alltraps>
f0104059:	90                   	nop

f010405a <handler75>:
TRAPHANDLER_NOEC(handler75, 75)
f010405a:	6a 00                	push   $0x0
f010405c:	6a 4b                	push   $0x4b
f010405e:	e9 ee 07 00 00       	jmp    f0104851 <_alltraps>
f0104063:	90                   	nop

f0104064 <handler76>:
TRAPHANDLER_NOEC(handler76, 76)
f0104064:	6a 00                	push   $0x0
f0104066:	6a 4c                	push   $0x4c
f0104068:	e9 e4 07 00 00       	jmp    f0104851 <_alltraps>
f010406d:	90                   	nop

f010406e <handler77>:
TRAPHANDLER_NOEC(handler77, 77)
f010406e:	6a 00                	push   $0x0
f0104070:	6a 4d                	push   $0x4d
f0104072:	e9 da 07 00 00       	jmp    f0104851 <_alltraps>
f0104077:	90                   	nop

f0104078 <handler78>:
TRAPHANDLER_NOEC(handler78, 78)
f0104078:	6a 00                	push   $0x0
f010407a:	6a 4e                	push   $0x4e
f010407c:	e9 d0 07 00 00       	jmp    f0104851 <_alltraps>
f0104081:	90                   	nop

f0104082 <handler79>:
TRAPHANDLER_NOEC(handler79, 79)
f0104082:	6a 00                	push   $0x0
f0104084:	6a 4f                	push   $0x4f
f0104086:	e9 c6 07 00 00       	jmp    f0104851 <_alltraps>
f010408b:	90                   	nop

f010408c <handler80>:
TRAPHANDLER_NOEC(handler80, 80)
f010408c:	6a 00                	push   $0x0
f010408e:	6a 50                	push   $0x50
f0104090:	e9 bc 07 00 00       	jmp    f0104851 <_alltraps>
f0104095:	90                   	nop

f0104096 <handler81>:
TRAPHANDLER_NOEC(handler81, 81)
f0104096:	6a 00                	push   $0x0
f0104098:	6a 51                	push   $0x51
f010409a:	e9 b2 07 00 00       	jmp    f0104851 <_alltraps>
f010409f:	90                   	nop

f01040a0 <handler82>:
TRAPHANDLER_NOEC(handler82, 82)
f01040a0:	6a 00                	push   $0x0
f01040a2:	6a 52                	push   $0x52
f01040a4:	e9 a8 07 00 00       	jmp    f0104851 <_alltraps>
f01040a9:	90                   	nop

f01040aa <handler83>:
TRAPHANDLER_NOEC(handler83, 83)
f01040aa:	6a 00                	push   $0x0
f01040ac:	6a 53                	push   $0x53
f01040ae:	e9 9e 07 00 00       	jmp    f0104851 <_alltraps>
f01040b3:	90                   	nop

f01040b4 <handler84>:
TRAPHANDLER_NOEC(handler84, 84)
f01040b4:	6a 00                	push   $0x0
f01040b6:	6a 54                	push   $0x54
f01040b8:	e9 94 07 00 00       	jmp    f0104851 <_alltraps>
f01040bd:	90                   	nop

f01040be <handler85>:
TRAPHANDLER_NOEC(handler85, 85)
f01040be:	6a 00                	push   $0x0
f01040c0:	6a 55                	push   $0x55
f01040c2:	e9 8a 07 00 00       	jmp    f0104851 <_alltraps>
f01040c7:	90                   	nop

f01040c8 <handler86>:
TRAPHANDLER_NOEC(handler86, 86)
f01040c8:	6a 00                	push   $0x0
f01040ca:	6a 56                	push   $0x56
f01040cc:	e9 80 07 00 00       	jmp    f0104851 <_alltraps>
f01040d1:	90                   	nop

f01040d2 <handler87>:
TRAPHANDLER_NOEC(handler87, 87)
f01040d2:	6a 00                	push   $0x0
f01040d4:	6a 57                	push   $0x57
f01040d6:	e9 76 07 00 00       	jmp    f0104851 <_alltraps>
f01040db:	90                   	nop

f01040dc <handler88>:
TRAPHANDLER_NOEC(handler88, 88)
f01040dc:	6a 00                	push   $0x0
f01040de:	6a 58                	push   $0x58
f01040e0:	e9 6c 07 00 00       	jmp    f0104851 <_alltraps>
f01040e5:	90                   	nop

f01040e6 <handler89>:
TRAPHANDLER_NOEC(handler89, 89)
f01040e6:	6a 00                	push   $0x0
f01040e8:	6a 59                	push   $0x59
f01040ea:	e9 62 07 00 00       	jmp    f0104851 <_alltraps>
f01040ef:	90                   	nop

f01040f0 <handler90>:
TRAPHANDLER_NOEC(handler90, 90)
f01040f0:	6a 00                	push   $0x0
f01040f2:	6a 5a                	push   $0x5a
f01040f4:	e9 58 07 00 00       	jmp    f0104851 <_alltraps>
f01040f9:	90                   	nop

f01040fa <handler91>:
TRAPHANDLER_NOEC(handler91, 91)
f01040fa:	6a 00                	push   $0x0
f01040fc:	6a 5b                	push   $0x5b
f01040fe:	e9 4e 07 00 00       	jmp    f0104851 <_alltraps>
f0104103:	90                   	nop

f0104104 <handler92>:
TRAPHANDLER_NOEC(handler92, 92)
f0104104:	6a 00                	push   $0x0
f0104106:	6a 5c                	push   $0x5c
f0104108:	e9 44 07 00 00       	jmp    f0104851 <_alltraps>
f010410d:	90                   	nop

f010410e <handler93>:
TRAPHANDLER_NOEC(handler93, 93)
f010410e:	6a 00                	push   $0x0
f0104110:	6a 5d                	push   $0x5d
f0104112:	e9 3a 07 00 00       	jmp    f0104851 <_alltraps>
f0104117:	90                   	nop

f0104118 <handler94>:
TRAPHANDLER_NOEC(handler94, 94)
f0104118:	6a 00                	push   $0x0
f010411a:	6a 5e                	push   $0x5e
f010411c:	e9 30 07 00 00       	jmp    f0104851 <_alltraps>
f0104121:	90                   	nop

f0104122 <handler95>:
TRAPHANDLER_NOEC(handler95, 95)
f0104122:	6a 00                	push   $0x0
f0104124:	6a 5f                	push   $0x5f
f0104126:	e9 26 07 00 00       	jmp    f0104851 <_alltraps>
f010412b:	90                   	nop

f010412c <handler96>:
TRAPHANDLER_NOEC(handler96, 96)
f010412c:	6a 00                	push   $0x0
f010412e:	6a 60                	push   $0x60
f0104130:	e9 1c 07 00 00       	jmp    f0104851 <_alltraps>
f0104135:	90                   	nop

f0104136 <handler97>:
TRAPHANDLER_NOEC(handler97, 97)
f0104136:	6a 00                	push   $0x0
f0104138:	6a 61                	push   $0x61
f010413a:	e9 12 07 00 00       	jmp    f0104851 <_alltraps>
f010413f:	90                   	nop

f0104140 <handler98>:
TRAPHANDLER_NOEC(handler98, 98)
f0104140:	6a 00                	push   $0x0
f0104142:	6a 62                	push   $0x62
f0104144:	e9 08 07 00 00       	jmp    f0104851 <_alltraps>
f0104149:	90                   	nop

f010414a <handler99>:
TRAPHANDLER_NOEC(handler99, 99)
f010414a:	6a 00                	push   $0x0
f010414c:	6a 63                	push   $0x63
f010414e:	e9 fe 06 00 00       	jmp    f0104851 <_alltraps>
f0104153:	90                   	nop

f0104154 <handler100>:
TRAPHANDLER_NOEC(handler100, 100)
f0104154:	6a 00                	push   $0x0
f0104156:	6a 64                	push   $0x64
f0104158:	e9 f4 06 00 00       	jmp    f0104851 <_alltraps>
f010415d:	90                   	nop

f010415e <handler101>:
TRAPHANDLER_NOEC(handler101, 101)
f010415e:	6a 00                	push   $0x0
f0104160:	6a 65                	push   $0x65
f0104162:	e9 ea 06 00 00       	jmp    f0104851 <_alltraps>
f0104167:	90                   	nop

f0104168 <handler102>:
TRAPHANDLER_NOEC(handler102, 102)
f0104168:	6a 00                	push   $0x0
f010416a:	6a 66                	push   $0x66
f010416c:	e9 e0 06 00 00       	jmp    f0104851 <_alltraps>
f0104171:	90                   	nop

f0104172 <handler103>:
TRAPHANDLER_NOEC(handler103, 103)
f0104172:	6a 00                	push   $0x0
f0104174:	6a 67                	push   $0x67
f0104176:	e9 d6 06 00 00       	jmp    f0104851 <_alltraps>
f010417b:	90                   	nop

f010417c <handler104>:
TRAPHANDLER_NOEC(handler104, 104)
f010417c:	6a 00                	push   $0x0
f010417e:	6a 68                	push   $0x68
f0104180:	e9 cc 06 00 00       	jmp    f0104851 <_alltraps>
f0104185:	90                   	nop

f0104186 <handler105>:
TRAPHANDLER_NOEC(handler105, 105)
f0104186:	6a 00                	push   $0x0
f0104188:	6a 69                	push   $0x69
f010418a:	e9 c2 06 00 00       	jmp    f0104851 <_alltraps>
f010418f:	90                   	nop

f0104190 <handler106>:
TRAPHANDLER_NOEC(handler106, 106)
f0104190:	6a 00                	push   $0x0
f0104192:	6a 6a                	push   $0x6a
f0104194:	e9 b8 06 00 00       	jmp    f0104851 <_alltraps>
f0104199:	90                   	nop

f010419a <handler107>:
TRAPHANDLER_NOEC(handler107, 107)
f010419a:	6a 00                	push   $0x0
f010419c:	6a 6b                	push   $0x6b
f010419e:	e9 ae 06 00 00       	jmp    f0104851 <_alltraps>
f01041a3:	90                   	nop

f01041a4 <handler108>:
TRAPHANDLER_NOEC(handler108, 108)
f01041a4:	6a 00                	push   $0x0
f01041a6:	6a 6c                	push   $0x6c
f01041a8:	e9 a4 06 00 00       	jmp    f0104851 <_alltraps>
f01041ad:	90                   	nop

f01041ae <handler109>:
TRAPHANDLER_NOEC(handler109, 109)
f01041ae:	6a 00                	push   $0x0
f01041b0:	6a 6d                	push   $0x6d
f01041b2:	e9 9a 06 00 00       	jmp    f0104851 <_alltraps>
f01041b7:	90                   	nop

f01041b8 <handler110>:
TRAPHANDLER_NOEC(handler110, 110)
f01041b8:	6a 00                	push   $0x0
f01041ba:	6a 6e                	push   $0x6e
f01041bc:	e9 90 06 00 00       	jmp    f0104851 <_alltraps>
f01041c1:	90                   	nop

f01041c2 <handler111>:
TRAPHANDLER_NOEC(handler111, 111)
f01041c2:	6a 00                	push   $0x0
f01041c4:	6a 6f                	push   $0x6f
f01041c6:	e9 86 06 00 00       	jmp    f0104851 <_alltraps>
f01041cb:	90                   	nop

f01041cc <handler112>:
TRAPHANDLER_NOEC(handler112, 112)
f01041cc:	6a 00                	push   $0x0
f01041ce:	6a 70                	push   $0x70
f01041d0:	e9 7c 06 00 00       	jmp    f0104851 <_alltraps>
f01041d5:	90                   	nop

f01041d6 <handler113>:
TRAPHANDLER_NOEC(handler113, 113)
f01041d6:	6a 00                	push   $0x0
f01041d8:	6a 71                	push   $0x71
f01041da:	e9 72 06 00 00       	jmp    f0104851 <_alltraps>
f01041df:	90                   	nop

f01041e0 <handler114>:
TRAPHANDLER_NOEC(handler114, 114)
f01041e0:	6a 00                	push   $0x0
f01041e2:	6a 72                	push   $0x72
f01041e4:	e9 68 06 00 00       	jmp    f0104851 <_alltraps>
f01041e9:	90                   	nop

f01041ea <handler115>:
TRAPHANDLER_NOEC(handler115, 115)
f01041ea:	6a 00                	push   $0x0
f01041ec:	6a 73                	push   $0x73
f01041ee:	e9 5e 06 00 00       	jmp    f0104851 <_alltraps>
f01041f3:	90                   	nop

f01041f4 <handler116>:
TRAPHANDLER_NOEC(handler116, 116)
f01041f4:	6a 00                	push   $0x0
f01041f6:	6a 74                	push   $0x74
f01041f8:	e9 54 06 00 00       	jmp    f0104851 <_alltraps>
f01041fd:	90                   	nop

f01041fe <handler117>:
TRAPHANDLER_NOEC(handler117, 117)
f01041fe:	6a 00                	push   $0x0
f0104200:	6a 75                	push   $0x75
f0104202:	e9 4a 06 00 00       	jmp    f0104851 <_alltraps>
f0104207:	90                   	nop

f0104208 <handler118>:
TRAPHANDLER_NOEC(handler118, 118)
f0104208:	6a 00                	push   $0x0
f010420a:	6a 76                	push   $0x76
f010420c:	e9 40 06 00 00       	jmp    f0104851 <_alltraps>
f0104211:	90                   	nop

f0104212 <handler119>:
TRAPHANDLER_NOEC(handler119, 119)
f0104212:	6a 00                	push   $0x0
f0104214:	6a 77                	push   $0x77
f0104216:	e9 36 06 00 00       	jmp    f0104851 <_alltraps>
f010421b:	90                   	nop

f010421c <handler120>:
TRAPHANDLER_NOEC(handler120, 120)
f010421c:	6a 00                	push   $0x0
f010421e:	6a 78                	push   $0x78
f0104220:	e9 2c 06 00 00       	jmp    f0104851 <_alltraps>
f0104225:	90                   	nop

f0104226 <handler121>:
TRAPHANDLER_NOEC(handler121, 121)
f0104226:	6a 00                	push   $0x0
f0104228:	6a 79                	push   $0x79
f010422a:	e9 22 06 00 00       	jmp    f0104851 <_alltraps>
f010422f:	90                   	nop

f0104230 <handler122>:
TRAPHANDLER_NOEC(handler122, 122)
f0104230:	6a 00                	push   $0x0
f0104232:	6a 7a                	push   $0x7a
f0104234:	e9 18 06 00 00       	jmp    f0104851 <_alltraps>
f0104239:	90                   	nop

f010423a <handler123>:
TRAPHANDLER_NOEC(handler123, 123)
f010423a:	6a 00                	push   $0x0
f010423c:	6a 7b                	push   $0x7b
f010423e:	e9 0e 06 00 00       	jmp    f0104851 <_alltraps>
f0104243:	90                   	nop

f0104244 <handler124>:
TRAPHANDLER_NOEC(handler124, 124)
f0104244:	6a 00                	push   $0x0
f0104246:	6a 7c                	push   $0x7c
f0104248:	e9 04 06 00 00       	jmp    f0104851 <_alltraps>
f010424d:	90                   	nop

f010424e <handler125>:
TRAPHANDLER_NOEC(handler125, 125)
f010424e:	6a 00                	push   $0x0
f0104250:	6a 7d                	push   $0x7d
f0104252:	e9 fa 05 00 00       	jmp    f0104851 <_alltraps>
f0104257:	90                   	nop

f0104258 <handler126>:
TRAPHANDLER_NOEC(handler126, 126)
f0104258:	6a 00                	push   $0x0
f010425a:	6a 7e                	push   $0x7e
f010425c:	e9 f0 05 00 00       	jmp    f0104851 <_alltraps>
f0104261:	90                   	nop

f0104262 <handler127>:
TRAPHANDLER_NOEC(handler127, 127)
f0104262:	6a 00                	push   $0x0
f0104264:	6a 7f                	push   $0x7f
f0104266:	e9 e6 05 00 00       	jmp    f0104851 <_alltraps>
f010426b:	90                   	nop

f010426c <handler128>:
TRAPHANDLER_NOEC(handler128, 128)
f010426c:	6a 00                	push   $0x0
f010426e:	68 80 00 00 00       	push   $0x80
f0104273:	e9 d9 05 00 00       	jmp    f0104851 <_alltraps>

f0104278 <handler129>:
TRAPHANDLER_NOEC(handler129, 129)
f0104278:	6a 00                	push   $0x0
f010427a:	68 81 00 00 00       	push   $0x81
f010427f:	e9 cd 05 00 00       	jmp    f0104851 <_alltraps>

f0104284 <handler130>:
TRAPHANDLER_NOEC(handler130, 130)
f0104284:	6a 00                	push   $0x0
f0104286:	68 82 00 00 00       	push   $0x82
f010428b:	e9 c1 05 00 00       	jmp    f0104851 <_alltraps>

f0104290 <handler131>:
TRAPHANDLER_NOEC(handler131, 131)
f0104290:	6a 00                	push   $0x0
f0104292:	68 83 00 00 00       	push   $0x83
f0104297:	e9 b5 05 00 00       	jmp    f0104851 <_alltraps>

f010429c <handler132>:
TRAPHANDLER_NOEC(handler132, 132)
f010429c:	6a 00                	push   $0x0
f010429e:	68 84 00 00 00       	push   $0x84
f01042a3:	e9 a9 05 00 00       	jmp    f0104851 <_alltraps>

f01042a8 <handler133>:
TRAPHANDLER_NOEC(handler133, 133)
f01042a8:	6a 00                	push   $0x0
f01042aa:	68 85 00 00 00       	push   $0x85
f01042af:	e9 9d 05 00 00       	jmp    f0104851 <_alltraps>

f01042b4 <handler134>:
TRAPHANDLER_NOEC(handler134, 134)
f01042b4:	6a 00                	push   $0x0
f01042b6:	68 86 00 00 00       	push   $0x86
f01042bb:	e9 91 05 00 00       	jmp    f0104851 <_alltraps>

f01042c0 <handler135>:
TRAPHANDLER_NOEC(handler135, 135)
f01042c0:	6a 00                	push   $0x0
f01042c2:	68 87 00 00 00       	push   $0x87
f01042c7:	e9 85 05 00 00       	jmp    f0104851 <_alltraps>

f01042cc <handler136>:
TRAPHANDLER_NOEC(handler136, 136)
f01042cc:	6a 00                	push   $0x0
f01042ce:	68 88 00 00 00       	push   $0x88
f01042d3:	e9 79 05 00 00       	jmp    f0104851 <_alltraps>

f01042d8 <handler137>:
TRAPHANDLER_NOEC(handler137, 137)
f01042d8:	6a 00                	push   $0x0
f01042da:	68 89 00 00 00       	push   $0x89
f01042df:	e9 6d 05 00 00       	jmp    f0104851 <_alltraps>

f01042e4 <handler138>:
TRAPHANDLER_NOEC(handler138, 138)
f01042e4:	6a 00                	push   $0x0
f01042e6:	68 8a 00 00 00       	push   $0x8a
f01042eb:	e9 61 05 00 00       	jmp    f0104851 <_alltraps>

f01042f0 <handler139>:
TRAPHANDLER_NOEC(handler139, 139)
f01042f0:	6a 00                	push   $0x0
f01042f2:	68 8b 00 00 00       	push   $0x8b
f01042f7:	e9 55 05 00 00       	jmp    f0104851 <_alltraps>

f01042fc <handler140>:
TRAPHANDLER_NOEC(handler140, 140)
f01042fc:	6a 00                	push   $0x0
f01042fe:	68 8c 00 00 00       	push   $0x8c
f0104303:	e9 49 05 00 00       	jmp    f0104851 <_alltraps>

f0104308 <handler141>:
TRAPHANDLER_NOEC(handler141, 141)
f0104308:	6a 00                	push   $0x0
f010430a:	68 8d 00 00 00       	push   $0x8d
f010430f:	e9 3d 05 00 00       	jmp    f0104851 <_alltraps>

f0104314 <handler142>:
TRAPHANDLER_NOEC(handler142, 142)
f0104314:	6a 00                	push   $0x0
f0104316:	68 8e 00 00 00       	push   $0x8e
f010431b:	e9 31 05 00 00       	jmp    f0104851 <_alltraps>

f0104320 <handler143>:
TRAPHANDLER_NOEC(handler143, 143)
f0104320:	6a 00                	push   $0x0
f0104322:	68 8f 00 00 00       	push   $0x8f
f0104327:	e9 25 05 00 00       	jmp    f0104851 <_alltraps>

f010432c <handler144>:
TRAPHANDLER_NOEC(handler144, 144)
f010432c:	6a 00                	push   $0x0
f010432e:	68 90 00 00 00       	push   $0x90
f0104333:	e9 19 05 00 00       	jmp    f0104851 <_alltraps>

f0104338 <handler145>:
TRAPHANDLER_NOEC(handler145, 145)
f0104338:	6a 00                	push   $0x0
f010433a:	68 91 00 00 00       	push   $0x91
f010433f:	e9 0d 05 00 00       	jmp    f0104851 <_alltraps>

f0104344 <handler146>:
TRAPHANDLER_NOEC(handler146, 146)
f0104344:	6a 00                	push   $0x0
f0104346:	68 92 00 00 00       	push   $0x92
f010434b:	e9 01 05 00 00       	jmp    f0104851 <_alltraps>

f0104350 <handler147>:
TRAPHANDLER_NOEC(handler147, 147)
f0104350:	6a 00                	push   $0x0
f0104352:	68 93 00 00 00       	push   $0x93
f0104357:	e9 f5 04 00 00       	jmp    f0104851 <_alltraps>

f010435c <handler148>:
TRAPHANDLER_NOEC(handler148, 148)
f010435c:	6a 00                	push   $0x0
f010435e:	68 94 00 00 00       	push   $0x94
f0104363:	e9 e9 04 00 00       	jmp    f0104851 <_alltraps>

f0104368 <handler149>:
TRAPHANDLER_NOEC(handler149, 149)
f0104368:	6a 00                	push   $0x0
f010436a:	68 95 00 00 00       	push   $0x95
f010436f:	e9 dd 04 00 00       	jmp    f0104851 <_alltraps>

f0104374 <handler150>:
TRAPHANDLER_NOEC(handler150, 150)
f0104374:	6a 00                	push   $0x0
f0104376:	68 96 00 00 00       	push   $0x96
f010437b:	e9 d1 04 00 00       	jmp    f0104851 <_alltraps>

f0104380 <handler151>:
TRAPHANDLER_NOEC(handler151, 151)
f0104380:	6a 00                	push   $0x0
f0104382:	68 97 00 00 00       	push   $0x97
f0104387:	e9 c5 04 00 00       	jmp    f0104851 <_alltraps>

f010438c <handler152>:
TRAPHANDLER_NOEC(handler152, 152)
f010438c:	6a 00                	push   $0x0
f010438e:	68 98 00 00 00       	push   $0x98
f0104393:	e9 b9 04 00 00       	jmp    f0104851 <_alltraps>

f0104398 <handler153>:
TRAPHANDLER_NOEC(handler153, 153)
f0104398:	6a 00                	push   $0x0
f010439a:	68 99 00 00 00       	push   $0x99
f010439f:	e9 ad 04 00 00       	jmp    f0104851 <_alltraps>

f01043a4 <handler154>:
TRAPHANDLER_NOEC(handler154, 154)
f01043a4:	6a 00                	push   $0x0
f01043a6:	68 9a 00 00 00       	push   $0x9a
f01043ab:	e9 a1 04 00 00       	jmp    f0104851 <_alltraps>

f01043b0 <handler155>:
TRAPHANDLER_NOEC(handler155, 155)
f01043b0:	6a 00                	push   $0x0
f01043b2:	68 9b 00 00 00       	push   $0x9b
f01043b7:	e9 95 04 00 00       	jmp    f0104851 <_alltraps>

f01043bc <handler156>:
TRAPHANDLER_NOEC(handler156, 156)
f01043bc:	6a 00                	push   $0x0
f01043be:	68 9c 00 00 00       	push   $0x9c
f01043c3:	e9 89 04 00 00       	jmp    f0104851 <_alltraps>

f01043c8 <handler157>:
TRAPHANDLER_NOEC(handler157, 157)
f01043c8:	6a 00                	push   $0x0
f01043ca:	68 9d 00 00 00       	push   $0x9d
f01043cf:	e9 7d 04 00 00       	jmp    f0104851 <_alltraps>

f01043d4 <handler158>:
TRAPHANDLER_NOEC(handler158, 158)
f01043d4:	6a 00                	push   $0x0
f01043d6:	68 9e 00 00 00       	push   $0x9e
f01043db:	e9 71 04 00 00       	jmp    f0104851 <_alltraps>

f01043e0 <handler159>:
TRAPHANDLER_NOEC(handler159, 159)
f01043e0:	6a 00                	push   $0x0
f01043e2:	68 9f 00 00 00       	push   $0x9f
f01043e7:	e9 65 04 00 00       	jmp    f0104851 <_alltraps>

f01043ec <handler160>:
TRAPHANDLER_NOEC(handler160, 160)
f01043ec:	6a 00                	push   $0x0
f01043ee:	68 a0 00 00 00       	push   $0xa0
f01043f3:	e9 59 04 00 00       	jmp    f0104851 <_alltraps>

f01043f8 <handler161>:
TRAPHANDLER_NOEC(handler161, 161)
f01043f8:	6a 00                	push   $0x0
f01043fa:	68 a1 00 00 00       	push   $0xa1
f01043ff:	e9 4d 04 00 00       	jmp    f0104851 <_alltraps>

f0104404 <handler162>:
TRAPHANDLER_NOEC(handler162, 162)
f0104404:	6a 00                	push   $0x0
f0104406:	68 a2 00 00 00       	push   $0xa2
f010440b:	e9 41 04 00 00       	jmp    f0104851 <_alltraps>

f0104410 <handler163>:
TRAPHANDLER_NOEC(handler163, 163)
f0104410:	6a 00                	push   $0x0
f0104412:	68 a3 00 00 00       	push   $0xa3
f0104417:	e9 35 04 00 00       	jmp    f0104851 <_alltraps>

f010441c <handler164>:
TRAPHANDLER_NOEC(handler164, 164)
f010441c:	6a 00                	push   $0x0
f010441e:	68 a4 00 00 00       	push   $0xa4
f0104423:	e9 29 04 00 00       	jmp    f0104851 <_alltraps>

f0104428 <handler165>:
TRAPHANDLER_NOEC(handler165, 165)
f0104428:	6a 00                	push   $0x0
f010442a:	68 a5 00 00 00       	push   $0xa5
f010442f:	e9 1d 04 00 00       	jmp    f0104851 <_alltraps>

f0104434 <handler166>:
TRAPHANDLER_NOEC(handler166, 166)
f0104434:	6a 00                	push   $0x0
f0104436:	68 a6 00 00 00       	push   $0xa6
f010443b:	e9 11 04 00 00       	jmp    f0104851 <_alltraps>

f0104440 <handler167>:
TRAPHANDLER_NOEC(handler167, 167)
f0104440:	6a 00                	push   $0x0
f0104442:	68 a7 00 00 00       	push   $0xa7
f0104447:	e9 05 04 00 00       	jmp    f0104851 <_alltraps>

f010444c <handler168>:
TRAPHANDLER_NOEC(handler168, 168)
f010444c:	6a 00                	push   $0x0
f010444e:	68 a8 00 00 00       	push   $0xa8
f0104453:	e9 f9 03 00 00       	jmp    f0104851 <_alltraps>

f0104458 <handler169>:
TRAPHANDLER_NOEC(handler169, 169)
f0104458:	6a 00                	push   $0x0
f010445a:	68 a9 00 00 00       	push   $0xa9
f010445f:	e9 ed 03 00 00       	jmp    f0104851 <_alltraps>

f0104464 <handler170>:
TRAPHANDLER_NOEC(handler170, 170)
f0104464:	6a 00                	push   $0x0
f0104466:	68 aa 00 00 00       	push   $0xaa
f010446b:	e9 e1 03 00 00       	jmp    f0104851 <_alltraps>

f0104470 <handler171>:
TRAPHANDLER_NOEC(handler171, 171)
f0104470:	6a 00                	push   $0x0
f0104472:	68 ab 00 00 00       	push   $0xab
f0104477:	e9 d5 03 00 00       	jmp    f0104851 <_alltraps>

f010447c <handler172>:
TRAPHANDLER_NOEC(handler172, 172)
f010447c:	6a 00                	push   $0x0
f010447e:	68 ac 00 00 00       	push   $0xac
f0104483:	e9 c9 03 00 00       	jmp    f0104851 <_alltraps>

f0104488 <handler173>:
TRAPHANDLER_NOEC(handler173, 173)
f0104488:	6a 00                	push   $0x0
f010448a:	68 ad 00 00 00       	push   $0xad
f010448f:	e9 bd 03 00 00       	jmp    f0104851 <_alltraps>

f0104494 <handler174>:
TRAPHANDLER_NOEC(handler174, 174)
f0104494:	6a 00                	push   $0x0
f0104496:	68 ae 00 00 00       	push   $0xae
f010449b:	e9 b1 03 00 00       	jmp    f0104851 <_alltraps>

f01044a0 <handler175>:
TRAPHANDLER_NOEC(handler175, 175)
f01044a0:	6a 00                	push   $0x0
f01044a2:	68 af 00 00 00       	push   $0xaf
f01044a7:	e9 a5 03 00 00       	jmp    f0104851 <_alltraps>

f01044ac <handler176>:
TRAPHANDLER_NOEC(handler176, 176)
f01044ac:	6a 00                	push   $0x0
f01044ae:	68 b0 00 00 00       	push   $0xb0
f01044b3:	e9 99 03 00 00       	jmp    f0104851 <_alltraps>

f01044b8 <handler177>:
TRAPHANDLER_NOEC(handler177, 177)
f01044b8:	6a 00                	push   $0x0
f01044ba:	68 b1 00 00 00       	push   $0xb1
f01044bf:	e9 8d 03 00 00       	jmp    f0104851 <_alltraps>

f01044c4 <handler178>:
TRAPHANDLER_NOEC(handler178, 178)
f01044c4:	6a 00                	push   $0x0
f01044c6:	68 b2 00 00 00       	push   $0xb2
f01044cb:	e9 81 03 00 00       	jmp    f0104851 <_alltraps>

f01044d0 <handler179>:
TRAPHANDLER_NOEC(handler179, 179)
f01044d0:	6a 00                	push   $0x0
f01044d2:	68 b3 00 00 00       	push   $0xb3
f01044d7:	e9 75 03 00 00       	jmp    f0104851 <_alltraps>

f01044dc <handler180>:
TRAPHANDLER_NOEC(handler180, 180)
f01044dc:	6a 00                	push   $0x0
f01044de:	68 b4 00 00 00       	push   $0xb4
f01044e3:	e9 69 03 00 00       	jmp    f0104851 <_alltraps>

f01044e8 <handler181>:
TRAPHANDLER_NOEC(handler181, 181)
f01044e8:	6a 00                	push   $0x0
f01044ea:	68 b5 00 00 00       	push   $0xb5
f01044ef:	e9 5d 03 00 00       	jmp    f0104851 <_alltraps>

f01044f4 <handler182>:
TRAPHANDLER_NOEC(handler182, 182)
f01044f4:	6a 00                	push   $0x0
f01044f6:	68 b6 00 00 00       	push   $0xb6
f01044fb:	e9 51 03 00 00       	jmp    f0104851 <_alltraps>

f0104500 <handler183>:
TRAPHANDLER_NOEC(handler183, 183)
f0104500:	6a 00                	push   $0x0
f0104502:	68 b7 00 00 00       	push   $0xb7
f0104507:	e9 45 03 00 00       	jmp    f0104851 <_alltraps>

f010450c <handler184>:
TRAPHANDLER_NOEC(handler184, 184)
f010450c:	6a 00                	push   $0x0
f010450e:	68 b8 00 00 00       	push   $0xb8
f0104513:	e9 39 03 00 00       	jmp    f0104851 <_alltraps>

f0104518 <handler185>:
TRAPHANDLER_NOEC(handler185, 185)
f0104518:	6a 00                	push   $0x0
f010451a:	68 b9 00 00 00       	push   $0xb9
f010451f:	e9 2d 03 00 00       	jmp    f0104851 <_alltraps>

f0104524 <handler186>:
TRAPHANDLER_NOEC(handler186, 186)
f0104524:	6a 00                	push   $0x0
f0104526:	68 ba 00 00 00       	push   $0xba
f010452b:	e9 21 03 00 00       	jmp    f0104851 <_alltraps>

f0104530 <handler187>:
TRAPHANDLER_NOEC(handler187, 187)
f0104530:	6a 00                	push   $0x0
f0104532:	68 bb 00 00 00       	push   $0xbb
f0104537:	e9 15 03 00 00       	jmp    f0104851 <_alltraps>

f010453c <handler188>:
TRAPHANDLER_NOEC(handler188, 188)
f010453c:	6a 00                	push   $0x0
f010453e:	68 bc 00 00 00       	push   $0xbc
f0104543:	e9 09 03 00 00       	jmp    f0104851 <_alltraps>

f0104548 <handler189>:
TRAPHANDLER_NOEC(handler189, 189)
f0104548:	6a 00                	push   $0x0
f010454a:	68 bd 00 00 00       	push   $0xbd
f010454f:	e9 fd 02 00 00       	jmp    f0104851 <_alltraps>

f0104554 <handler190>:
TRAPHANDLER_NOEC(handler190, 190)
f0104554:	6a 00                	push   $0x0
f0104556:	68 be 00 00 00       	push   $0xbe
f010455b:	e9 f1 02 00 00       	jmp    f0104851 <_alltraps>

f0104560 <handler191>:
TRAPHANDLER_NOEC(handler191, 191)
f0104560:	6a 00                	push   $0x0
f0104562:	68 bf 00 00 00       	push   $0xbf
f0104567:	e9 e5 02 00 00       	jmp    f0104851 <_alltraps>

f010456c <handler192>:
TRAPHANDLER_NOEC(handler192, 192)
f010456c:	6a 00                	push   $0x0
f010456e:	68 c0 00 00 00       	push   $0xc0
f0104573:	e9 d9 02 00 00       	jmp    f0104851 <_alltraps>

f0104578 <handler193>:
TRAPHANDLER_NOEC(handler193, 193)
f0104578:	6a 00                	push   $0x0
f010457a:	68 c1 00 00 00       	push   $0xc1
f010457f:	e9 cd 02 00 00       	jmp    f0104851 <_alltraps>

f0104584 <handler194>:
TRAPHANDLER_NOEC(handler194, 194)
f0104584:	6a 00                	push   $0x0
f0104586:	68 c2 00 00 00       	push   $0xc2
f010458b:	e9 c1 02 00 00       	jmp    f0104851 <_alltraps>

f0104590 <handler195>:
TRAPHANDLER_NOEC(handler195, 195)
f0104590:	6a 00                	push   $0x0
f0104592:	68 c3 00 00 00       	push   $0xc3
f0104597:	e9 b5 02 00 00       	jmp    f0104851 <_alltraps>

f010459c <handler196>:
TRAPHANDLER_NOEC(handler196, 196)
f010459c:	6a 00                	push   $0x0
f010459e:	68 c4 00 00 00       	push   $0xc4
f01045a3:	e9 a9 02 00 00       	jmp    f0104851 <_alltraps>

f01045a8 <handler197>:
TRAPHANDLER_NOEC(handler197, 197)
f01045a8:	6a 00                	push   $0x0
f01045aa:	68 c5 00 00 00       	push   $0xc5
f01045af:	e9 9d 02 00 00       	jmp    f0104851 <_alltraps>

f01045b4 <handler198>:
TRAPHANDLER_NOEC(handler198, 198)
f01045b4:	6a 00                	push   $0x0
f01045b6:	68 c6 00 00 00       	push   $0xc6
f01045bb:	e9 91 02 00 00       	jmp    f0104851 <_alltraps>

f01045c0 <handler199>:
TRAPHANDLER_NOEC(handler199, 199)
f01045c0:	6a 00                	push   $0x0
f01045c2:	68 c7 00 00 00       	push   $0xc7
f01045c7:	e9 85 02 00 00       	jmp    f0104851 <_alltraps>

f01045cc <handler200>:
TRAPHANDLER_NOEC(handler200, 200)
f01045cc:	6a 00                	push   $0x0
f01045ce:	68 c8 00 00 00       	push   $0xc8
f01045d3:	e9 79 02 00 00       	jmp    f0104851 <_alltraps>

f01045d8 <handler201>:
TRAPHANDLER_NOEC(handler201, 201)
f01045d8:	6a 00                	push   $0x0
f01045da:	68 c9 00 00 00       	push   $0xc9
f01045df:	e9 6d 02 00 00       	jmp    f0104851 <_alltraps>

f01045e4 <handler202>:
TRAPHANDLER_NOEC(handler202, 202)
f01045e4:	6a 00                	push   $0x0
f01045e6:	68 ca 00 00 00       	push   $0xca
f01045eb:	e9 61 02 00 00       	jmp    f0104851 <_alltraps>

f01045f0 <handler203>:
TRAPHANDLER_NOEC(handler203, 203)
f01045f0:	6a 00                	push   $0x0
f01045f2:	68 cb 00 00 00       	push   $0xcb
f01045f7:	e9 55 02 00 00       	jmp    f0104851 <_alltraps>

f01045fc <handler204>:
TRAPHANDLER_NOEC(handler204, 204)
f01045fc:	6a 00                	push   $0x0
f01045fe:	68 cc 00 00 00       	push   $0xcc
f0104603:	e9 49 02 00 00       	jmp    f0104851 <_alltraps>

f0104608 <handler205>:
TRAPHANDLER_NOEC(handler205, 205)
f0104608:	6a 00                	push   $0x0
f010460a:	68 cd 00 00 00       	push   $0xcd
f010460f:	e9 3d 02 00 00       	jmp    f0104851 <_alltraps>

f0104614 <handler206>:
TRAPHANDLER_NOEC(handler206, 206)
f0104614:	6a 00                	push   $0x0
f0104616:	68 ce 00 00 00       	push   $0xce
f010461b:	e9 31 02 00 00       	jmp    f0104851 <_alltraps>

f0104620 <handler207>:
TRAPHANDLER_NOEC(handler207, 207)
f0104620:	6a 00                	push   $0x0
f0104622:	68 cf 00 00 00       	push   $0xcf
f0104627:	e9 25 02 00 00       	jmp    f0104851 <_alltraps>

f010462c <handler208>:
TRAPHANDLER_NOEC(handler208, 208)
f010462c:	6a 00                	push   $0x0
f010462e:	68 d0 00 00 00       	push   $0xd0
f0104633:	e9 19 02 00 00       	jmp    f0104851 <_alltraps>

f0104638 <handler209>:
TRAPHANDLER_NOEC(handler209, 209)
f0104638:	6a 00                	push   $0x0
f010463a:	68 d1 00 00 00       	push   $0xd1
f010463f:	e9 0d 02 00 00       	jmp    f0104851 <_alltraps>

f0104644 <handler210>:
TRAPHANDLER_NOEC(handler210, 210)
f0104644:	6a 00                	push   $0x0
f0104646:	68 d2 00 00 00       	push   $0xd2
f010464b:	e9 01 02 00 00       	jmp    f0104851 <_alltraps>

f0104650 <handler211>:
TRAPHANDLER_NOEC(handler211, 211)
f0104650:	6a 00                	push   $0x0
f0104652:	68 d3 00 00 00       	push   $0xd3
f0104657:	e9 f5 01 00 00       	jmp    f0104851 <_alltraps>

f010465c <handler212>:
TRAPHANDLER_NOEC(handler212, 212)
f010465c:	6a 00                	push   $0x0
f010465e:	68 d4 00 00 00       	push   $0xd4
f0104663:	e9 e9 01 00 00       	jmp    f0104851 <_alltraps>

f0104668 <handler213>:
TRAPHANDLER_NOEC(handler213, 213)
f0104668:	6a 00                	push   $0x0
f010466a:	68 d5 00 00 00       	push   $0xd5
f010466f:	e9 dd 01 00 00       	jmp    f0104851 <_alltraps>

f0104674 <handler214>:
TRAPHANDLER_NOEC(handler214, 214)
f0104674:	6a 00                	push   $0x0
f0104676:	68 d6 00 00 00       	push   $0xd6
f010467b:	e9 d1 01 00 00       	jmp    f0104851 <_alltraps>

f0104680 <handler215>:
TRAPHANDLER_NOEC(handler215, 215)
f0104680:	6a 00                	push   $0x0
f0104682:	68 d7 00 00 00       	push   $0xd7
f0104687:	e9 c5 01 00 00       	jmp    f0104851 <_alltraps>

f010468c <handler216>:
TRAPHANDLER_NOEC(handler216, 216)
f010468c:	6a 00                	push   $0x0
f010468e:	68 d8 00 00 00       	push   $0xd8
f0104693:	e9 b9 01 00 00       	jmp    f0104851 <_alltraps>

f0104698 <handler217>:
TRAPHANDLER_NOEC(handler217, 217)
f0104698:	6a 00                	push   $0x0
f010469a:	68 d9 00 00 00       	push   $0xd9
f010469f:	e9 ad 01 00 00       	jmp    f0104851 <_alltraps>

f01046a4 <handler218>:
TRAPHANDLER_NOEC(handler218, 218)
f01046a4:	6a 00                	push   $0x0
f01046a6:	68 da 00 00 00       	push   $0xda
f01046ab:	e9 a1 01 00 00       	jmp    f0104851 <_alltraps>

f01046b0 <handler219>:
TRAPHANDLER_NOEC(handler219, 219)
f01046b0:	6a 00                	push   $0x0
f01046b2:	68 db 00 00 00       	push   $0xdb
f01046b7:	e9 95 01 00 00       	jmp    f0104851 <_alltraps>

f01046bc <handler220>:
TRAPHANDLER_NOEC(handler220, 220)
f01046bc:	6a 00                	push   $0x0
f01046be:	68 dc 00 00 00       	push   $0xdc
f01046c3:	e9 89 01 00 00       	jmp    f0104851 <_alltraps>

f01046c8 <handler221>:
TRAPHANDLER_NOEC(handler221, 221)
f01046c8:	6a 00                	push   $0x0
f01046ca:	68 dd 00 00 00       	push   $0xdd
f01046cf:	e9 7d 01 00 00       	jmp    f0104851 <_alltraps>

f01046d4 <handler222>:
TRAPHANDLER_NOEC(handler222, 222)
f01046d4:	6a 00                	push   $0x0
f01046d6:	68 de 00 00 00       	push   $0xde
f01046db:	e9 71 01 00 00       	jmp    f0104851 <_alltraps>

f01046e0 <handler223>:
TRAPHANDLER_NOEC(handler223, 223)
f01046e0:	6a 00                	push   $0x0
f01046e2:	68 df 00 00 00       	push   $0xdf
f01046e7:	e9 65 01 00 00       	jmp    f0104851 <_alltraps>

f01046ec <handler224>:
TRAPHANDLER_NOEC(handler224, 224)
f01046ec:	6a 00                	push   $0x0
f01046ee:	68 e0 00 00 00       	push   $0xe0
f01046f3:	e9 59 01 00 00       	jmp    f0104851 <_alltraps>

f01046f8 <handler225>:
TRAPHANDLER_NOEC(handler225, 225)
f01046f8:	6a 00                	push   $0x0
f01046fa:	68 e1 00 00 00       	push   $0xe1
f01046ff:	e9 4d 01 00 00       	jmp    f0104851 <_alltraps>

f0104704 <handler226>:
TRAPHANDLER_NOEC(handler226, 226)
f0104704:	6a 00                	push   $0x0
f0104706:	68 e2 00 00 00       	push   $0xe2
f010470b:	e9 41 01 00 00       	jmp    f0104851 <_alltraps>

f0104710 <handler227>:
TRAPHANDLER_NOEC(handler227, 227)
f0104710:	6a 00                	push   $0x0
f0104712:	68 e3 00 00 00       	push   $0xe3
f0104717:	e9 35 01 00 00       	jmp    f0104851 <_alltraps>

f010471c <handler228>:
TRAPHANDLER_NOEC(handler228, 228)
f010471c:	6a 00                	push   $0x0
f010471e:	68 e4 00 00 00       	push   $0xe4
f0104723:	e9 29 01 00 00       	jmp    f0104851 <_alltraps>

f0104728 <handler229>:
TRAPHANDLER_NOEC(handler229, 229)
f0104728:	6a 00                	push   $0x0
f010472a:	68 e5 00 00 00       	push   $0xe5
f010472f:	e9 1d 01 00 00       	jmp    f0104851 <_alltraps>

f0104734 <handler230>:
TRAPHANDLER_NOEC(handler230, 230)
f0104734:	6a 00                	push   $0x0
f0104736:	68 e6 00 00 00       	push   $0xe6
f010473b:	e9 11 01 00 00       	jmp    f0104851 <_alltraps>

f0104740 <handler231>:
TRAPHANDLER_NOEC(handler231, 231)
f0104740:	6a 00                	push   $0x0
f0104742:	68 e7 00 00 00       	push   $0xe7
f0104747:	e9 05 01 00 00       	jmp    f0104851 <_alltraps>

f010474c <handler232>:
TRAPHANDLER_NOEC(handler232, 232)
f010474c:	6a 00                	push   $0x0
f010474e:	68 e8 00 00 00       	push   $0xe8
f0104753:	e9 f9 00 00 00       	jmp    f0104851 <_alltraps>

f0104758 <handler233>:
TRAPHANDLER_NOEC(handler233, 233)
f0104758:	6a 00                	push   $0x0
f010475a:	68 e9 00 00 00       	push   $0xe9
f010475f:	e9 ed 00 00 00       	jmp    f0104851 <_alltraps>

f0104764 <handler234>:
TRAPHANDLER_NOEC(handler234, 234)
f0104764:	6a 00                	push   $0x0
f0104766:	68 ea 00 00 00       	push   $0xea
f010476b:	e9 e1 00 00 00       	jmp    f0104851 <_alltraps>

f0104770 <handler235>:
TRAPHANDLER_NOEC(handler235, 235)
f0104770:	6a 00                	push   $0x0
f0104772:	68 eb 00 00 00       	push   $0xeb
f0104777:	e9 d5 00 00 00       	jmp    f0104851 <_alltraps>

f010477c <handler236>:
TRAPHANDLER_NOEC(handler236, 236)
f010477c:	6a 00                	push   $0x0
f010477e:	68 ec 00 00 00       	push   $0xec
f0104783:	e9 c9 00 00 00       	jmp    f0104851 <_alltraps>

f0104788 <handler237>:
TRAPHANDLER_NOEC(handler237, 237)
f0104788:	6a 00                	push   $0x0
f010478a:	68 ed 00 00 00       	push   $0xed
f010478f:	e9 bd 00 00 00       	jmp    f0104851 <_alltraps>

f0104794 <handler238>:
TRAPHANDLER_NOEC(handler238, 238)
f0104794:	6a 00                	push   $0x0
f0104796:	68 ee 00 00 00       	push   $0xee
f010479b:	e9 b1 00 00 00       	jmp    f0104851 <_alltraps>

f01047a0 <handler239>:
TRAPHANDLER_NOEC(handler239, 239)
f01047a0:	6a 00                	push   $0x0
f01047a2:	68 ef 00 00 00       	push   $0xef
f01047a7:	e9 a5 00 00 00       	jmp    f0104851 <_alltraps>

f01047ac <handler240>:
TRAPHANDLER_NOEC(handler240, 240)
f01047ac:	6a 00                	push   $0x0
f01047ae:	68 f0 00 00 00       	push   $0xf0
f01047b3:	e9 99 00 00 00       	jmp    f0104851 <_alltraps>

f01047b8 <handler241>:
TRAPHANDLER_NOEC(handler241, 241)
f01047b8:	6a 00                	push   $0x0
f01047ba:	68 f1 00 00 00       	push   $0xf1
f01047bf:	e9 8d 00 00 00       	jmp    f0104851 <_alltraps>

f01047c4 <handler242>:
TRAPHANDLER_NOEC(handler242, 242)
f01047c4:	6a 00                	push   $0x0
f01047c6:	68 f2 00 00 00       	push   $0xf2
f01047cb:	e9 81 00 00 00       	jmp    f0104851 <_alltraps>

f01047d0 <handler243>:
TRAPHANDLER_NOEC(handler243, 243)
f01047d0:	6a 00                	push   $0x0
f01047d2:	68 f3 00 00 00       	push   $0xf3
f01047d7:	eb 78                	jmp    f0104851 <_alltraps>
f01047d9:	90                   	nop

f01047da <handler244>:
TRAPHANDLER_NOEC(handler244, 244)
f01047da:	6a 00                	push   $0x0
f01047dc:	68 f4 00 00 00       	push   $0xf4
f01047e1:	eb 6e                	jmp    f0104851 <_alltraps>
f01047e3:	90                   	nop

f01047e4 <handler245>:
TRAPHANDLER_NOEC(handler245, 245)
f01047e4:	6a 00                	push   $0x0
f01047e6:	68 f5 00 00 00       	push   $0xf5
f01047eb:	eb 64                	jmp    f0104851 <_alltraps>
f01047ed:	90                   	nop

f01047ee <handler246>:
TRAPHANDLER_NOEC(handler246, 246)
f01047ee:	6a 00                	push   $0x0
f01047f0:	68 f6 00 00 00       	push   $0xf6
f01047f5:	eb 5a                	jmp    f0104851 <_alltraps>
f01047f7:	90                   	nop

f01047f8 <handler247>:
TRAPHANDLER_NOEC(handler247, 247)
f01047f8:	6a 00                	push   $0x0
f01047fa:	68 f7 00 00 00       	push   $0xf7
f01047ff:	eb 50                	jmp    f0104851 <_alltraps>
f0104801:	90                   	nop

f0104802 <handler248>:
TRAPHANDLER_NOEC(handler248, 248)
f0104802:	6a 00                	push   $0x0
f0104804:	68 f8 00 00 00       	push   $0xf8
f0104809:	eb 46                	jmp    f0104851 <_alltraps>
f010480b:	90                   	nop

f010480c <handler249>:
TRAPHANDLER_NOEC(handler249, 249)
f010480c:	6a 00                	push   $0x0
f010480e:	68 f9 00 00 00       	push   $0xf9
f0104813:	eb 3c                	jmp    f0104851 <_alltraps>
f0104815:	90                   	nop

f0104816 <handler250>:
TRAPHANDLER_NOEC(handler250, 250)
f0104816:	6a 00                	push   $0x0
f0104818:	68 fa 00 00 00       	push   $0xfa
f010481d:	eb 32                	jmp    f0104851 <_alltraps>
f010481f:	90                   	nop

f0104820 <handler251>:
TRAPHANDLER_NOEC(handler251, 251)
f0104820:	6a 00                	push   $0x0
f0104822:	68 fb 00 00 00       	push   $0xfb
f0104827:	eb 28                	jmp    f0104851 <_alltraps>
f0104829:	90                   	nop

f010482a <handler252>:
TRAPHANDLER_NOEC(handler252, 252)
f010482a:	6a 00                	push   $0x0
f010482c:	68 fc 00 00 00       	push   $0xfc
f0104831:	eb 1e                	jmp    f0104851 <_alltraps>
f0104833:	90                   	nop

f0104834 <handler253>:
TRAPHANDLER_NOEC(handler253, 253)
f0104834:	6a 00                	push   $0x0
f0104836:	68 fd 00 00 00       	push   $0xfd
f010483b:	eb 14                	jmp    f0104851 <_alltraps>
f010483d:	90                   	nop

f010483e <handler254>:
TRAPHANDLER_NOEC(handler254, 254)
f010483e:	6a 00                	push   $0x0
f0104840:	68 fe 00 00 00       	push   $0xfe
f0104845:	eb 0a                	jmp    f0104851 <_alltraps>
f0104847:	90                   	nop

f0104848 <handler255>:
TRAPHANDLER_NOEC(handler255, 255)
f0104848:	6a 00                	push   $0x0
f010484a:	68 ff 00 00 00       	push   $0xff
f010484f:	eb 00                	jmp    f0104851 <_alltraps>

f0104851 <_alltraps>:

/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	push %ds
f0104851:	1e                   	push   %ds
	push %es
f0104852:	06                   	push   %es
	pushal
f0104853:	60                   	pusha  

	mov $GD_KD, %ax
f0104854:	66 b8 10 00          	mov    $0x10,%ax
	mov %ax, %ds
f0104858:	8e d8                	mov    %eax,%ds
	mov %ax, %es
f010485a:	8e c0                	mov    %eax,%es

	# trap(Trapframe *tf)
	pushl %esp
f010485c:	54                   	push   %esp
	call trap
f010485d:	e8 06 f3 ff ff       	call   f0103b68 <trap>

f0104862 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0104862:	55                   	push   %ebp
f0104863:	89 e5                	mov    %esp,%ebp
f0104865:	83 ec 08             	sub    $0x8,%esp
f0104868:	a1 48 c2 22 f0       	mov    0xf022c248,%eax
f010486d:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104870:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0104875:	8b 02                	mov    (%edx),%eax
f0104877:	83 e8 01             	sub    $0x1,%eax
f010487a:	83 f8 02             	cmp    $0x2,%eax
f010487d:	76 10                	jbe    f010488f <sched_halt+0x2d>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f010487f:	83 c1 01             	add    $0x1,%ecx
f0104882:	83 c2 7c             	add    $0x7c,%edx
f0104885:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f010488b:	75 e8                	jne    f0104875 <sched_halt+0x13>
f010488d:	eb 08                	jmp    f0104897 <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f010488f:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0104895:	75 1f                	jne    f01048b6 <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f0104897:	83 ec 0c             	sub    $0xc,%esp
f010489a:	68 10 7d 10 f0       	push   $0xf0107d10
f010489f:	e8 b6 ed ff ff       	call   f010365a <cprintf>
f01048a4:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f01048a7:	83 ec 0c             	sub    $0xc,%esp
f01048aa:	6a 00                	push   $0x0
f01048ac:	e8 4c c0 ff ff       	call   f01008fd <monitor>
f01048b1:	83 c4 10             	add    $0x10,%esp
f01048b4:	eb f1                	jmp    f01048a7 <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f01048b6:	e8 87 16 00 00       	call   f0105f42 <cpunum>
f01048bb:	6b c0 74             	imul   $0x74,%eax,%eax
f01048be:	c7 80 28 d0 22 f0 00 	movl   $0x0,-0xfdd2fd8(%eax)
f01048c5:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f01048c8:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01048cd:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01048d2:	77 12                	ja     f01048e6 <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01048d4:	50                   	push   %eax
f01048d5:	68 28 66 10 f0       	push   $0xf0106628
f01048da:	6a 48                	push   $0x48
f01048dc:	68 39 7d 10 f0       	push   $0xf0107d39
f01048e1:	e8 5a b7 ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01048e6:	05 00 00 00 10       	add    $0x10000000,%eax
f01048eb:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f01048ee:	e8 4f 16 00 00       	call   f0105f42 <cpunum>
f01048f3:	6b d0 74             	imul   $0x74,%eax,%edx
f01048f6:	81 c2 20 d0 22 f0    	add    $0xf022d020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f01048fc:	b8 02 00 00 00       	mov    $0x2,%eax
f0104901:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0104905:	83 ec 0c             	sub    $0xc,%esp
f0104908:	68 c0 17 12 f0       	push   $0xf01217c0
f010490d:	e8 3b 19 00 00       	call   f010624d <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0104912:	f3 90                	pause  
		// Uncomment the following line after completing exercise 13
		//"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f0104914:	e8 29 16 00 00       	call   f0105f42 <cpunum>
f0104919:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f010491c:	8b 80 30 d0 22 f0    	mov    -0xfdd2fd0(%eax),%eax
f0104922:	bd 00 00 00 00       	mov    $0x0,%ebp
f0104927:	89 c4                	mov    %eax,%esp
f0104929:	6a 00                	push   $0x0
f010492b:	6a 00                	push   $0x0
f010492d:	f4                   	hlt    
f010492e:	eb fd                	jmp    f010492d <sched_halt+0xcb>
		//"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f0104930:	83 c4 10             	add    $0x10,%esp
f0104933:	c9                   	leave  
f0104934:	c3                   	ret    

f0104935 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f0104935:	55                   	push   %ebp
f0104936:	89 e5                	mov    %esp,%ebp
f0104938:	53                   	push   %ebx
f0104939:	83 ec 04             	sub    $0x4,%esp
	// below to halt the cpu.

	// LAB 4: Your code here.
	int nextindex = 0;
	
	if(curenv != NULL)	nextindex = (ENVX(curenv->env_id) + 1) % NENV;
f010493c:	e8 01 16 00 00       	call   f0105f42 <cpunum>
f0104941:	6b d0 74             	imul   $0x74,%eax,%edx
	// another CPU (env_status == ENV_RUNNING). If there are
	// no runnable environments, simply drop through to the code
	// below to halt the cpu.

	// LAB 4: Your code here.
	int nextindex = 0;
f0104944:	b8 00 00 00 00       	mov    $0x0,%eax
	
	if(curenv != NULL)	nextindex = (ENVX(curenv->env_id) + 1) % NENV;
f0104949:	83 ba 28 d0 22 f0 00 	cmpl   $0x0,-0xfdd2fd8(%edx)
f0104950:	74 19                	je     f010496b <sched_yield+0x36>
f0104952:	e8 eb 15 00 00       	call   f0105f42 <cpunum>
f0104957:	6b c0 74             	imul   $0x74,%eax,%eax
f010495a:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0104960:	8b 40 48             	mov    0x48(%eax),%eax
f0104963:	8d 40 01             	lea    0x1(%eax),%eax
f0104966:	25 ff 03 00 00       	and    $0x3ff,%eax

	for(int i = 0; i < NENV; i++){
		if(envs[nextindex].env_status == ENV_RUNNABLE)
f010496b:	8b 0d 48 c2 22 f0    	mov    0xf022c248,%ecx
f0104971:	ba 00 04 00 00       	mov    $0x400,%edx
f0104976:	6b d8 7c             	imul   $0x7c,%eax,%ebx
f0104979:	01 cb                	add    %ecx,%ebx
f010497b:	83 7b 54 02          	cmpl   $0x2,0x54(%ebx)
f010497f:	75 09                	jne    f010498a <sched_yield+0x55>
			env_run(&envs[nextindex]);
f0104981:	83 ec 0c             	sub    $0xc,%esp
f0104984:	53                   	push   %ebx
f0104985:	e8 9a ea ff ff       	call   f0103424 <env_run>
		nextindex = (nextindex + 1) % NENV;	
f010498a:	83 c0 01             	add    $0x1,%eax
f010498d:	89 c3                	mov    %eax,%ebx
f010498f:	c1 fb 1f             	sar    $0x1f,%ebx
f0104992:	c1 eb 16             	shr    $0x16,%ebx
f0104995:	01 d8                	add    %ebx,%eax
f0104997:	25 ff 03 00 00       	and    $0x3ff,%eax
f010499c:	29 d8                	sub    %ebx,%eax
	// LAB 4: Your code here.
	int nextindex = 0;
	
	if(curenv != NULL)	nextindex = (ENVX(curenv->env_id) + 1) % NENV;

	for(int i = 0; i < NENV; i++){
f010499e:	83 ea 01             	sub    $0x1,%edx
f01049a1:	75 d3                	jne    f0104976 <sched_yield+0x41>
		if(envs[nextindex].env_status == ENV_RUNNABLE)
			env_run(&envs[nextindex]);
		nextindex = (nextindex + 1) % NENV;	
	}
	
	if (curenv != NULL && curenv->env_status == ENV_RUNNING)
f01049a3:	e8 9a 15 00 00       	call   f0105f42 <cpunum>
f01049a8:	6b c0 74             	imul   $0x74,%eax,%eax
f01049ab:	83 b8 28 d0 22 f0 00 	cmpl   $0x0,-0xfdd2fd8(%eax)
f01049b2:	74 2a                	je     f01049de <sched_yield+0xa9>
f01049b4:	e8 89 15 00 00       	call   f0105f42 <cpunum>
f01049b9:	6b c0 74             	imul   $0x74,%eax,%eax
f01049bc:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f01049c2:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01049c6:	75 16                	jne    f01049de <sched_yield+0xa9>
		env_run(curenv);
f01049c8:	e8 75 15 00 00       	call   f0105f42 <cpunum>
f01049cd:	83 ec 0c             	sub    $0xc,%esp
f01049d0:	6b c0 74             	imul   $0x74,%eax,%eax
f01049d3:	ff b0 28 d0 22 f0    	pushl  -0xfdd2fd8(%eax)
f01049d9:	e8 46 ea ff ff       	call   f0103424 <env_run>
	// sched_halt never returns
	sched_halt();
f01049de:	e8 7f fe ff ff       	call   f0104862 <sched_halt>
}
f01049e3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01049e6:	c9                   	leave  
f01049e7:	c3                   	ret    

f01049e8 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01049e8:	55                   	push   %ebp
f01049e9:	89 e5                	mov    %esp,%ebp
f01049eb:	57                   	push   %edi
f01049ec:	56                   	push   %esi
f01049ed:	53                   	push   %ebx
f01049ee:	83 ec 1c             	sub    $0x1c,%esp
f01049f1:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");

	switch (syscallno) {
f01049f4:	83 f8 0a             	cmp    $0xa,%eax
f01049f7:	0f 87 ac 03 00 00    	ja     f0104da9 <syscall+0x3c1>
f01049fd:	ff 24 85 80 7d 10 f0 	jmp    *-0xfef8280(,%eax,4)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_P | PTE_U);
f0104a04:	e8 39 15 00 00       	call   f0105f42 <cpunum>
f0104a09:	6a 05                	push   $0x5
f0104a0b:	ff 75 10             	pushl  0x10(%ebp)
f0104a0e:	ff 75 0c             	pushl  0xc(%ebp)
f0104a11:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a14:	ff b0 28 d0 22 f0    	pushl  -0xfdd2fd8(%eax)
f0104a1a:	e8 13 e3 ff ff       	call   f0102d32 <user_mem_assert>

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0104a1f:	83 c4 0c             	add    $0xc,%esp
f0104a22:	ff 75 0c             	pushl  0xc(%ebp)
f0104a25:	ff 75 10             	pushl  0x10(%ebp)
f0104a28:	68 46 7d 10 f0       	push   $0xf0107d46
f0104a2d:	e8 28 ec ff ff       	call   f010365a <cprintf>
f0104a32:	83 c4 10             	add    $0x10,%esp
	//panic("syscall not implemented");

	switch (syscallno) {
	case SYS_cputs:
		sys_cputs((const char *)a1, a2);
		return 0;
f0104a35:	b8 00 00 00 00       	mov    $0x0,%eax
f0104a3a:	e9 6f 03 00 00       	jmp    f0104dae <syscall+0x3c6>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0104a3f:	e8 b1 bb ff ff       	call   f01005f5 <cons_getc>
	case SYS_cputs:
		sys_cputs((const char *)a1, a2);
		return 0;

	case SYS_cgetc:
		return sys_cgetc();
f0104a44:	e9 65 03 00 00       	jmp    f0104dae <syscall+0x3c6>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0104a49:	e8 f4 14 00 00       	call   f0105f42 <cpunum>
f0104a4e:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a51:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0104a57:	8b 40 48             	mov    0x48(%eax),%eax

	case SYS_cgetc:
		return sys_cgetc();

	case SYS_getenvid:
		return sys_getenvid();
f0104a5a:	e9 4f 03 00 00       	jmp    f0104dae <syscall+0x3c6>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0104a5f:	83 ec 04             	sub    $0x4,%esp
f0104a62:	6a 01                	push   $0x1
f0104a64:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104a67:	50                   	push   %eax
f0104a68:	ff 75 0c             	pushl  0xc(%ebp)
f0104a6b:	e8 77 e3 ff ff       	call   f0102de7 <envid2env>
f0104a70:	83 c4 10             	add    $0x10,%esp
f0104a73:	85 c0                	test   %eax,%eax
f0104a75:	0f 88 33 03 00 00    	js     f0104dae <syscall+0x3c6>
		return r;
	if (e == curenv)
f0104a7b:	e8 c2 14 00 00       	call   f0105f42 <cpunum>
f0104a80:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104a83:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a86:	39 90 28 d0 22 f0    	cmp    %edx,-0xfdd2fd8(%eax)
f0104a8c:	75 23                	jne    f0104ab1 <syscall+0xc9>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104a8e:	e8 af 14 00 00       	call   f0105f42 <cpunum>
f0104a93:	83 ec 08             	sub    $0x8,%esp
f0104a96:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a99:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0104a9f:	ff 70 48             	pushl  0x48(%eax)
f0104aa2:	68 4b 7d 10 f0       	push   $0xf0107d4b
f0104aa7:	e8 ae eb ff ff       	call   f010365a <cprintf>
f0104aac:	83 c4 10             	add    $0x10,%esp
f0104aaf:	eb 25                	jmp    f0104ad6 <syscall+0xee>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0104ab1:	8b 5a 48             	mov    0x48(%edx),%ebx
f0104ab4:	e8 89 14 00 00       	call   f0105f42 <cpunum>
f0104ab9:	83 ec 04             	sub    $0x4,%esp
f0104abc:	53                   	push   %ebx
f0104abd:	6b c0 74             	imul   $0x74,%eax,%eax
f0104ac0:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0104ac6:	ff 70 48             	pushl  0x48(%eax)
f0104ac9:	68 66 7d 10 f0       	push   $0xf0107d66
f0104ace:	e8 87 eb ff ff       	call   f010365a <cprintf>
f0104ad3:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f0104ad6:	83 ec 0c             	sub    $0xc,%esp
f0104ad9:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104adc:	e8 a4 e8 ff ff       	call   f0103385 <env_destroy>
f0104ae1:	83 c4 10             	add    $0x10,%esp
	return 0;
f0104ae4:	b8 00 00 00 00       	mov    $0x0,%eax
f0104ae9:	e9 c0 02 00 00       	jmp    f0104dae <syscall+0x3c6>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f0104aee:	e8 42 fe ff ff       	call   f0104935 <sched_yield>
	// will appear to return 0.

	// LAB 4: Your code here.
	//panic("sys_exofork not implemented");
	struct Env *newenv;
	int r = env_alloc(&newenv, curenv->env_id);
f0104af3:	e8 4a 14 00 00       	call   f0105f42 <cpunum>
f0104af8:	83 ec 08             	sub    $0x8,%esp
f0104afb:	6b c0 74             	imul   $0x74,%eax,%eax
f0104afe:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0104b04:	ff 70 48             	pushl  0x48(%eax)
f0104b07:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104b0a:	50                   	push   %eax
f0104b0b:	e8 e9 e3 ff ff       	call   f0102ef9 <env_alloc>
	if(r < 0)	return r;
f0104b10:	83 c4 10             	add    $0x10,%esp
f0104b13:	85 c0                	test   %eax,%eax
f0104b15:	0f 88 93 02 00 00    	js     f0104dae <syscall+0x3c6>

	newenv->env_status = ENV_NOT_RUNNABLE;
f0104b1b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104b1e:	c7 43 54 04 00 00 00 	movl   $0x4,0x54(%ebx)
	newenv->env_tf = curenv->env_tf;
f0104b25:	e8 18 14 00 00       	call   f0105f42 <cpunum>
f0104b2a:	6b c0 74             	imul   $0x74,%eax,%eax
f0104b2d:	8b b0 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%esi
f0104b33:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104b38:	89 df                	mov    %ebx,%edi
f0104b3a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	newenv->env_tf.tf_regs.reg_eax = 0;
f0104b3c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104b3f:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

	return newenv->env_id;
f0104b46:	8b 40 48             	mov    0x48(%eax),%eax
f0104b49:	e9 60 02 00 00       	jmp    f0104dae <syscall+0x3c6>

	// LAB 4: Your code here.
	//panic("sys_env_set_status not implemented");
	//envid2env(envid_t envid, struct Env **env_store, bool checkperm);
	struct Env *env;
	int r = envid2env(envid, &env, 1);
f0104b4e:	83 ec 04             	sub    $0x4,%esp
f0104b51:	6a 01                	push   $0x1
f0104b53:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104b56:	50                   	push   %eax
f0104b57:	ff 75 0c             	pushl  0xc(%ebp)
f0104b5a:	e8 88 e2 ff ff       	call   f0102de7 <envid2env>
	
	if(r < 0)	return r;
f0104b5f:	83 c4 10             	add    $0x10,%esp
f0104b62:	85 c0                	test   %eax,%eax
f0104b64:	0f 88 44 02 00 00    	js     f0104dae <syscall+0x3c6>

	if((status == ENV_RUNNABLE) ||(status == ENV_NOT_RUNNABLE))
f0104b6a:	8b 45 10             	mov    0x10(%ebp),%eax
f0104b6d:	83 e8 02             	sub    $0x2,%eax
f0104b70:	a9 fd ff ff ff       	test   $0xfffffffd,%eax
f0104b75:	75 13                	jne    f0104b8a <syscall+0x1a2>
		{env->env_status = status;
f0104b77:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104b7a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104b7d:	89 48 54             	mov    %ecx,0x54(%eax)
		return 0;}
f0104b80:	b8 00 00 00 00       	mov    $0x0,%eax
f0104b85:	e9 24 02 00 00       	jmp    f0104dae <syscall+0x3c6>
	else 
		return -E_INVAL;
f0104b8a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
		
	case SYS_exofork:
		return sys_exofork();
		
	case SYS_env_set_status:
		return sys_env_set_status(a1, a2);
f0104b8f:	e9 1a 02 00 00       	jmp    f0104dae <syscall+0x3c6>
	//panic("sys_page_alloc not implemented");

	struct Env *new;
	struct PageInfo *pp;
	
	int a =	envid2env(envid, &new, 1);
f0104b94:	83 ec 04             	sub    $0x4,%esp
f0104b97:	6a 01                	push   $0x1
f0104b99:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104b9c:	50                   	push   %eax
f0104b9d:	ff 75 0c             	pushl  0xc(%ebp)
f0104ba0:	e8 42 e2 ff ff       	call   f0102de7 <envid2env>
	if(a < 0)	
f0104ba5:	83 c4 10             	add    $0x10,%esp
f0104ba8:	85 c0                	test   %eax,%eax
f0104baa:	78 69                	js     f0104c15 <syscall+0x22d>
		return -E_BAD_ENV; 	
	
	if(va >= (void *)UTOP || PGOFF(va) != 0)	
f0104bac:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104bb3:	77 6a                	ja     f0104c1f <syscall+0x237>
f0104bb5:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104bbc:	75 6b                	jne    f0104c29 <syscall+0x241>
		return -E_INVAL;
	
	if((perm & (PTE_U | PTE_P)) != (PTE_U | PTE_P) || (perm & ~PTE_SYSCALL) != 0)	
f0104bbe:	8b 45 14             	mov    0x14(%ebp),%eax
f0104bc1:	25 fd f1 ff ff       	and    $0xfffff1fd,%eax
f0104bc6:	83 f8 05             	cmp    $0x5,%eax
f0104bc9:	75 68                	jne    f0104c33 <syscall+0x24b>
		return -E_INVAL;	
	
	
	pp = page_alloc(ALLOC_ZERO);
f0104bcb:	83 ec 0c             	sub    $0xc,%esp
f0104bce:	6a 01                	push   $0x1
f0104bd0:	e8 27 c3 ff ff       	call   f0100efc <page_alloc>
f0104bd5:	89 c3                	mov    %eax,%ebx
	if(pp == NULL)	return -E_NO_MEM; 	//Handle -E_NO_MEM;
f0104bd7:	83 c4 10             	add    $0x10,%esp
f0104bda:	85 c0                	test   %eax,%eax
f0104bdc:	74 5f                	je     f0104c3d <syscall+0x255>
	
	a = page_insert(new->env_pgdir, pp, va, perm);
f0104bde:	ff 75 14             	pushl  0x14(%ebp)
f0104be1:	ff 75 10             	pushl  0x10(%ebp)
f0104be4:	50                   	push   %eax
f0104be5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104be8:	ff 70 60             	pushl  0x60(%eax)
f0104beb:	e8 de c5 ff ff       	call   f01011ce <page_insert>
f0104bf0:	89 c6                	mov    %eax,%esi
	if(a < 0){
f0104bf2:	83 c4 10             	add    $0x10,%esp
		page_free(pp);
		return a;}

	return 0;
f0104bf5:	b8 00 00 00 00       	mov    $0x0,%eax
	
	pp = page_alloc(ALLOC_ZERO);
	if(pp == NULL)	return -E_NO_MEM; 	//Handle -E_NO_MEM;
	
	a = page_insert(new->env_pgdir, pp, va, perm);
	if(a < 0){
f0104bfa:	85 f6                	test   %esi,%esi
f0104bfc:	0f 89 ac 01 00 00    	jns    f0104dae <syscall+0x3c6>
		page_free(pp);
f0104c02:	83 ec 0c             	sub    $0xc,%esp
f0104c05:	53                   	push   %ebx
f0104c06:	e8 61 c3 ff ff       	call   f0100f6c <page_free>
f0104c0b:	83 c4 10             	add    $0x10,%esp
		return a;}
f0104c0e:	89 f0                	mov    %esi,%eax
f0104c10:	e9 99 01 00 00       	jmp    f0104dae <syscall+0x3c6>
	struct Env *new;
	struct PageInfo *pp;
	
	int a =	envid2env(envid, &new, 1);
	if(a < 0)	
		return -E_BAD_ENV; 	
f0104c15:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0104c1a:	e9 8f 01 00 00       	jmp    f0104dae <syscall+0x3c6>
	
	if(va >= (void *)UTOP || PGOFF(va) != 0)	
		return -E_INVAL;
f0104c1f:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104c24:	e9 85 01 00 00       	jmp    f0104dae <syscall+0x3c6>
f0104c29:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104c2e:	e9 7b 01 00 00       	jmp    f0104dae <syscall+0x3c6>
	
	if((perm & (PTE_U | PTE_P)) != (PTE_U | PTE_P) || (perm & ~PTE_SYSCALL) != 0)	
		return -E_INVAL;	
f0104c33:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104c38:	e9 71 01 00 00       	jmp    f0104dae <syscall+0x3c6>
	
	
	pp = page_alloc(ALLOC_ZERO);
	if(pp == NULL)	return -E_NO_MEM; 	//Handle -E_NO_MEM;
f0104c3d:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0104c42:	e9 67 01 00 00       	jmp    f0104dae <syscall+0x3c6>

	struct Env *src_env,*dst_env;
	struct PageInfo *pp;
	pte_t *pte;

	int a =	envid2env(srcenvid, &src_env, 1);
f0104c47:	83 ec 04             	sub    $0x4,%esp
f0104c4a:	6a 01                	push   $0x1
f0104c4c:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0104c4f:	50                   	push   %eax
f0104c50:	ff 75 0c             	pushl  0xc(%ebp)
f0104c53:	e8 8f e1 ff ff       	call   f0102de7 <envid2env>
	if(a < 0)	
f0104c58:	83 c4 10             	add    $0x10,%esp
f0104c5b:	85 c0                	test   %eax,%eax
f0104c5d:	0f 88 ab 00 00 00    	js     f0104d0e <syscall+0x326>
		return -E_BAD_ENV;

	a =	envid2env(dstenvid, &dst_env, 1);
f0104c63:	83 ec 04             	sub    $0x4,%esp
f0104c66:	6a 01                	push   $0x1
f0104c68:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0104c6b:	50                   	push   %eax
f0104c6c:	ff 75 14             	pushl  0x14(%ebp)
f0104c6f:	e8 73 e1 ff ff       	call   f0102de7 <envid2env>
	if(a < 0)	
f0104c74:	83 c4 10             	add    $0x10,%esp
f0104c77:	85 c0                	test   %eax,%eax
f0104c79:	0f 88 99 00 00 00    	js     f0104d18 <syscall+0x330>
		return -E_BAD_ENV;

	if(srcva >= (void *)UTOP || PGOFF(srcva) != 0)	
f0104c7f:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104c86:	0f 87 96 00 00 00    	ja     f0104d22 <syscall+0x33a>
		return -E_INVAL;

	if(dstva >= (void *)UTOP || PGOFF(dstva) != 0)	
f0104c8c:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104c93:	0f 85 93 00 00 00    	jne    f0104d2c <syscall+0x344>
f0104c99:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f0104ca0:	0f 87 86 00 00 00    	ja     f0104d2c <syscall+0x344>
f0104ca6:	f7 45 18 ff 0f 00 00 	testl  $0xfff,0x18(%ebp)
f0104cad:	0f 85 80 00 00 00    	jne    f0104d33 <syscall+0x34b>
		return -E_INVAL;
	
	
	if ((perm & (PTE_U | PTE_P)) != (PTE_U | PTE_P) || (perm & ~PTE_SYSCALL) != 0)
f0104cb3:	8b 45 1c             	mov    0x1c(%ebp),%eax
f0104cb6:	25 fd f1 ff ff       	and    $0xfffff1fd,%eax
f0104cbb:	83 f8 05             	cmp    $0x5,%eax
f0104cbe:	75 7a                	jne    f0104d3a <syscall+0x352>
		return -E_INVAL;

	if ((pp = page_lookup(src_env->env_pgdir, srcva, &pte)) == NULL)
f0104cc0:	83 ec 04             	sub    $0x4,%esp
f0104cc3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104cc6:	50                   	push   %eax
f0104cc7:	ff 75 10             	pushl  0x10(%ebp)
f0104cca:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104ccd:	ff 70 60             	pushl  0x60(%eax)
f0104cd0:	e8 18 c4 ff ff       	call   f01010ed <page_lookup>
f0104cd5:	83 c4 10             	add    $0x10,%esp
f0104cd8:	85 c0                	test   %eax,%eax
f0104cda:	74 65                	je     f0104d41 <syscall+0x359>
		return -E_INVAL;

	if ((perm & PTE_W) && !(*pte & PTE_W))
f0104cdc:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f0104ce0:	74 08                	je     f0104cea <syscall+0x302>
f0104ce2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104ce5:	f6 02 02             	testb  $0x2,(%edx)
f0104ce8:	74 5e                	je     f0104d48 <syscall+0x360>
		return -E_INVAL;

	if ((a = page_insert(dst_env->env_pgdir, pp, dstva, perm)) < 0)
f0104cea:	ff 75 1c             	pushl  0x1c(%ebp)
f0104ced:	ff 75 18             	pushl  0x18(%ebp)
f0104cf0:	50                   	push   %eax
f0104cf1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104cf4:	ff 70 60             	pushl  0x60(%eax)
f0104cf7:	e8 d2 c4 ff ff       	call   f01011ce <page_insert>
f0104cfc:	83 c4 10             	add    $0x10,%esp
f0104cff:	85 c0                	test   %eax,%eax
f0104d01:	ba 00 00 00 00       	mov    $0x0,%edx
f0104d06:	0f 4f c2             	cmovg  %edx,%eax
f0104d09:	e9 a0 00 00 00       	jmp    f0104dae <syscall+0x3c6>
	struct PageInfo *pp;
	pte_t *pte;

	int a =	envid2env(srcenvid, &src_env, 1);
	if(a < 0)	
		return -E_BAD_ENV;
f0104d0e:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0104d13:	e9 96 00 00 00       	jmp    f0104dae <syscall+0x3c6>

	a =	envid2env(dstenvid, &dst_env, 1);
	if(a < 0)	
		return -E_BAD_ENV;
f0104d18:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0104d1d:	e9 8c 00 00 00       	jmp    f0104dae <syscall+0x3c6>

	if(srcva >= (void *)UTOP || PGOFF(srcva) != 0)	
		return -E_INVAL;
f0104d22:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104d27:	e9 82 00 00 00       	jmp    f0104dae <syscall+0x3c6>

	if(dstva >= (void *)UTOP || PGOFF(dstva) != 0)	
		return -E_INVAL;
f0104d2c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104d31:	eb 7b                	jmp    f0104dae <syscall+0x3c6>
f0104d33:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104d38:	eb 74                	jmp    f0104dae <syscall+0x3c6>
	
	
	if ((perm & (PTE_U | PTE_P)) != (PTE_U | PTE_P) || (perm & ~PTE_SYSCALL) != 0)
		return -E_INVAL;
f0104d3a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104d3f:	eb 6d                	jmp    f0104dae <syscall+0x3c6>

	if ((pp = page_lookup(src_env->env_pgdir, srcva, &pte)) == NULL)
		return -E_INVAL;
f0104d41:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104d46:	eb 66                	jmp    f0104dae <syscall+0x3c6>

	if ((perm & PTE_W) && !(*pte & PTE_W))
		return -E_INVAL;
f0104d48:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
		
	case SYS_page_alloc:
		return sys_page_alloc(a1, (void *) a2, a3);
		
	case SYS_page_map:
		return sys_page_map(a1, (void *)a2, a3, (void *) a4, a5);
f0104d4d:	eb 5f                	jmp    f0104dae <syscall+0x3c6>
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.
	//panic("sys_page_unmap not implemented");
	
	if(va >= (void*) UTOP  || PGOFF(va) != 0)	
f0104d4f:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104d56:	77 3c                	ja     f0104d94 <syscall+0x3ac>
f0104d58:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104d5f:	75 3a                	jne    f0104d9b <syscall+0x3b3>
		return -E_INVAL;

	struct Env *env;

	int a =	envid2env(envid, &env, 1);
f0104d61:	83 ec 04             	sub    $0x4,%esp
f0104d64:	6a 01                	push   $0x1
f0104d66:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104d69:	50                   	push   %eax
f0104d6a:	ff 75 0c             	pushl  0xc(%ebp)
f0104d6d:	e8 75 e0 ff ff       	call   f0102de7 <envid2env>
	if(a < 0)	
f0104d72:	83 c4 10             	add    $0x10,%esp
f0104d75:	85 c0                	test   %eax,%eax
f0104d77:	78 29                	js     f0104da2 <syscall+0x3ba>
		return -E_BAD_ENV;

	page_remove(env->env_pgdir, va);
f0104d79:	83 ec 08             	sub    $0x8,%esp
f0104d7c:	ff 75 10             	pushl  0x10(%ebp)
f0104d7f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104d82:	ff 70 60             	pushl  0x60(%eax)
f0104d85:	e8 fe c3 ff ff       	call   f0101188 <page_remove>
f0104d8a:	83 c4 10             	add    $0x10,%esp
	return 0;		
f0104d8d:	b8 00 00 00 00       	mov    $0x0,%eax
f0104d92:	eb 1a                	jmp    f0104dae <syscall+0x3c6>

	// LAB 4: Your code here.
	//panic("sys_page_unmap not implemented");
	
	if(va >= (void*) UTOP  || PGOFF(va) != 0)	
		return -E_INVAL;
f0104d94:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104d99:	eb 13                	jmp    f0104dae <syscall+0x3c6>
f0104d9b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104da0:	eb 0c                	jmp    f0104dae <syscall+0x3c6>

	struct Env *env;

	int a =	envid2env(envid, &env, 1);
	if(a < 0)	
		return -E_BAD_ENV;
f0104da2:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
		
	case SYS_page_map:
		return sys_page_map(a1, (void *)a2, a3, (void *) a4, a5);
				
	case SYS_page_unmap:
		return sys_page_unmap(a1, (void *) a2);
f0104da7:	eb 05                	jmp    f0104dae <syscall+0x3c6>
		
	default:
		return -E_INVAL;
f0104da9:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}

}
f0104dae:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104db1:	5b                   	pop    %ebx
f0104db2:	5e                   	pop    %esi
f0104db3:	5f                   	pop    %edi
f0104db4:	5d                   	pop    %ebp
f0104db5:	c3                   	ret    

f0104db6 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104db6:	55                   	push   %ebp
f0104db7:	89 e5                	mov    %esp,%ebp
f0104db9:	57                   	push   %edi
f0104dba:	56                   	push   %esi
f0104dbb:	53                   	push   %ebx
f0104dbc:	83 ec 14             	sub    $0x14,%esp
f0104dbf:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104dc2:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104dc5:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104dc8:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104dcb:	8b 1a                	mov    (%edx),%ebx
f0104dcd:	8b 01                	mov    (%ecx),%eax
f0104dcf:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104dd2:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104dd9:	eb 7f                	jmp    f0104e5a <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0104ddb:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104dde:	01 d8                	add    %ebx,%eax
f0104de0:	89 c6                	mov    %eax,%esi
f0104de2:	c1 ee 1f             	shr    $0x1f,%esi
f0104de5:	01 c6                	add    %eax,%esi
f0104de7:	d1 fe                	sar    %esi
f0104de9:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0104dec:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104def:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0104df2:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104df4:	eb 03                	jmp    f0104df9 <stab_binsearch+0x43>
			m--;
f0104df6:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104df9:	39 c3                	cmp    %eax,%ebx
f0104dfb:	7f 0d                	jg     f0104e0a <stab_binsearch+0x54>
f0104dfd:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104e01:	83 ea 0c             	sub    $0xc,%edx
f0104e04:	39 f9                	cmp    %edi,%ecx
f0104e06:	75 ee                	jne    f0104df6 <stab_binsearch+0x40>
f0104e08:	eb 05                	jmp    f0104e0f <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0104e0a:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0104e0d:	eb 4b                	jmp    f0104e5a <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104e0f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104e12:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104e15:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104e19:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104e1c:	76 11                	jbe    f0104e2f <stab_binsearch+0x79>
			*region_left = m;
f0104e1e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104e21:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0104e23:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104e26:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104e2d:	eb 2b                	jmp    f0104e5a <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0104e2f:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104e32:	73 14                	jae    f0104e48 <stab_binsearch+0x92>
			*region_right = m - 1;
f0104e34:	83 e8 01             	sub    $0x1,%eax
f0104e37:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104e3a:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0104e3d:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104e3f:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104e46:	eb 12                	jmp    f0104e5a <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104e48:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104e4b:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0104e4d:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104e51:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104e53:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0104e5a:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104e5d:	0f 8e 78 ff ff ff    	jle    f0104ddb <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0104e63:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0104e67:	75 0f                	jne    f0104e78 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0104e69:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104e6c:	8b 00                	mov    (%eax),%eax
f0104e6e:	83 e8 01             	sub    $0x1,%eax
f0104e71:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0104e74:	89 06                	mov    %eax,(%esi)
f0104e76:	eb 2c                	jmp    f0104ea4 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104e78:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104e7b:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104e7d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104e80:	8b 0e                	mov    (%esi),%ecx
f0104e82:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104e85:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0104e88:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104e8b:	eb 03                	jmp    f0104e90 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104e8d:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104e90:	39 c8                	cmp    %ecx,%eax
f0104e92:	7e 0b                	jle    f0104e9f <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0104e94:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0104e98:	83 ea 0c             	sub    $0xc,%edx
f0104e9b:	39 df                	cmp    %ebx,%edi
f0104e9d:	75 ee                	jne    f0104e8d <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104e9f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104ea2:	89 06                	mov    %eax,(%esi)
	}
}
f0104ea4:	83 c4 14             	add    $0x14,%esp
f0104ea7:	5b                   	pop    %ebx
f0104ea8:	5e                   	pop    %esi
f0104ea9:	5f                   	pop    %edi
f0104eaa:	5d                   	pop    %ebp
f0104eab:	c3                   	ret    

f0104eac <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104eac:	55                   	push   %ebp
f0104ead:	89 e5                	mov    %esp,%ebp
f0104eaf:	57                   	push   %edi
f0104eb0:	56                   	push   %esi
f0104eb1:	53                   	push   %ebx
f0104eb2:	83 ec 3c             	sub    $0x3c,%esp
f0104eb5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104eb8:	c7 03 ac 7d 10 f0    	movl   $0xf0107dac,(%ebx)
	info->eip_line = 0;
f0104ebe:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0104ec5:	c7 43 08 ac 7d 10 f0 	movl   $0xf0107dac,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0104ecc:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0104ed3:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ed6:	89 43 10             	mov    %eax,0x10(%ebx)
	info->eip_fn_narg = 0;
f0104ed9:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0104ee0:	3d ff ff 7f ef       	cmp    $0xef7fffff,%eax
f0104ee5:	0f 87 a3 00 00 00    	ja     f0104f8e <debuginfo_eip+0xe2>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		int perm = PTE_U | PTE_P;
		if (user_mem_check(curenv, usd, sizeof(struct UserStabData), perm) < 0) {
f0104eeb:	e8 52 10 00 00       	call   f0105f42 <cpunum>
f0104ef0:	6a 05                	push   $0x5
f0104ef2:	6a 10                	push   $0x10
f0104ef4:	68 00 00 20 00       	push   $0x200000
f0104ef9:	6b c0 74             	imul   $0x74,%eax,%eax
f0104efc:	ff b0 28 d0 22 f0    	pushl  -0xfdd2fd8(%eax)
f0104f02:	e8 84 dd ff ff       	call   f0102c8b <user_mem_check>
f0104f07:	83 c4 10             	add    $0x10,%esp
f0104f0a:	85 c0                	test   %eax,%eax
f0104f0c:	0f 88 41 02 00 00    	js     f0105153 <debuginfo_eip+0x2a7>
			return -1;
		}

		stabs = usd->stabs;
f0104f12:	a1 00 00 20 00       	mov    0x200000,%eax
		stab_end = usd->stab_end;
f0104f17:	8b 3d 04 00 20 00    	mov    0x200004,%edi
		stabstr = usd->stabstr;
f0104f1d:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f0104f23:	89 ce                	mov    %ecx,%esi
f0104f25:	89 4d b8             	mov    %ecx,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f0104f28:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f0104f2e:	89 55 c0             	mov    %edx,-0x40(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv , (void *)stabs , (uint32_t)stab_end - (uint32_t)stabs , perm) < 0) {
f0104f31:	89 f9                	mov    %edi,%ecx
f0104f33:	89 45 bc             	mov    %eax,-0x44(%ebp)
f0104f36:	29 c1                	sub    %eax,%ecx
f0104f38:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f0104f3b:	e8 02 10 00 00       	call   f0105f42 <cpunum>
f0104f40:	6a 05                	push   $0x5
f0104f42:	ff 75 c4             	pushl  -0x3c(%ebp)
f0104f45:	ff 75 bc             	pushl  -0x44(%ebp)
f0104f48:	6b c0 74             	imul   $0x74,%eax,%eax
f0104f4b:	ff b0 28 d0 22 f0    	pushl  -0xfdd2fd8(%eax)
f0104f51:	e8 35 dd ff ff       	call   f0102c8b <user_mem_check>
f0104f56:	83 c4 10             	add    $0x10,%esp
f0104f59:	85 c0                	test   %eax,%eax
f0104f5b:	0f 88 f9 01 00 00    	js     f010515a <debuginfo_eip+0x2ae>
			return -1;
		}
		if (user_mem_check(curenv , (void *) stabstr , (uint32_t)stabstr_end - (uint32_t)stabstr , perm) < 0) {
f0104f61:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0104f64:	29 f2                	sub    %esi,%edx
f0104f66:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f0104f69:	e8 d4 0f 00 00       	call   f0105f42 <cpunum>
f0104f6e:	6a 05                	push   $0x5
f0104f70:	ff 75 c4             	pushl  -0x3c(%ebp)
f0104f73:	56                   	push   %esi
f0104f74:	6b c0 74             	imul   $0x74,%eax,%eax
f0104f77:	ff b0 28 d0 22 f0    	pushl  -0xfdd2fd8(%eax)
f0104f7d:	e8 09 dd ff ff       	call   f0102c8b <user_mem_check>
f0104f82:	83 c4 10             	add    $0x10,%esp
f0104f85:	85 c0                	test   %eax,%eax
f0104f87:	79 1f                	jns    f0104fa8 <debuginfo_eip+0xfc>
f0104f89:	e9 d3 01 00 00       	jmp    f0105161 <debuginfo_eip+0x2b5>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104f8e:	c7 45 c0 9b 61 11 f0 	movl   $0xf011619b,-0x40(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0104f95:	c7 45 b8 b9 2a 11 f0 	movl   $0xf0112ab9,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0104f9c:	bf b8 2a 11 f0       	mov    $0xf0112ab8,%edi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0104fa1:	c7 45 bc 94 82 10 f0 	movl   $0xf0108294,-0x44(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104fa8:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0104fab:	39 45 b8             	cmp    %eax,-0x48(%ebp)
f0104fae:	0f 83 b4 01 00 00    	jae    f0105168 <debuginfo_eip+0x2bc>
f0104fb4:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0104fb8:	0f 85 b1 01 00 00    	jne    f010516f <debuginfo_eip+0x2c3>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104fbe:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0104fc5:	8b 75 bc             	mov    -0x44(%ebp),%esi
f0104fc8:	29 f7                	sub    %esi,%edi
f0104fca:	c1 ff 02             	sar    $0x2,%edi
f0104fcd:	69 c7 ab aa aa aa    	imul   $0xaaaaaaab,%edi,%eax
f0104fd3:	83 e8 01             	sub    $0x1,%eax
f0104fd6:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104fd9:	83 ec 08             	sub    $0x8,%esp
f0104fdc:	ff 75 08             	pushl  0x8(%ebp)
f0104fdf:	6a 64                	push   $0x64
f0104fe1:	8d 55 e0             	lea    -0x20(%ebp),%edx
f0104fe4:	89 d1                	mov    %edx,%ecx
f0104fe6:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104fe9:	89 f0                	mov    %esi,%eax
f0104feb:	e8 c6 fd ff ff       	call   f0104db6 <stab_binsearch>
	if (lfile == 0)
f0104ff0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104ff3:	83 c4 10             	add    $0x10,%esp
f0104ff6:	85 c0                	test   %eax,%eax
f0104ff8:	0f 84 78 01 00 00    	je     f0105176 <debuginfo_eip+0x2ca>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104ffe:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0105001:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105004:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0105007:	83 ec 08             	sub    $0x8,%esp
f010500a:	ff 75 08             	pushl  0x8(%ebp)
f010500d:	6a 24                	push   $0x24
f010500f:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0105012:	89 d1                	mov    %edx,%ecx
f0105014:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0105017:	89 f0                	mov    %esi,%eax
f0105019:	e8 98 fd ff ff       	call   f0104db6 <stab_binsearch>

	if (lfun <= rfun) {
f010501e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0105021:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0105024:	83 c4 10             	add    $0x10,%esp
f0105027:	39 d0                	cmp    %edx,%eax
f0105029:	7f 29                	jg     f0105054 <debuginfo_eip+0x1a8>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010502b:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f010502e:	8d 3c 8e             	lea    (%esi,%ecx,4),%edi
f0105031:	8b 37                	mov    (%edi),%esi
f0105033:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f0105036:	2b 4d b8             	sub    -0x48(%ebp),%ecx
f0105039:	39 ce                	cmp    %ecx,%esi
f010503b:	73 06                	jae    f0105043 <debuginfo_eip+0x197>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010503d:	03 75 b8             	add    -0x48(%ebp),%esi
f0105040:	89 73 08             	mov    %esi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0105043:	8b 4f 08             	mov    0x8(%edi),%ecx
f0105046:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0105049:	29 4d 08             	sub    %ecx,0x8(%ebp)
		// Search within the function definition for the line number.
		lline = lfun;
f010504c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f010504f:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0105052:	eb 12                	jmp    f0105066 <debuginfo_eip+0x1ba>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0105054:	8b 45 08             	mov    0x8(%ebp),%eax
f0105057:	89 43 10             	mov    %eax,0x10(%ebx)
		lline = lfile;
f010505a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010505d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0105060:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105063:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0105066:	83 ec 08             	sub    $0x8,%esp
f0105069:	6a 3a                	push   $0x3a
f010506b:	ff 73 08             	pushl  0x8(%ebx)
f010506e:	e8 91 08 00 00       	call   f0105904 <strfind>
f0105073:	2b 43 08             	sub    0x8(%ebx),%eax
f0105076:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0105079:	83 c4 08             	add    $0x8,%esp
f010507c:	ff 75 08             	pushl  0x8(%ebp)
f010507f:	6a 44                	push   $0x44
f0105081:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0105084:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0105087:	8b 7d bc             	mov    -0x44(%ebp),%edi
f010508a:	89 f8                	mov    %edi,%eax
f010508c:	e8 25 fd ff ff       	call   f0104db6 <stab_binsearch>
  	if (lline <= rline) {
f0105091:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0105094:	83 c4 10             	add    $0x10,%esp
f0105097:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f010509a:	0f 8f dd 00 00 00    	jg     f010517d <debuginfo_eip+0x2d1>
    	info->eip_line = stabs[lline].n_desc;
f01050a0:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01050a3:	8d 14 97             	lea    (%edi,%edx,4),%edx
f01050a6:	0f b7 4a 06          	movzwl 0x6(%edx),%ecx
f01050aa:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01050ad:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01050b0:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f01050b4:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01050b7:	eb 0a                	jmp    f01050c3 <debuginfo_eip+0x217>
f01050b9:	83 e8 01             	sub    $0x1,%eax
f01050bc:	83 ea 0c             	sub    $0xc,%edx
f01050bf:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f01050c3:	39 c7                	cmp    %eax,%edi
f01050c5:	7e 05                	jle    f01050cc <debuginfo_eip+0x220>
f01050c7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01050ca:	eb 47                	jmp    f0105113 <debuginfo_eip+0x267>
	       && stabs[lline].n_type != N_SOL
f01050cc:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01050d0:	80 f9 84             	cmp    $0x84,%cl
f01050d3:	75 0e                	jne    f01050e3 <debuginfo_eip+0x237>
f01050d5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01050d8:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01050dc:	74 1c                	je     f01050fa <debuginfo_eip+0x24e>
f01050de:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01050e1:	eb 17                	jmp    f01050fa <debuginfo_eip+0x24e>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01050e3:	80 f9 64             	cmp    $0x64,%cl
f01050e6:	75 d1                	jne    f01050b9 <debuginfo_eip+0x20d>
f01050e8:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f01050ec:	74 cb                	je     f01050b9 <debuginfo_eip+0x20d>
f01050ee:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01050f1:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01050f5:	74 03                	je     f01050fa <debuginfo_eip+0x24e>
f01050f7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01050fa:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01050fd:	8b 75 bc             	mov    -0x44(%ebp),%esi
f0105100:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0105103:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0105106:	8b 75 b8             	mov    -0x48(%ebp),%esi
f0105109:	29 f0                	sub    %esi,%eax
f010510b:	39 c2                	cmp    %eax,%edx
f010510d:	73 04                	jae    f0105113 <debuginfo_eip+0x267>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010510f:	01 f2                	add    %esi,%edx
f0105111:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0105113:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0105116:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0105119:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010511e:	39 f2                	cmp    %esi,%edx
f0105120:	7d 67                	jge    f0105189 <debuginfo_eip+0x2dd>
		for (lline = lfun + 1;
f0105122:	83 c2 01             	add    $0x1,%edx
f0105125:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0105128:	89 d0                	mov    %edx,%eax
f010512a:	8d 14 52             	lea    (%edx,%edx,2),%edx
f010512d:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0105130:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0105133:	eb 04                	jmp    f0105139 <debuginfo_eip+0x28d>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0105135:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0105139:	39 c6                	cmp    %eax,%esi
f010513b:	7e 47                	jle    f0105184 <debuginfo_eip+0x2d8>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010513d:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0105141:	83 c0 01             	add    $0x1,%eax
f0105144:	83 c2 0c             	add    $0xc,%edx
f0105147:	80 f9 a0             	cmp    $0xa0,%cl
f010514a:	74 e9                	je     f0105135 <debuginfo_eip+0x289>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010514c:	b8 00 00 00 00       	mov    $0x0,%eax
f0105151:	eb 36                	jmp    f0105189 <debuginfo_eip+0x2dd>
		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		int perm = PTE_U | PTE_P;
		if (user_mem_check(curenv, usd, sizeof(struct UserStabData), perm) < 0) {
			return -1;
f0105153:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105158:	eb 2f                	jmp    f0105189 <debuginfo_eip+0x2dd>
		stabstr_end = usd->stabstr_end;

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv , (void *)stabs , (uint32_t)stab_end - (uint32_t)stabs , perm) < 0) {
			return -1;
f010515a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010515f:	eb 28                	jmp    f0105189 <debuginfo_eip+0x2dd>
		}
		if (user_mem_check(curenv , (void *) stabstr , (uint32_t)stabstr_end - (uint32_t)stabstr , perm) < 0) {
			return -1;
f0105161:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105166:	eb 21                	jmp    f0105189 <debuginfo_eip+0x2dd>
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0105168:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010516d:	eb 1a                	jmp    f0105189 <debuginfo_eip+0x2dd>
f010516f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105174:	eb 13                	jmp    f0105189 <debuginfo_eip+0x2dd>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0105176:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010517b:	eb 0c                	jmp    f0105189 <debuginfo_eip+0x2dd>
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
  	if (lline <= rline) {
    	info->eip_line = stabs[lline].n_desc;
  	} else {
    	return -1;
f010517d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105182:	eb 05                	jmp    f0105189 <debuginfo_eip+0x2dd>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0105184:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105189:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010518c:	5b                   	pop    %ebx
f010518d:	5e                   	pop    %esi
f010518e:	5f                   	pop    %edi
f010518f:	5d                   	pop    %ebp
f0105190:	c3                   	ret    

f0105191 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0105191:	55                   	push   %ebp
f0105192:	89 e5                	mov    %esp,%ebp
f0105194:	57                   	push   %edi
f0105195:	56                   	push   %esi
f0105196:	53                   	push   %ebx
f0105197:	83 ec 1c             	sub    $0x1c,%esp
f010519a:	89 c7                	mov    %eax,%edi
f010519c:	89 d6                	mov    %edx,%esi
f010519e:	8b 45 08             	mov    0x8(%ebp),%eax
f01051a1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01051a4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01051a7:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01051aa:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01051ad:	bb 00 00 00 00       	mov    $0x0,%ebx
f01051b2:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01051b5:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01051b8:	39 d3                	cmp    %edx,%ebx
f01051ba:	72 05                	jb     f01051c1 <printnum+0x30>
f01051bc:	39 45 10             	cmp    %eax,0x10(%ebp)
f01051bf:	77 45                	ja     f0105206 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01051c1:	83 ec 0c             	sub    $0xc,%esp
f01051c4:	ff 75 18             	pushl  0x18(%ebp)
f01051c7:	8b 45 14             	mov    0x14(%ebp),%eax
f01051ca:	8d 58 ff             	lea    -0x1(%eax),%ebx
f01051cd:	53                   	push   %ebx
f01051ce:	ff 75 10             	pushl  0x10(%ebp)
f01051d1:	83 ec 08             	sub    $0x8,%esp
f01051d4:	ff 75 e4             	pushl  -0x1c(%ebp)
f01051d7:	ff 75 e0             	pushl  -0x20(%ebp)
f01051da:	ff 75 dc             	pushl  -0x24(%ebp)
f01051dd:	ff 75 d8             	pushl  -0x28(%ebp)
f01051e0:	e8 5b 11 00 00       	call   f0106340 <__udivdi3>
f01051e5:	83 c4 18             	add    $0x18,%esp
f01051e8:	52                   	push   %edx
f01051e9:	50                   	push   %eax
f01051ea:	89 f2                	mov    %esi,%edx
f01051ec:	89 f8                	mov    %edi,%eax
f01051ee:	e8 9e ff ff ff       	call   f0105191 <printnum>
f01051f3:	83 c4 20             	add    $0x20,%esp
f01051f6:	eb 18                	jmp    f0105210 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01051f8:	83 ec 08             	sub    $0x8,%esp
f01051fb:	56                   	push   %esi
f01051fc:	ff 75 18             	pushl  0x18(%ebp)
f01051ff:	ff d7                	call   *%edi
f0105201:	83 c4 10             	add    $0x10,%esp
f0105204:	eb 03                	jmp    f0105209 <printnum+0x78>
f0105206:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0105209:	83 eb 01             	sub    $0x1,%ebx
f010520c:	85 db                	test   %ebx,%ebx
f010520e:	7f e8                	jg     f01051f8 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0105210:	83 ec 08             	sub    $0x8,%esp
f0105213:	56                   	push   %esi
f0105214:	83 ec 04             	sub    $0x4,%esp
f0105217:	ff 75 e4             	pushl  -0x1c(%ebp)
f010521a:	ff 75 e0             	pushl  -0x20(%ebp)
f010521d:	ff 75 dc             	pushl  -0x24(%ebp)
f0105220:	ff 75 d8             	pushl  -0x28(%ebp)
f0105223:	e8 48 12 00 00       	call   f0106470 <__umoddi3>
f0105228:	83 c4 14             	add    $0x14,%esp
f010522b:	0f be 80 b6 7d 10 f0 	movsbl -0xfef824a(%eax),%eax
f0105232:	50                   	push   %eax
f0105233:	ff d7                	call   *%edi
}
f0105235:	83 c4 10             	add    $0x10,%esp
f0105238:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010523b:	5b                   	pop    %ebx
f010523c:	5e                   	pop    %esi
f010523d:	5f                   	pop    %edi
f010523e:	5d                   	pop    %ebp
f010523f:	c3                   	ret    

f0105240 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0105240:	55                   	push   %ebp
f0105241:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0105243:	83 fa 01             	cmp    $0x1,%edx
f0105246:	7e 0e                	jle    f0105256 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0105248:	8b 10                	mov    (%eax),%edx
f010524a:	8d 4a 08             	lea    0x8(%edx),%ecx
f010524d:	89 08                	mov    %ecx,(%eax)
f010524f:	8b 02                	mov    (%edx),%eax
f0105251:	8b 52 04             	mov    0x4(%edx),%edx
f0105254:	eb 22                	jmp    f0105278 <getuint+0x38>
	else if (lflag)
f0105256:	85 d2                	test   %edx,%edx
f0105258:	74 10                	je     f010526a <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f010525a:	8b 10                	mov    (%eax),%edx
f010525c:	8d 4a 04             	lea    0x4(%edx),%ecx
f010525f:	89 08                	mov    %ecx,(%eax)
f0105261:	8b 02                	mov    (%edx),%eax
f0105263:	ba 00 00 00 00       	mov    $0x0,%edx
f0105268:	eb 0e                	jmp    f0105278 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f010526a:	8b 10                	mov    (%eax),%edx
f010526c:	8d 4a 04             	lea    0x4(%edx),%ecx
f010526f:	89 08                	mov    %ecx,(%eax)
f0105271:	8b 02                	mov    (%edx),%eax
f0105273:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0105278:	5d                   	pop    %ebp
f0105279:	c3                   	ret    

f010527a <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010527a:	55                   	push   %ebp
f010527b:	89 e5                	mov    %esp,%ebp
f010527d:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0105280:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0105284:	8b 10                	mov    (%eax),%edx
f0105286:	3b 50 04             	cmp    0x4(%eax),%edx
f0105289:	73 0a                	jae    f0105295 <sprintputch+0x1b>
		*b->buf++ = ch;
f010528b:	8d 4a 01             	lea    0x1(%edx),%ecx
f010528e:	89 08                	mov    %ecx,(%eax)
f0105290:	8b 45 08             	mov    0x8(%ebp),%eax
f0105293:	88 02                	mov    %al,(%edx)
}
f0105295:	5d                   	pop    %ebp
f0105296:	c3                   	ret    

f0105297 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0105297:	55                   	push   %ebp
f0105298:	89 e5                	mov    %esp,%ebp
f010529a:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f010529d:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01052a0:	50                   	push   %eax
f01052a1:	ff 75 10             	pushl  0x10(%ebp)
f01052a4:	ff 75 0c             	pushl  0xc(%ebp)
f01052a7:	ff 75 08             	pushl  0x8(%ebp)
f01052aa:	e8 05 00 00 00       	call   f01052b4 <vprintfmt>
	va_end(ap);
}
f01052af:	83 c4 10             	add    $0x10,%esp
f01052b2:	c9                   	leave  
f01052b3:	c3                   	ret    

f01052b4 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01052b4:	55                   	push   %ebp
f01052b5:	89 e5                	mov    %esp,%ebp
f01052b7:	57                   	push   %edi
f01052b8:	56                   	push   %esi
f01052b9:	53                   	push   %ebx
f01052ba:	83 ec 2c             	sub    $0x2c,%esp
f01052bd:	8b 75 08             	mov    0x8(%ebp),%esi
f01052c0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01052c3:	8b 7d 10             	mov    0x10(%ebp),%edi
f01052c6:	eb 12                	jmp    f01052da <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01052c8:	85 c0                	test   %eax,%eax
f01052ca:	0f 84 89 03 00 00    	je     f0105659 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f01052d0:	83 ec 08             	sub    $0x8,%esp
f01052d3:	53                   	push   %ebx
f01052d4:	50                   	push   %eax
f01052d5:	ff d6                	call   *%esi
f01052d7:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01052da:	83 c7 01             	add    $0x1,%edi
f01052dd:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01052e1:	83 f8 25             	cmp    $0x25,%eax
f01052e4:	75 e2                	jne    f01052c8 <vprintfmt+0x14>
f01052e6:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f01052ea:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01052f1:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01052f8:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f01052ff:	ba 00 00 00 00       	mov    $0x0,%edx
f0105304:	eb 07                	jmp    f010530d <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105306:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0105309:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010530d:	8d 47 01             	lea    0x1(%edi),%eax
f0105310:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105313:	0f b6 07             	movzbl (%edi),%eax
f0105316:	0f b6 c8             	movzbl %al,%ecx
f0105319:	83 e8 23             	sub    $0x23,%eax
f010531c:	3c 55                	cmp    $0x55,%al
f010531e:	0f 87 1a 03 00 00    	ja     f010563e <vprintfmt+0x38a>
f0105324:	0f b6 c0             	movzbl %al,%eax
f0105327:	ff 24 85 80 7e 10 f0 	jmp    *-0xfef8180(,%eax,4)
f010532e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0105331:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0105335:	eb d6                	jmp    f010530d <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105337:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010533a:	b8 00 00 00 00       	mov    $0x0,%eax
f010533f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0105342:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0105345:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0105349:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f010534c:	8d 51 d0             	lea    -0x30(%ecx),%edx
f010534f:	83 fa 09             	cmp    $0x9,%edx
f0105352:	77 39                	ja     f010538d <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0105354:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0105357:	eb e9                	jmp    f0105342 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0105359:	8b 45 14             	mov    0x14(%ebp),%eax
f010535c:	8d 48 04             	lea    0x4(%eax),%ecx
f010535f:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0105362:	8b 00                	mov    (%eax),%eax
f0105364:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105367:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f010536a:	eb 27                	jmp    f0105393 <vprintfmt+0xdf>
f010536c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010536f:	85 c0                	test   %eax,%eax
f0105371:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105376:	0f 49 c8             	cmovns %eax,%ecx
f0105379:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010537c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010537f:	eb 8c                	jmp    f010530d <vprintfmt+0x59>
f0105381:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0105384:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f010538b:	eb 80                	jmp    f010530d <vprintfmt+0x59>
f010538d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0105390:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0105393:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0105397:	0f 89 70 ff ff ff    	jns    f010530d <vprintfmt+0x59>
				width = precision, precision = -1;
f010539d:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01053a0:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01053a3:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01053aa:	e9 5e ff ff ff       	jmp    f010530d <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01053af:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01053b2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01053b5:	e9 53 ff ff ff       	jmp    f010530d <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01053ba:	8b 45 14             	mov    0x14(%ebp),%eax
f01053bd:	8d 50 04             	lea    0x4(%eax),%edx
f01053c0:	89 55 14             	mov    %edx,0x14(%ebp)
f01053c3:	83 ec 08             	sub    $0x8,%esp
f01053c6:	53                   	push   %ebx
f01053c7:	ff 30                	pushl  (%eax)
f01053c9:	ff d6                	call   *%esi
			break;
f01053cb:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01053ce:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f01053d1:	e9 04 ff ff ff       	jmp    f01052da <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01053d6:	8b 45 14             	mov    0x14(%ebp),%eax
f01053d9:	8d 50 04             	lea    0x4(%eax),%edx
f01053dc:	89 55 14             	mov    %edx,0x14(%ebp)
f01053df:	8b 00                	mov    (%eax),%eax
f01053e1:	99                   	cltd   
f01053e2:	31 d0                	xor    %edx,%eax
f01053e4:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01053e6:	83 f8 08             	cmp    $0x8,%eax
f01053e9:	7f 0b                	jg     f01053f6 <vprintfmt+0x142>
f01053eb:	8b 14 85 e0 7f 10 f0 	mov    -0xfef8020(,%eax,4),%edx
f01053f2:	85 d2                	test   %edx,%edx
f01053f4:	75 18                	jne    f010540e <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f01053f6:	50                   	push   %eax
f01053f7:	68 ce 7d 10 f0       	push   $0xf0107dce
f01053fc:	53                   	push   %ebx
f01053fd:	56                   	push   %esi
f01053fe:	e8 94 fe ff ff       	call   f0105297 <printfmt>
f0105403:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105406:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0105409:	e9 cc fe ff ff       	jmp    f01052da <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f010540e:	52                   	push   %edx
f010540f:	68 f9 6b 10 f0       	push   $0xf0106bf9
f0105414:	53                   	push   %ebx
f0105415:	56                   	push   %esi
f0105416:	e8 7c fe ff ff       	call   f0105297 <printfmt>
f010541b:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010541e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0105421:	e9 b4 fe ff ff       	jmp    f01052da <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0105426:	8b 45 14             	mov    0x14(%ebp),%eax
f0105429:	8d 50 04             	lea    0x4(%eax),%edx
f010542c:	89 55 14             	mov    %edx,0x14(%ebp)
f010542f:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0105431:	85 ff                	test   %edi,%edi
f0105433:	b8 c7 7d 10 f0       	mov    $0xf0107dc7,%eax
f0105438:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f010543b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010543f:	0f 8e 94 00 00 00    	jle    f01054d9 <vprintfmt+0x225>
f0105445:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0105449:	0f 84 98 00 00 00    	je     f01054e7 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f010544f:	83 ec 08             	sub    $0x8,%esp
f0105452:	ff 75 d0             	pushl  -0x30(%ebp)
f0105455:	57                   	push   %edi
f0105456:	e8 5f 03 00 00       	call   f01057ba <strnlen>
f010545b:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010545e:	29 c1                	sub    %eax,%ecx
f0105460:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0105463:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0105466:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f010546a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010546d:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0105470:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0105472:	eb 0f                	jmp    f0105483 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0105474:	83 ec 08             	sub    $0x8,%esp
f0105477:	53                   	push   %ebx
f0105478:	ff 75 e0             	pushl  -0x20(%ebp)
f010547b:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010547d:	83 ef 01             	sub    $0x1,%edi
f0105480:	83 c4 10             	add    $0x10,%esp
f0105483:	85 ff                	test   %edi,%edi
f0105485:	7f ed                	jg     f0105474 <vprintfmt+0x1c0>
f0105487:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010548a:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f010548d:	85 c9                	test   %ecx,%ecx
f010548f:	b8 00 00 00 00       	mov    $0x0,%eax
f0105494:	0f 49 c1             	cmovns %ecx,%eax
f0105497:	29 c1                	sub    %eax,%ecx
f0105499:	89 75 08             	mov    %esi,0x8(%ebp)
f010549c:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010549f:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01054a2:	89 cb                	mov    %ecx,%ebx
f01054a4:	eb 4d                	jmp    f01054f3 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01054a6:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01054aa:	74 1b                	je     f01054c7 <vprintfmt+0x213>
f01054ac:	0f be c0             	movsbl %al,%eax
f01054af:	83 e8 20             	sub    $0x20,%eax
f01054b2:	83 f8 5e             	cmp    $0x5e,%eax
f01054b5:	76 10                	jbe    f01054c7 <vprintfmt+0x213>
					putch('?', putdat);
f01054b7:	83 ec 08             	sub    $0x8,%esp
f01054ba:	ff 75 0c             	pushl  0xc(%ebp)
f01054bd:	6a 3f                	push   $0x3f
f01054bf:	ff 55 08             	call   *0x8(%ebp)
f01054c2:	83 c4 10             	add    $0x10,%esp
f01054c5:	eb 0d                	jmp    f01054d4 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f01054c7:	83 ec 08             	sub    $0x8,%esp
f01054ca:	ff 75 0c             	pushl  0xc(%ebp)
f01054cd:	52                   	push   %edx
f01054ce:	ff 55 08             	call   *0x8(%ebp)
f01054d1:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01054d4:	83 eb 01             	sub    $0x1,%ebx
f01054d7:	eb 1a                	jmp    f01054f3 <vprintfmt+0x23f>
f01054d9:	89 75 08             	mov    %esi,0x8(%ebp)
f01054dc:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01054df:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01054e2:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01054e5:	eb 0c                	jmp    f01054f3 <vprintfmt+0x23f>
f01054e7:	89 75 08             	mov    %esi,0x8(%ebp)
f01054ea:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01054ed:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01054f0:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01054f3:	83 c7 01             	add    $0x1,%edi
f01054f6:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01054fa:	0f be d0             	movsbl %al,%edx
f01054fd:	85 d2                	test   %edx,%edx
f01054ff:	74 23                	je     f0105524 <vprintfmt+0x270>
f0105501:	85 f6                	test   %esi,%esi
f0105503:	78 a1                	js     f01054a6 <vprintfmt+0x1f2>
f0105505:	83 ee 01             	sub    $0x1,%esi
f0105508:	79 9c                	jns    f01054a6 <vprintfmt+0x1f2>
f010550a:	89 df                	mov    %ebx,%edi
f010550c:	8b 75 08             	mov    0x8(%ebp),%esi
f010550f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105512:	eb 18                	jmp    f010552c <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0105514:	83 ec 08             	sub    $0x8,%esp
f0105517:	53                   	push   %ebx
f0105518:	6a 20                	push   $0x20
f010551a:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010551c:	83 ef 01             	sub    $0x1,%edi
f010551f:	83 c4 10             	add    $0x10,%esp
f0105522:	eb 08                	jmp    f010552c <vprintfmt+0x278>
f0105524:	89 df                	mov    %ebx,%edi
f0105526:	8b 75 08             	mov    0x8(%ebp),%esi
f0105529:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010552c:	85 ff                	test   %edi,%edi
f010552e:	7f e4                	jg     f0105514 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105530:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0105533:	e9 a2 fd ff ff       	jmp    f01052da <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0105538:	83 fa 01             	cmp    $0x1,%edx
f010553b:	7e 16                	jle    f0105553 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f010553d:	8b 45 14             	mov    0x14(%ebp),%eax
f0105540:	8d 50 08             	lea    0x8(%eax),%edx
f0105543:	89 55 14             	mov    %edx,0x14(%ebp)
f0105546:	8b 50 04             	mov    0x4(%eax),%edx
f0105549:	8b 00                	mov    (%eax),%eax
f010554b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010554e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0105551:	eb 32                	jmp    f0105585 <vprintfmt+0x2d1>
	else if (lflag)
f0105553:	85 d2                	test   %edx,%edx
f0105555:	74 18                	je     f010556f <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0105557:	8b 45 14             	mov    0x14(%ebp),%eax
f010555a:	8d 50 04             	lea    0x4(%eax),%edx
f010555d:	89 55 14             	mov    %edx,0x14(%ebp)
f0105560:	8b 00                	mov    (%eax),%eax
f0105562:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105565:	89 c1                	mov    %eax,%ecx
f0105567:	c1 f9 1f             	sar    $0x1f,%ecx
f010556a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010556d:	eb 16                	jmp    f0105585 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f010556f:	8b 45 14             	mov    0x14(%ebp),%eax
f0105572:	8d 50 04             	lea    0x4(%eax),%edx
f0105575:	89 55 14             	mov    %edx,0x14(%ebp)
f0105578:	8b 00                	mov    (%eax),%eax
f010557a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010557d:	89 c1                	mov    %eax,%ecx
f010557f:	c1 f9 1f             	sar    $0x1f,%ecx
f0105582:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0105585:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0105588:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010558b:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0105590:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0105594:	79 74                	jns    f010560a <vprintfmt+0x356>
				putch('-', putdat);
f0105596:	83 ec 08             	sub    $0x8,%esp
f0105599:	53                   	push   %ebx
f010559a:	6a 2d                	push   $0x2d
f010559c:	ff d6                	call   *%esi
				num = -(long long) num;
f010559e:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01055a1:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01055a4:	f7 d8                	neg    %eax
f01055a6:	83 d2 00             	adc    $0x0,%edx
f01055a9:	f7 da                	neg    %edx
f01055ab:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f01055ae:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01055b3:	eb 55                	jmp    f010560a <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01055b5:	8d 45 14             	lea    0x14(%ebp),%eax
f01055b8:	e8 83 fc ff ff       	call   f0105240 <getuint>
			base = 10;
f01055bd:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01055c2:	eb 46                	jmp    f010560a <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f01055c4:	8d 45 14             	lea    0x14(%ebp),%eax
f01055c7:	e8 74 fc ff ff       	call   f0105240 <getuint>
      			base = 8;
f01055cc:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01055d1:	eb 37                	jmp    f010560a <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f01055d3:	83 ec 08             	sub    $0x8,%esp
f01055d6:	53                   	push   %ebx
f01055d7:	6a 30                	push   $0x30
f01055d9:	ff d6                	call   *%esi
			putch('x', putdat);
f01055db:	83 c4 08             	add    $0x8,%esp
f01055de:	53                   	push   %ebx
f01055df:	6a 78                	push   $0x78
f01055e1:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01055e3:	8b 45 14             	mov    0x14(%ebp),%eax
f01055e6:	8d 50 04             	lea    0x4(%eax),%edx
f01055e9:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01055ec:	8b 00                	mov    (%eax),%eax
f01055ee:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01055f3:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01055f6:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01055fb:	eb 0d                	jmp    f010560a <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01055fd:	8d 45 14             	lea    0x14(%ebp),%eax
f0105600:	e8 3b fc ff ff       	call   f0105240 <getuint>
			base = 16;
f0105605:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f010560a:	83 ec 0c             	sub    $0xc,%esp
f010560d:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0105611:	57                   	push   %edi
f0105612:	ff 75 e0             	pushl  -0x20(%ebp)
f0105615:	51                   	push   %ecx
f0105616:	52                   	push   %edx
f0105617:	50                   	push   %eax
f0105618:	89 da                	mov    %ebx,%edx
f010561a:	89 f0                	mov    %esi,%eax
f010561c:	e8 70 fb ff ff       	call   f0105191 <printnum>
			break;
f0105621:	83 c4 20             	add    $0x20,%esp
f0105624:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0105627:	e9 ae fc ff ff       	jmp    f01052da <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010562c:	83 ec 08             	sub    $0x8,%esp
f010562f:	53                   	push   %ebx
f0105630:	51                   	push   %ecx
f0105631:	ff d6                	call   *%esi
			break;
f0105633:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105636:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0105639:	e9 9c fc ff ff       	jmp    f01052da <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010563e:	83 ec 08             	sub    $0x8,%esp
f0105641:	53                   	push   %ebx
f0105642:	6a 25                	push   $0x25
f0105644:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0105646:	83 c4 10             	add    $0x10,%esp
f0105649:	eb 03                	jmp    f010564e <vprintfmt+0x39a>
f010564b:	83 ef 01             	sub    $0x1,%edi
f010564e:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0105652:	75 f7                	jne    f010564b <vprintfmt+0x397>
f0105654:	e9 81 fc ff ff       	jmp    f01052da <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0105659:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010565c:	5b                   	pop    %ebx
f010565d:	5e                   	pop    %esi
f010565e:	5f                   	pop    %edi
f010565f:	5d                   	pop    %ebp
f0105660:	c3                   	ret    

f0105661 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0105661:	55                   	push   %ebp
f0105662:	89 e5                	mov    %esp,%ebp
f0105664:	83 ec 18             	sub    $0x18,%esp
f0105667:	8b 45 08             	mov    0x8(%ebp),%eax
f010566a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010566d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0105670:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0105674:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0105677:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010567e:	85 c0                	test   %eax,%eax
f0105680:	74 26                	je     f01056a8 <vsnprintf+0x47>
f0105682:	85 d2                	test   %edx,%edx
f0105684:	7e 22                	jle    f01056a8 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0105686:	ff 75 14             	pushl  0x14(%ebp)
f0105689:	ff 75 10             	pushl  0x10(%ebp)
f010568c:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010568f:	50                   	push   %eax
f0105690:	68 7a 52 10 f0       	push   $0xf010527a
f0105695:	e8 1a fc ff ff       	call   f01052b4 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010569a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010569d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01056a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01056a3:	83 c4 10             	add    $0x10,%esp
f01056a6:	eb 05                	jmp    f01056ad <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01056a8:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01056ad:	c9                   	leave  
f01056ae:	c3                   	ret    

f01056af <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01056af:	55                   	push   %ebp
f01056b0:	89 e5                	mov    %esp,%ebp
f01056b2:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01056b5:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01056b8:	50                   	push   %eax
f01056b9:	ff 75 10             	pushl  0x10(%ebp)
f01056bc:	ff 75 0c             	pushl  0xc(%ebp)
f01056bf:	ff 75 08             	pushl  0x8(%ebp)
f01056c2:	e8 9a ff ff ff       	call   f0105661 <vsnprintf>
	va_end(ap);

	return rc;
}
f01056c7:	c9                   	leave  
f01056c8:	c3                   	ret    

f01056c9 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01056c9:	55                   	push   %ebp
f01056ca:	89 e5                	mov    %esp,%ebp
f01056cc:	57                   	push   %edi
f01056cd:	56                   	push   %esi
f01056ce:	53                   	push   %ebx
f01056cf:	83 ec 0c             	sub    $0xc,%esp
f01056d2:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01056d5:	85 c0                	test   %eax,%eax
f01056d7:	74 11                	je     f01056ea <readline+0x21>
		cprintf("%s", prompt);
f01056d9:	83 ec 08             	sub    $0x8,%esp
f01056dc:	50                   	push   %eax
f01056dd:	68 f9 6b 10 f0       	push   $0xf0106bf9
f01056e2:	e8 73 df ff ff       	call   f010365a <cprintf>
f01056e7:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01056ea:	83 ec 0c             	sub    $0xc,%esp
f01056ed:	6a 00                	push   $0x0
f01056ef:	e8 91 b0 ff ff       	call   f0100785 <iscons>
f01056f4:	89 c7                	mov    %eax,%edi
f01056f6:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01056f9:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01056fe:	e8 71 b0 ff ff       	call   f0100774 <getchar>
f0105703:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0105705:	85 c0                	test   %eax,%eax
f0105707:	79 18                	jns    f0105721 <readline+0x58>
			cprintf("read error: %e\n", c);
f0105709:	83 ec 08             	sub    $0x8,%esp
f010570c:	50                   	push   %eax
f010570d:	68 04 80 10 f0       	push   $0xf0108004
f0105712:	e8 43 df ff ff       	call   f010365a <cprintf>
			return NULL;
f0105717:	83 c4 10             	add    $0x10,%esp
f010571a:	b8 00 00 00 00       	mov    $0x0,%eax
f010571f:	eb 79                	jmp    f010579a <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0105721:	83 f8 08             	cmp    $0x8,%eax
f0105724:	0f 94 c2             	sete   %dl
f0105727:	83 f8 7f             	cmp    $0x7f,%eax
f010572a:	0f 94 c0             	sete   %al
f010572d:	08 c2                	or     %al,%dl
f010572f:	74 1a                	je     f010574b <readline+0x82>
f0105731:	85 f6                	test   %esi,%esi
f0105733:	7e 16                	jle    f010574b <readline+0x82>
			if (echoing)
f0105735:	85 ff                	test   %edi,%edi
f0105737:	74 0d                	je     f0105746 <readline+0x7d>
				cputchar('\b');
f0105739:	83 ec 0c             	sub    $0xc,%esp
f010573c:	6a 08                	push   $0x8
f010573e:	e8 21 b0 ff ff       	call   f0100764 <cputchar>
f0105743:	83 c4 10             	add    $0x10,%esp
			i--;
f0105746:	83 ee 01             	sub    $0x1,%esi
f0105749:	eb b3                	jmp    f01056fe <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010574b:	83 fb 1f             	cmp    $0x1f,%ebx
f010574e:	7e 23                	jle    f0105773 <readline+0xaa>
f0105750:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0105756:	7f 1b                	jg     f0105773 <readline+0xaa>
			if (echoing)
f0105758:	85 ff                	test   %edi,%edi
f010575a:	74 0c                	je     f0105768 <readline+0x9f>
				cputchar(c);
f010575c:	83 ec 0c             	sub    $0xc,%esp
f010575f:	53                   	push   %ebx
f0105760:	e8 ff af ff ff       	call   f0100764 <cputchar>
f0105765:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0105768:	88 9e 80 ca 22 f0    	mov    %bl,-0xfdd3580(%esi)
f010576e:	8d 76 01             	lea    0x1(%esi),%esi
f0105771:	eb 8b                	jmp    f01056fe <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0105773:	83 fb 0a             	cmp    $0xa,%ebx
f0105776:	74 05                	je     f010577d <readline+0xb4>
f0105778:	83 fb 0d             	cmp    $0xd,%ebx
f010577b:	75 81                	jne    f01056fe <readline+0x35>
			if (echoing)
f010577d:	85 ff                	test   %edi,%edi
f010577f:	74 0d                	je     f010578e <readline+0xc5>
				cputchar('\n');
f0105781:	83 ec 0c             	sub    $0xc,%esp
f0105784:	6a 0a                	push   $0xa
f0105786:	e8 d9 af ff ff       	call   f0100764 <cputchar>
f010578b:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f010578e:	c6 86 80 ca 22 f0 00 	movb   $0x0,-0xfdd3580(%esi)
			return buf;
f0105795:	b8 80 ca 22 f0       	mov    $0xf022ca80,%eax
		}
	}
}
f010579a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010579d:	5b                   	pop    %ebx
f010579e:	5e                   	pop    %esi
f010579f:	5f                   	pop    %edi
f01057a0:	5d                   	pop    %ebp
f01057a1:	c3                   	ret    

f01057a2 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01057a2:	55                   	push   %ebp
f01057a3:	89 e5                	mov    %esp,%ebp
f01057a5:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01057a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01057ad:	eb 03                	jmp    f01057b2 <strlen+0x10>
		n++;
f01057af:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01057b2:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01057b6:	75 f7                	jne    f01057af <strlen+0xd>
		n++;
	return n;
}
f01057b8:	5d                   	pop    %ebp
f01057b9:	c3                   	ret    

f01057ba <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01057ba:	55                   	push   %ebp
f01057bb:	89 e5                	mov    %esp,%ebp
f01057bd:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01057c0:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01057c3:	ba 00 00 00 00       	mov    $0x0,%edx
f01057c8:	eb 03                	jmp    f01057cd <strnlen+0x13>
		n++;
f01057ca:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01057cd:	39 c2                	cmp    %eax,%edx
f01057cf:	74 08                	je     f01057d9 <strnlen+0x1f>
f01057d1:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01057d5:	75 f3                	jne    f01057ca <strnlen+0x10>
f01057d7:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01057d9:	5d                   	pop    %ebp
f01057da:	c3                   	ret    

f01057db <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01057db:	55                   	push   %ebp
f01057dc:	89 e5                	mov    %esp,%ebp
f01057de:	53                   	push   %ebx
f01057df:	8b 45 08             	mov    0x8(%ebp),%eax
f01057e2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01057e5:	89 c2                	mov    %eax,%edx
f01057e7:	83 c2 01             	add    $0x1,%edx
f01057ea:	83 c1 01             	add    $0x1,%ecx
f01057ed:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01057f1:	88 5a ff             	mov    %bl,-0x1(%edx)
f01057f4:	84 db                	test   %bl,%bl
f01057f6:	75 ef                	jne    f01057e7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01057f8:	5b                   	pop    %ebx
f01057f9:	5d                   	pop    %ebp
f01057fa:	c3                   	ret    

f01057fb <strcat>:

char *
strcat(char *dst, const char *src)
{
f01057fb:	55                   	push   %ebp
f01057fc:	89 e5                	mov    %esp,%ebp
f01057fe:	53                   	push   %ebx
f01057ff:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0105802:	53                   	push   %ebx
f0105803:	e8 9a ff ff ff       	call   f01057a2 <strlen>
f0105808:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010580b:	ff 75 0c             	pushl  0xc(%ebp)
f010580e:	01 d8                	add    %ebx,%eax
f0105810:	50                   	push   %eax
f0105811:	e8 c5 ff ff ff       	call   f01057db <strcpy>
	return dst;
}
f0105816:	89 d8                	mov    %ebx,%eax
f0105818:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010581b:	c9                   	leave  
f010581c:	c3                   	ret    

f010581d <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010581d:	55                   	push   %ebp
f010581e:	89 e5                	mov    %esp,%ebp
f0105820:	56                   	push   %esi
f0105821:	53                   	push   %ebx
f0105822:	8b 75 08             	mov    0x8(%ebp),%esi
f0105825:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105828:	89 f3                	mov    %esi,%ebx
f010582a:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010582d:	89 f2                	mov    %esi,%edx
f010582f:	eb 0f                	jmp    f0105840 <strncpy+0x23>
		*dst++ = *src;
f0105831:	83 c2 01             	add    $0x1,%edx
f0105834:	0f b6 01             	movzbl (%ecx),%eax
f0105837:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010583a:	80 39 01             	cmpb   $0x1,(%ecx)
f010583d:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105840:	39 da                	cmp    %ebx,%edx
f0105842:	75 ed                	jne    f0105831 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0105844:	89 f0                	mov    %esi,%eax
f0105846:	5b                   	pop    %ebx
f0105847:	5e                   	pop    %esi
f0105848:	5d                   	pop    %ebp
f0105849:	c3                   	ret    

f010584a <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010584a:	55                   	push   %ebp
f010584b:	89 e5                	mov    %esp,%ebp
f010584d:	56                   	push   %esi
f010584e:	53                   	push   %ebx
f010584f:	8b 75 08             	mov    0x8(%ebp),%esi
f0105852:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105855:	8b 55 10             	mov    0x10(%ebp),%edx
f0105858:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010585a:	85 d2                	test   %edx,%edx
f010585c:	74 21                	je     f010587f <strlcpy+0x35>
f010585e:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0105862:	89 f2                	mov    %esi,%edx
f0105864:	eb 09                	jmp    f010586f <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0105866:	83 c2 01             	add    $0x1,%edx
f0105869:	83 c1 01             	add    $0x1,%ecx
f010586c:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010586f:	39 c2                	cmp    %eax,%edx
f0105871:	74 09                	je     f010587c <strlcpy+0x32>
f0105873:	0f b6 19             	movzbl (%ecx),%ebx
f0105876:	84 db                	test   %bl,%bl
f0105878:	75 ec                	jne    f0105866 <strlcpy+0x1c>
f010587a:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010587c:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010587f:	29 f0                	sub    %esi,%eax
}
f0105881:	5b                   	pop    %ebx
f0105882:	5e                   	pop    %esi
f0105883:	5d                   	pop    %ebp
f0105884:	c3                   	ret    

f0105885 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0105885:	55                   	push   %ebp
f0105886:	89 e5                	mov    %esp,%ebp
f0105888:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010588b:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010588e:	eb 06                	jmp    f0105896 <strcmp+0x11>
		p++, q++;
f0105890:	83 c1 01             	add    $0x1,%ecx
f0105893:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0105896:	0f b6 01             	movzbl (%ecx),%eax
f0105899:	84 c0                	test   %al,%al
f010589b:	74 04                	je     f01058a1 <strcmp+0x1c>
f010589d:	3a 02                	cmp    (%edx),%al
f010589f:	74 ef                	je     f0105890 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01058a1:	0f b6 c0             	movzbl %al,%eax
f01058a4:	0f b6 12             	movzbl (%edx),%edx
f01058a7:	29 d0                	sub    %edx,%eax
}
f01058a9:	5d                   	pop    %ebp
f01058aa:	c3                   	ret    

f01058ab <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01058ab:	55                   	push   %ebp
f01058ac:	89 e5                	mov    %esp,%ebp
f01058ae:	53                   	push   %ebx
f01058af:	8b 45 08             	mov    0x8(%ebp),%eax
f01058b2:	8b 55 0c             	mov    0xc(%ebp),%edx
f01058b5:	89 c3                	mov    %eax,%ebx
f01058b7:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01058ba:	eb 06                	jmp    f01058c2 <strncmp+0x17>
		n--, p++, q++;
f01058bc:	83 c0 01             	add    $0x1,%eax
f01058bf:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01058c2:	39 d8                	cmp    %ebx,%eax
f01058c4:	74 15                	je     f01058db <strncmp+0x30>
f01058c6:	0f b6 08             	movzbl (%eax),%ecx
f01058c9:	84 c9                	test   %cl,%cl
f01058cb:	74 04                	je     f01058d1 <strncmp+0x26>
f01058cd:	3a 0a                	cmp    (%edx),%cl
f01058cf:	74 eb                	je     f01058bc <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01058d1:	0f b6 00             	movzbl (%eax),%eax
f01058d4:	0f b6 12             	movzbl (%edx),%edx
f01058d7:	29 d0                	sub    %edx,%eax
f01058d9:	eb 05                	jmp    f01058e0 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01058db:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01058e0:	5b                   	pop    %ebx
f01058e1:	5d                   	pop    %ebp
f01058e2:	c3                   	ret    

f01058e3 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01058e3:	55                   	push   %ebp
f01058e4:	89 e5                	mov    %esp,%ebp
f01058e6:	8b 45 08             	mov    0x8(%ebp),%eax
f01058e9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01058ed:	eb 07                	jmp    f01058f6 <strchr+0x13>
		if (*s == c)
f01058ef:	38 ca                	cmp    %cl,%dl
f01058f1:	74 0f                	je     f0105902 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01058f3:	83 c0 01             	add    $0x1,%eax
f01058f6:	0f b6 10             	movzbl (%eax),%edx
f01058f9:	84 d2                	test   %dl,%dl
f01058fb:	75 f2                	jne    f01058ef <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01058fd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105902:	5d                   	pop    %ebp
f0105903:	c3                   	ret    

f0105904 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0105904:	55                   	push   %ebp
f0105905:	89 e5                	mov    %esp,%ebp
f0105907:	8b 45 08             	mov    0x8(%ebp),%eax
f010590a:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010590e:	eb 03                	jmp    f0105913 <strfind+0xf>
f0105910:	83 c0 01             	add    $0x1,%eax
f0105913:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0105916:	38 ca                	cmp    %cl,%dl
f0105918:	74 04                	je     f010591e <strfind+0x1a>
f010591a:	84 d2                	test   %dl,%dl
f010591c:	75 f2                	jne    f0105910 <strfind+0xc>
			break;
	return (char *) s;
}
f010591e:	5d                   	pop    %ebp
f010591f:	c3                   	ret    

f0105920 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105920:	55                   	push   %ebp
f0105921:	89 e5                	mov    %esp,%ebp
f0105923:	57                   	push   %edi
f0105924:	56                   	push   %esi
f0105925:	53                   	push   %ebx
f0105926:	8b 7d 08             	mov    0x8(%ebp),%edi
f0105929:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010592c:	85 c9                	test   %ecx,%ecx
f010592e:	74 36                	je     f0105966 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0105930:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0105936:	75 28                	jne    f0105960 <memset+0x40>
f0105938:	f6 c1 03             	test   $0x3,%cl
f010593b:	75 23                	jne    f0105960 <memset+0x40>
		c &= 0xFF;
f010593d:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0105941:	89 d3                	mov    %edx,%ebx
f0105943:	c1 e3 08             	shl    $0x8,%ebx
f0105946:	89 d6                	mov    %edx,%esi
f0105948:	c1 e6 18             	shl    $0x18,%esi
f010594b:	89 d0                	mov    %edx,%eax
f010594d:	c1 e0 10             	shl    $0x10,%eax
f0105950:	09 f0                	or     %esi,%eax
f0105952:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0105954:	89 d8                	mov    %ebx,%eax
f0105956:	09 d0                	or     %edx,%eax
f0105958:	c1 e9 02             	shr    $0x2,%ecx
f010595b:	fc                   	cld    
f010595c:	f3 ab                	rep stos %eax,%es:(%edi)
f010595e:	eb 06                	jmp    f0105966 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0105960:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105963:	fc                   	cld    
f0105964:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0105966:	89 f8                	mov    %edi,%eax
f0105968:	5b                   	pop    %ebx
f0105969:	5e                   	pop    %esi
f010596a:	5f                   	pop    %edi
f010596b:	5d                   	pop    %ebp
f010596c:	c3                   	ret    

f010596d <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010596d:	55                   	push   %ebp
f010596e:	89 e5                	mov    %esp,%ebp
f0105970:	57                   	push   %edi
f0105971:	56                   	push   %esi
f0105972:	8b 45 08             	mov    0x8(%ebp),%eax
f0105975:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105978:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010597b:	39 c6                	cmp    %eax,%esi
f010597d:	73 35                	jae    f01059b4 <memmove+0x47>
f010597f:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0105982:	39 d0                	cmp    %edx,%eax
f0105984:	73 2e                	jae    f01059b4 <memmove+0x47>
		s += n;
		d += n;
f0105986:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105989:	89 d6                	mov    %edx,%esi
f010598b:	09 fe                	or     %edi,%esi
f010598d:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0105993:	75 13                	jne    f01059a8 <memmove+0x3b>
f0105995:	f6 c1 03             	test   $0x3,%cl
f0105998:	75 0e                	jne    f01059a8 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010599a:	83 ef 04             	sub    $0x4,%edi
f010599d:	8d 72 fc             	lea    -0x4(%edx),%esi
f01059a0:	c1 e9 02             	shr    $0x2,%ecx
f01059a3:	fd                   	std    
f01059a4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01059a6:	eb 09                	jmp    f01059b1 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01059a8:	83 ef 01             	sub    $0x1,%edi
f01059ab:	8d 72 ff             	lea    -0x1(%edx),%esi
f01059ae:	fd                   	std    
f01059af:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01059b1:	fc                   	cld    
f01059b2:	eb 1d                	jmp    f01059d1 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01059b4:	89 f2                	mov    %esi,%edx
f01059b6:	09 c2                	or     %eax,%edx
f01059b8:	f6 c2 03             	test   $0x3,%dl
f01059bb:	75 0f                	jne    f01059cc <memmove+0x5f>
f01059bd:	f6 c1 03             	test   $0x3,%cl
f01059c0:	75 0a                	jne    f01059cc <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01059c2:	c1 e9 02             	shr    $0x2,%ecx
f01059c5:	89 c7                	mov    %eax,%edi
f01059c7:	fc                   	cld    
f01059c8:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01059ca:	eb 05                	jmp    f01059d1 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01059cc:	89 c7                	mov    %eax,%edi
f01059ce:	fc                   	cld    
f01059cf:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01059d1:	5e                   	pop    %esi
f01059d2:	5f                   	pop    %edi
f01059d3:	5d                   	pop    %ebp
f01059d4:	c3                   	ret    

f01059d5 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01059d5:	55                   	push   %ebp
f01059d6:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01059d8:	ff 75 10             	pushl  0x10(%ebp)
f01059db:	ff 75 0c             	pushl  0xc(%ebp)
f01059de:	ff 75 08             	pushl  0x8(%ebp)
f01059e1:	e8 87 ff ff ff       	call   f010596d <memmove>
}
f01059e6:	c9                   	leave  
f01059e7:	c3                   	ret    

f01059e8 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01059e8:	55                   	push   %ebp
f01059e9:	89 e5                	mov    %esp,%ebp
f01059eb:	56                   	push   %esi
f01059ec:	53                   	push   %ebx
f01059ed:	8b 45 08             	mov    0x8(%ebp),%eax
f01059f0:	8b 55 0c             	mov    0xc(%ebp),%edx
f01059f3:	89 c6                	mov    %eax,%esi
f01059f5:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01059f8:	eb 1a                	jmp    f0105a14 <memcmp+0x2c>
		if (*s1 != *s2)
f01059fa:	0f b6 08             	movzbl (%eax),%ecx
f01059fd:	0f b6 1a             	movzbl (%edx),%ebx
f0105a00:	38 d9                	cmp    %bl,%cl
f0105a02:	74 0a                	je     f0105a0e <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0105a04:	0f b6 c1             	movzbl %cl,%eax
f0105a07:	0f b6 db             	movzbl %bl,%ebx
f0105a0a:	29 d8                	sub    %ebx,%eax
f0105a0c:	eb 0f                	jmp    f0105a1d <memcmp+0x35>
		s1++, s2++;
f0105a0e:	83 c0 01             	add    $0x1,%eax
f0105a11:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105a14:	39 f0                	cmp    %esi,%eax
f0105a16:	75 e2                	jne    f01059fa <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0105a18:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105a1d:	5b                   	pop    %ebx
f0105a1e:	5e                   	pop    %esi
f0105a1f:	5d                   	pop    %ebp
f0105a20:	c3                   	ret    

f0105a21 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0105a21:	55                   	push   %ebp
f0105a22:	89 e5                	mov    %esp,%ebp
f0105a24:	53                   	push   %ebx
f0105a25:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0105a28:	89 c1                	mov    %eax,%ecx
f0105a2a:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0105a2d:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0105a31:	eb 0a                	jmp    f0105a3d <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0105a33:	0f b6 10             	movzbl (%eax),%edx
f0105a36:	39 da                	cmp    %ebx,%edx
f0105a38:	74 07                	je     f0105a41 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0105a3a:	83 c0 01             	add    $0x1,%eax
f0105a3d:	39 c8                	cmp    %ecx,%eax
f0105a3f:	72 f2                	jb     f0105a33 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0105a41:	5b                   	pop    %ebx
f0105a42:	5d                   	pop    %ebp
f0105a43:	c3                   	ret    

f0105a44 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0105a44:	55                   	push   %ebp
f0105a45:	89 e5                	mov    %esp,%ebp
f0105a47:	57                   	push   %edi
f0105a48:	56                   	push   %esi
f0105a49:	53                   	push   %ebx
f0105a4a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105a4d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105a50:	eb 03                	jmp    f0105a55 <strtol+0x11>
		s++;
f0105a52:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105a55:	0f b6 01             	movzbl (%ecx),%eax
f0105a58:	3c 20                	cmp    $0x20,%al
f0105a5a:	74 f6                	je     f0105a52 <strtol+0xe>
f0105a5c:	3c 09                	cmp    $0x9,%al
f0105a5e:	74 f2                	je     f0105a52 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0105a60:	3c 2b                	cmp    $0x2b,%al
f0105a62:	75 0a                	jne    f0105a6e <strtol+0x2a>
		s++;
f0105a64:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0105a67:	bf 00 00 00 00       	mov    $0x0,%edi
f0105a6c:	eb 11                	jmp    f0105a7f <strtol+0x3b>
f0105a6e:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0105a73:	3c 2d                	cmp    $0x2d,%al
f0105a75:	75 08                	jne    f0105a7f <strtol+0x3b>
		s++, neg = 1;
f0105a77:	83 c1 01             	add    $0x1,%ecx
f0105a7a:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105a7f:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0105a85:	75 15                	jne    f0105a9c <strtol+0x58>
f0105a87:	80 39 30             	cmpb   $0x30,(%ecx)
f0105a8a:	75 10                	jne    f0105a9c <strtol+0x58>
f0105a8c:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0105a90:	75 7c                	jne    f0105b0e <strtol+0xca>
		s += 2, base = 16;
f0105a92:	83 c1 02             	add    $0x2,%ecx
f0105a95:	bb 10 00 00 00       	mov    $0x10,%ebx
f0105a9a:	eb 16                	jmp    f0105ab2 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0105a9c:	85 db                	test   %ebx,%ebx
f0105a9e:	75 12                	jne    f0105ab2 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105aa0:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105aa5:	80 39 30             	cmpb   $0x30,(%ecx)
f0105aa8:	75 08                	jne    f0105ab2 <strtol+0x6e>
		s++, base = 8;
f0105aaa:	83 c1 01             	add    $0x1,%ecx
f0105aad:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0105ab2:	b8 00 00 00 00       	mov    $0x0,%eax
f0105ab7:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0105aba:	0f b6 11             	movzbl (%ecx),%edx
f0105abd:	8d 72 d0             	lea    -0x30(%edx),%esi
f0105ac0:	89 f3                	mov    %esi,%ebx
f0105ac2:	80 fb 09             	cmp    $0x9,%bl
f0105ac5:	77 08                	ja     f0105acf <strtol+0x8b>
			dig = *s - '0';
f0105ac7:	0f be d2             	movsbl %dl,%edx
f0105aca:	83 ea 30             	sub    $0x30,%edx
f0105acd:	eb 22                	jmp    f0105af1 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0105acf:	8d 72 9f             	lea    -0x61(%edx),%esi
f0105ad2:	89 f3                	mov    %esi,%ebx
f0105ad4:	80 fb 19             	cmp    $0x19,%bl
f0105ad7:	77 08                	ja     f0105ae1 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0105ad9:	0f be d2             	movsbl %dl,%edx
f0105adc:	83 ea 57             	sub    $0x57,%edx
f0105adf:	eb 10                	jmp    f0105af1 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0105ae1:	8d 72 bf             	lea    -0x41(%edx),%esi
f0105ae4:	89 f3                	mov    %esi,%ebx
f0105ae6:	80 fb 19             	cmp    $0x19,%bl
f0105ae9:	77 16                	ja     f0105b01 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0105aeb:	0f be d2             	movsbl %dl,%edx
f0105aee:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0105af1:	3b 55 10             	cmp    0x10(%ebp),%edx
f0105af4:	7d 0b                	jge    f0105b01 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0105af6:	83 c1 01             	add    $0x1,%ecx
f0105af9:	0f af 45 10          	imul   0x10(%ebp),%eax
f0105afd:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0105aff:	eb b9                	jmp    f0105aba <strtol+0x76>

	if (endptr)
f0105b01:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0105b05:	74 0d                	je     f0105b14 <strtol+0xd0>
		*endptr = (char *) s;
f0105b07:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105b0a:	89 0e                	mov    %ecx,(%esi)
f0105b0c:	eb 06                	jmp    f0105b14 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105b0e:	85 db                	test   %ebx,%ebx
f0105b10:	74 98                	je     f0105aaa <strtol+0x66>
f0105b12:	eb 9e                	jmp    f0105ab2 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0105b14:	89 c2                	mov    %eax,%edx
f0105b16:	f7 da                	neg    %edx
f0105b18:	85 ff                	test   %edi,%edi
f0105b1a:	0f 45 c2             	cmovne %edx,%eax
}
f0105b1d:	5b                   	pop    %ebx
f0105b1e:	5e                   	pop    %esi
f0105b1f:	5f                   	pop    %edi
f0105b20:	5d                   	pop    %ebp
f0105b21:	c3                   	ret    
f0105b22:	66 90                	xchg   %ax,%ax

f0105b24 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0105b24:	fa                   	cli    

	xorw    %ax, %ax
f0105b25:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f0105b27:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105b29:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105b2b:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0105b2d:	0f 01 16             	lgdtl  (%esi)
f0105b30:	74 70                	je     f0105ba2 <mpsearch1+0x3>
	movl    %cr0, %eax
f0105b32:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0105b35:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0105b39:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0105b3c:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f0105b42:	08 00                	or     %al,(%eax)

f0105b44 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0105b44:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0105b48:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105b4a:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105b4c:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0105b4e:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f0105b52:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0105b54:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f0105b56:	b8 00 f0 11 00       	mov    $0x11f000,%eax
	movl    %eax, %cr3
f0105b5b:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0105b5e:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0105b61:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f0105b66:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0105b69:	8b 25 84 ce 22 f0    	mov    0xf022ce84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0105b6f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0105b74:	b8 b3 01 10 f0       	mov    $0xf01001b3,%eax
	call    *%eax
f0105b79:	ff d0                	call   *%eax

f0105b7b <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0105b7b:	eb fe                	jmp    f0105b7b <spin>
f0105b7d:	8d 76 00             	lea    0x0(%esi),%esi

f0105b80 <gdt>:
	...
f0105b88:	ff                   	(bad)  
f0105b89:	ff 00                	incl   (%eax)
f0105b8b:	00 00                	add    %al,(%eax)
f0105b8d:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0105b94:	00                   	.byte 0x0
f0105b95:	92                   	xchg   %eax,%edx
f0105b96:	cf                   	iret   
	...

f0105b98 <gdtdesc>:
f0105b98:	17                   	pop    %ss
f0105b99:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0105b9e <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0105b9e:	90                   	nop

f0105b9f <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0105b9f:	55                   	push   %ebp
f0105ba0:	89 e5                	mov    %esp,%ebp
f0105ba2:	57                   	push   %edi
f0105ba3:	56                   	push   %esi
f0105ba4:	53                   	push   %ebx
f0105ba5:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105ba8:	8b 0d 88 ce 22 f0    	mov    0xf022ce88,%ecx
f0105bae:	89 c3                	mov    %eax,%ebx
f0105bb0:	c1 eb 0c             	shr    $0xc,%ebx
f0105bb3:	39 cb                	cmp    %ecx,%ebx
f0105bb5:	72 12                	jb     f0105bc9 <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105bb7:	50                   	push   %eax
f0105bb8:	68 04 66 10 f0       	push   $0xf0106604
f0105bbd:	6a 57                	push   $0x57
f0105bbf:	68 a1 81 10 f0       	push   $0xf01081a1
f0105bc4:	e8 77 a4 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105bc9:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0105bcf:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105bd1:	89 c2                	mov    %eax,%edx
f0105bd3:	c1 ea 0c             	shr    $0xc,%edx
f0105bd6:	39 ca                	cmp    %ecx,%edx
f0105bd8:	72 12                	jb     f0105bec <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105bda:	50                   	push   %eax
f0105bdb:	68 04 66 10 f0       	push   $0xf0106604
f0105be0:	6a 57                	push   $0x57
f0105be2:	68 a1 81 10 f0       	push   $0xf01081a1
f0105be7:	e8 54 a4 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105bec:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f0105bf2:	eb 2f                	jmp    f0105c23 <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105bf4:	83 ec 04             	sub    $0x4,%esp
f0105bf7:	6a 04                	push   $0x4
f0105bf9:	68 b1 81 10 f0       	push   $0xf01081b1
f0105bfe:	53                   	push   %ebx
f0105bff:	e8 e4 fd ff ff       	call   f01059e8 <memcmp>
f0105c04:	83 c4 10             	add    $0x10,%esp
f0105c07:	85 c0                	test   %eax,%eax
f0105c09:	75 15                	jne    f0105c20 <mpsearch1+0x81>
f0105c0b:	89 da                	mov    %ebx,%edx
f0105c0d:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f0105c10:	0f b6 0a             	movzbl (%edx),%ecx
f0105c13:	01 c8                	add    %ecx,%eax
f0105c15:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105c18:	39 d7                	cmp    %edx,%edi
f0105c1a:	75 f4                	jne    f0105c10 <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105c1c:	84 c0                	test   %al,%al
f0105c1e:	74 0e                	je     f0105c2e <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f0105c20:	83 c3 10             	add    $0x10,%ebx
f0105c23:	39 f3                	cmp    %esi,%ebx
f0105c25:	72 cd                	jb     f0105bf4 <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f0105c27:	b8 00 00 00 00       	mov    $0x0,%eax
f0105c2c:	eb 02                	jmp    f0105c30 <mpsearch1+0x91>
f0105c2e:	89 d8                	mov    %ebx,%eax
}
f0105c30:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105c33:	5b                   	pop    %ebx
f0105c34:	5e                   	pop    %esi
f0105c35:	5f                   	pop    %edi
f0105c36:	5d                   	pop    %ebp
f0105c37:	c3                   	ret    

f0105c38 <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0105c38:	55                   	push   %ebp
f0105c39:	89 e5                	mov    %esp,%ebp
f0105c3b:	57                   	push   %edi
f0105c3c:	56                   	push   %esi
f0105c3d:	53                   	push   %ebx
f0105c3e:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0105c41:	c7 05 c0 d3 22 f0 20 	movl   $0xf022d020,0xf022d3c0
f0105c48:	d0 22 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105c4b:	83 3d 88 ce 22 f0 00 	cmpl   $0x0,0xf022ce88
f0105c52:	75 16                	jne    f0105c6a <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105c54:	68 00 04 00 00       	push   $0x400
f0105c59:	68 04 66 10 f0       	push   $0xf0106604
f0105c5e:	6a 6f                	push   $0x6f
f0105c60:	68 a1 81 10 f0       	push   $0xf01081a1
f0105c65:	e8 d6 a3 ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0105c6a:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105c71:	85 c0                	test   %eax,%eax
f0105c73:	74 16                	je     f0105c8b <mp_init+0x53>
		p <<= 4;	// Translate from segment to PA
		if ((mp = mpsearch1(p, 1024)))
f0105c75:	c1 e0 04             	shl    $0x4,%eax
f0105c78:	ba 00 04 00 00       	mov    $0x400,%edx
f0105c7d:	e8 1d ff ff ff       	call   f0105b9f <mpsearch1>
f0105c82:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105c85:	85 c0                	test   %eax,%eax
f0105c87:	75 3c                	jne    f0105cc5 <mp_init+0x8d>
f0105c89:	eb 20                	jmp    f0105cab <mp_init+0x73>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
		if ((mp = mpsearch1(p - 1024, 1024)))
f0105c8b:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0105c92:	c1 e0 0a             	shl    $0xa,%eax
f0105c95:	2d 00 04 00 00       	sub    $0x400,%eax
f0105c9a:	ba 00 04 00 00       	mov    $0x400,%edx
f0105c9f:	e8 fb fe ff ff       	call   f0105b9f <mpsearch1>
f0105ca4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105ca7:	85 c0                	test   %eax,%eax
f0105ca9:	75 1a                	jne    f0105cc5 <mp_init+0x8d>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f0105cab:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105cb0:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0105cb5:	e8 e5 fe ff ff       	call   f0105b9f <mpsearch1>
f0105cba:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f0105cbd:	85 c0                	test   %eax,%eax
f0105cbf:	0f 84 5d 02 00 00    	je     f0105f22 <mp_init+0x2ea>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f0105cc5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105cc8:	8b 70 04             	mov    0x4(%eax),%esi
f0105ccb:	85 f6                	test   %esi,%esi
f0105ccd:	74 06                	je     f0105cd5 <mp_init+0x9d>
f0105ccf:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f0105cd3:	74 15                	je     f0105cea <mp_init+0xb2>
		cprintf("SMP: Default configurations not implemented\n");
f0105cd5:	83 ec 0c             	sub    $0xc,%esp
f0105cd8:	68 14 80 10 f0       	push   $0xf0108014
f0105cdd:	e8 78 d9 ff ff       	call   f010365a <cprintf>
f0105ce2:	83 c4 10             	add    $0x10,%esp
f0105ce5:	e9 38 02 00 00       	jmp    f0105f22 <mp_init+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105cea:	89 f0                	mov    %esi,%eax
f0105cec:	c1 e8 0c             	shr    $0xc,%eax
f0105cef:	3b 05 88 ce 22 f0    	cmp    0xf022ce88,%eax
f0105cf5:	72 15                	jb     f0105d0c <mp_init+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105cf7:	56                   	push   %esi
f0105cf8:	68 04 66 10 f0       	push   $0xf0106604
f0105cfd:	68 90 00 00 00       	push   $0x90
f0105d02:	68 a1 81 10 f0       	push   $0xf01081a1
f0105d07:	e8 34 a3 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105d0c:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f0105d12:	83 ec 04             	sub    $0x4,%esp
f0105d15:	6a 04                	push   $0x4
f0105d17:	68 b6 81 10 f0       	push   $0xf01081b6
f0105d1c:	53                   	push   %ebx
f0105d1d:	e8 c6 fc ff ff       	call   f01059e8 <memcmp>
f0105d22:	83 c4 10             	add    $0x10,%esp
f0105d25:	85 c0                	test   %eax,%eax
f0105d27:	74 15                	je     f0105d3e <mp_init+0x106>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0105d29:	83 ec 0c             	sub    $0xc,%esp
f0105d2c:	68 44 80 10 f0       	push   $0xf0108044
f0105d31:	e8 24 d9 ff ff       	call   f010365a <cprintf>
f0105d36:	83 c4 10             	add    $0x10,%esp
f0105d39:	e9 e4 01 00 00       	jmp    f0105f22 <mp_init+0x2ea>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105d3e:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f0105d42:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f0105d46:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105d49:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105d4e:	b8 00 00 00 00       	mov    $0x0,%eax
f0105d53:	eb 0d                	jmp    f0105d62 <mp_init+0x12a>
		sum += ((uint8_t *)addr)[i];
f0105d55:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0105d5c:	f0 
f0105d5d:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105d5f:	83 c0 01             	add    $0x1,%eax
f0105d62:	39 c7                	cmp    %eax,%edi
f0105d64:	75 ef                	jne    f0105d55 <mp_init+0x11d>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105d66:	84 d2                	test   %dl,%dl
f0105d68:	74 15                	je     f0105d7f <mp_init+0x147>
		cprintf("SMP: Bad MP configuration checksum\n");
f0105d6a:	83 ec 0c             	sub    $0xc,%esp
f0105d6d:	68 78 80 10 f0       	push   $0xf0108078
f0105d72:	e8 e3 d8 ff ff       	call   f010365a <cprintf>
f0105d77:	83 c4 10             	add    $0x10,%esp
f0105d7a:	e9 a3 01 00 00       	jmp    f0105f22 <mp_init+0x2ea>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0105d7f:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f0105d83:	3c 01                	cmp    $0x1,%al
f0105d85:	74 1d                	je     f0105da4 <mp_init+0x16c>
f0105d87:	3c 04                	cmp    $0x4,%al
f0105d89:	74 19                	je     f0105da4 <mp_init+0x16c>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0105d8b:	83 ec 08             	sub    $0x8,%esp
f0105d8e:	0f b6 c0             	movzbl %al,%eax
f0105d91:	50                   	push   %eax
f0105d92:	68 9c 80 10 f0       	push   $0xf010809c
f0105d97:	e8 be d8 ff ff       	call   f010365a <cprintf>
f0105d9c:	83 c4 10             	add    $0x10,%esp
f0105d9f:	e9 7e 01 00 00       	jmp    f0105f22 <mp_init+0x2ea>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105da4:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f0105da8:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105dac:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105db1:	b8 00 00 00 00       	mov    $0x0,%eax
		sum += ((uint8_t *)addr)[i];
f0105db6:	01 ce                	add    %ecx,%esi
f0105db8:	eb 0d                	jmp    f0105dc7 <mp_init+0x18f>
f0105dba:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f0105dc1:	f0 
f0105dc2:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105dc4:	83 c0 01             	add    $0x1,%eax
f0105dc7:	39 c7                	cmp    %eax,%edi
f0105dc9:	75 ef                	jne    f0105dba <mp_init+0x182>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105dcb:	89 d0                	mov    %edx,%eax
f0105dcd:	02 43 2a             	add    0x2a(%ebx),%al
f0105dd0:	74 15                	je     f0105de7 <mp_init+0x1af>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0105dd2:	83 ec 0c             	sub    $0xc,%esp
f0105dd5:	68 bc 80 10 f0       	push   $0xf01080bc
f0105dda:	e8 7b d8 ff ff       	call   f010365a <cprintf>
f0105ddf:	83 c4 10             	add    $0x10,%esp
f0105de2:	e9 3b 01 00 00       	jmp    f0105f22 <mp_init+0x2ea>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f0105de7:	85 db                	test   %ebx,%ebx
f0105de9:	0f 84 33 01 00 00    	je     f0105f22 <mp_init+0x2ea>
		return;
	ismp = 1;
f0105def:	c7 05 00 d0 22 f0 01 	movl   $0x1,0xf022d000
f0105df6:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0105df9:	8b 43 24             	mov    0x24(%ebx),%eax
f0105dfc:	a3 00 e0 26 f0       	mov    %eax,0xf026e000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105e01:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f0105e04:	be 00 00 00 00       	mov    $0x0,%esi
f0105e09:	e9 85 00 00 00       	jmp    f0105e93 <mp_init+0x25b>
		switch (*p) {
f0105e0e:	0f b6 07             	movzbl (%edi),%eax
f0105e11:	84 c0                	test   %al,%al
f0105e13:	74 06                	je     f0105e1b <mp_init+0x1e3>
f0105e15:	3c 04                	cmp    $0x4,%al
f0105e17:	77 55                	ja     f0105e6e <mp_init+0x236>
f0105e19:	eb 4e                	jmp    f0105e69 <mp_init+0x231>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f0105e1b:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f0105e1f:	74 11                	je     f0105e32 <mp_init+0x1fa>
				bootcpu = &cpus[ncpu];
f0105e21:	6b 05 c4 d3 22 f0 74 	imul   $0x74,0xf022d3c4,%eax
f0105e28:	05 20 d0 22 f0       	add    $0xf022d020,%eax
f0105e2d:	a3 c0 d3 22 f0       	mov    %eax,0xf022d3c0
			if (ncpu < NCPU) {
f0105e32:	a1 c4 d3 22 f0       	mov    0xf022d3c4,%eax
f0105e37:	83 f8 07             	cmp    $0x7,%eax
f0105e3a:	7f 13                	jg     f0105e4f <mp_init+0x217>
				cpus[ncpu].cpu_id = ncpu;
f0105e3c:	6b d0 74             	imul   $0x74,%eax,%edx
f0105e3f:	88 82 20 d0 22 f0    	mov    %al,-0xfdd2fe0(%edx)
				ncpu++;
f0105e45:	83 c0 01             	add    $0x1,%eax
f0105e48:	a3 c4 d3 22 f0       	mov    %eax,0xf022d3c4
f0105e4d:	eb 15                	jmp    f0105e64 <mp_init+0x22c>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0105e4f:	83 ec 08             	sub    $0x8,%esp
f0105e52:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f0105e56:	50                   	push   %eax
f0105e57:	68 ec 80 10 f0       	push   $0xf01080ec
f0105e5c:	e8 f9 d7 ff ff       	call   f010365a <cprintf>
f0105e61:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0105e64:	83 c7 14             	add    $0x14,%edi
			continue;
f0105e67:	eb 27                	jmp    f0105e90 <mp_init+0x258>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0105e69:	83 c7 08             	add    $0x8,%edi
			continue;
f0105e6c:	eb 22                	jmp    f0105e90 <mp_init+0x258>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0105e6e:	83 ec 08             	sub    $0x8,%esp
f0105e71:	0f b6 c0             	movzbl %al,%eax
f0105e74:	50                   	push   %eax
f0105e75:	68 14 81 10 f0       	push   $0xf0108114
f0105e7a:	e8 db d7 ff ff       	call   f010365a <cprintf>
			ismp = 0;
f0105e7f:	c7 05 00 d0 22 f0 00 	movl   $0x0,0xf022d000
f0105e86:	00 00 00 
			i = conf->entry;
f0105e89:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f0105e8d:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105e90:	83 c6 01             	add    $0x1,%esi
f0105e93:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f0105e97:	39 c6                	cmp    %eax,%esi
f0105e99:	0f 82 6f ff ff ff    	jb     f0105e0e <mp_init+0x1d6>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f0105e9f:	a1 c0 d3 22 f0       	mov    0xf022d3c0,%eax
f0105ea4:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f0105eab:	83 3d 00 d0 22 f0 00 	cmpl   $0x0,0xf022d000
f0105eb2:	75 26                	jne    f0105eda <mp_init+0x2a2>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f0105eb4:	c7 05 c4 d3 22 f0 01 	movl   $0x1,0xf022d3c4
f0105ebb:	00 00 00 
		lapicaddr = 0;
f0105ebe:	c7 05 00 e0 26 f0 00 	movl   $0x0,0xf026e000
f0105ec5:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0105ec8:	83 ec 0c             	sub    $0xc,%esp
f0105ecb:	68 34 81 10 f0       	push   $0xf0108134
f0105ed0:	e8 85 d7 ff ff       	call   f010365a <cprintf>
		return;
f0105ed5:	83 c4 10             	add    $0x10,%esp
f0105ed8:	eb 48                	jmp    f0105f22 <mp_init+0x2ea>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f0105eda:	83 ec 04             	sub    $0x4,%esp
f0105edd:	ff 35 c4 d3 22 f0    	pushl  0xf022d3c4
f0105ee3:	0f b6 00             	movzbl (%eax),%eax
f0105ee6:	50                   	push   %eax
f0105ee7:	68 bb 81 10 f0       	push   $0xf01081bb
f0105eec:	e8 69 d7 ff ff       	call   f010365a <cprintf>

	if (mp->imcrp) {
f0105ef1:	83 c4 10             	add    $0x10,%esp
f0105ef4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105ef7:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0105efb:	74 25                	je     f0105f22 <mp_init+0x2ea>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0105efd:	83 ec 0c             	sub    $0xc,%esp
f0105f00:	68 60 81 10 f0       	push   $0xf0108160
f0105f05:	e8 50 d7 ff ff       	call   f010365a <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105f0a:	ba 22 00 00 00       	mov    $0x22,%edx
f0105f0f:	b8 70 00 00 00       	mov    $0x70,%eax
f0105f14:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0105f15:	ba 23 00 00 00       	mov    $0x23,%edx
f0105f1a:	ec                   	in     (%dx),%al
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105f1b:	83 c8 01             	or     $0x1,%eax
f0105f1e:	ee                   	out    %al,(%dx)
f0105f1f:	83 c4 10             	add    $0x10,%esp
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f0105f22:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105f25:	5b                   	pop    %ebx
f0105f26:	5e                   	pop    %esi
f0105f27:	5f                   	pop    %edi
f0105f28:	5d                   	pop    %ebp
f0105f29:	c3                   	ret    

f0105f2a <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f0105f2a:	55                   	push   %ebp
f0105f2b:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f0105f2d:	8b 0d 04 e0 26 f0    	mov    0xf026e004,%ecx
f0105f33:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0105f36:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f0105f38:	a1 04 e0 26 f0       	mov    0xf026e004,%eax
f0105f3d:	8b 40 20             	mov    0x20(%eax),%eax
}
f0105f40:	5d                   	pop    %ebp
f0105f41:	c3                   	ret    

f0105f42 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f0105f42:	55                   	push   %ebp
f0105f43:	89 e5                	mov    %esp,%ebp
	if (lapic)
f0105f45:	a1 04 e0 26 f0       	mov    0xf026e004,%eax
f0105f4a:	85 c0                	test   %eax,%eax
f0105f4c:	74 08                	je     f0105f56 <cpunum+0x14>
		return lapic[ID] >> 24;
f0105f4e:	8b 40 20             	mov    0x20(%eax),%eax
f0105f51:	c1 e8 18             	shr    $0x18,%eax
f0105f54:	eb 05                	jmp    f0105f5b <cpunum+0x19>
	return 0;
f0105f56:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105f5b:	5d                   	pop    %ebp
f0105f5c:	c3                   	ret    

f0105f5d <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f0105f5d:	a1 00 e0 26 f0       	mov    0xf026e000,%eax
f0105f62:	85 c0                	test   %eax,%eax
f0105f64:	0f 84 21 01 00 00    	je     f010608b <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f0105f6a:	55                   	push   %ebp
f0105f6b:	89 e5                	mov    %esp,%ebp
f0105f6d:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0105f70:	68 00 10 00 00       	push   $0x1000
f0105f75:	50                   	push   %eax
f0105f76:	e8 b9 b2 ff ff       	call   f0101234 <mmio_map_region>
f0105f7b:	a3 04 e0 26 f0       	mov    %eax,0xf026e004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105f80:	ba 27 01 00 00       	mov    $0x127,%edx
f0105f85:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0105f8a:	e8 9b ff ff ff       	call   f0105f2a <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0105f8f:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105f94:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0105f99:	e8 8c ff ff ff       	call   f0105f2a <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0105f9e:	ba 20 00 02 00       	mov    $0x20020,%edx
f0105fa3:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0105fa8:	e8 7d ff ff ff       	call   f0105f2a <lapicw>
	lapicw(TICR, 10000000); 
f0105fad:	ba 80 96 98 00       	mov    $0x989680,%edx
f0105fb2:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0105fb7:	e8 6e ff ff ff       	call   f0105f2a <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0105fbc:	e8 81 ff ff ff       	call   f0105f42 <cpunum>
f0105fc1:	6b c0 74             	imul   $0x74,%eax,%eax
f0105fc4:	05 20 d0 22 f0       	add    $0xf022d020,%eax
f0105fc9:	83 c4 10             	add    $0x10,%esp
f0105fcc:	39 05 c0 d3 22 f0    	cmp    %eax,0xf022d3c0
f0105fd2:	74 0f                	je     f0105fe3 <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f0105fd4:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105fd9:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0105fde:	e8 47 ff ff ff       	call   f0105f2a <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f0105fe3:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105fe8:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0105fed:	e8 38 ff ff ff       	call   f0105f2a <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f0105ff2:	a1 04 e0 26 f0       	mov    0xf026e004,%eax
f0105ff7:	8b 40 30             	mov    0x30(%eax),%eax
f0105ffa:	c1 e8 10             	shr    $0x10,%eax
f0105ffd:	3c 03                	cmp    $0x3,%al
f0105fff:	76 0f                	jbe    f0106010 <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f0106001:	ba 00 00 01 00       	mov    $0x10000,%edx
f0106006:	b8 d0 00 00 00       	mov    $0xd0,%eax
f010600b:	e8 1a ff ff ff       	call   f0105f2a <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0106010:	ba 33 00 00 00       	mov    $0x33,%edx
f0106015:	b8 dc 00 00 00       	mov    $0xdc,%eax
f010601a:	e8 0b ff ff ff       	call   f0105f2a <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f010601f:	ba 00 00 00 00       	mov    $0x0,%edx
f0106024:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0106029:	e8 fc fe ff ff       	call   f0105f2a <lapicw>
	lapicw(ESR, 0);
f010602e:	ba 00 00 00 00       	mov    $0x0,%edx
f0106033:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0106038:	e8 ed fe ff ff       	call   f0105f2a <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f010603d:	ba 00 00 00 00       	mov    $0x0,%edx
f0106042:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0106047:	e8 de fe ff ff       	call   f0105f2a <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f010604c:	ba 00 00 00 00       	mov    $0x0,%edx
f0106051:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0106056:	e8 cf fe ff ff       	call   f0105f2a <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f010605b:	ba 00 85 08 00       	mov    $0x88500,%edx
f0106060:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106065:	e8 c0 fe ff ff       	call   f0105f2a <lapicw>
	while(lapic[ICRLO] & DELIVS)
f010606a:	8b 15 04 e0 26 f0    	mov    0xf026e004,%edx
f0106070:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0106076:	f6 c4 10             	test   $0x10,%ah
f0106079:	75 f5                	jne    f0106070 <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f010607b:	ba 00 00 00 00       	mov    $0x0,%edx
f0106080:	b8 20 00 00 00       	mov    $0x20,%eax
f0106085:	e8 a0 fe ff ff       	call   f0105f2a <lapicw>
}
f010608a:	c9                   	leave  
f010608b:	f3 c3                	repz ret 

f010608d <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f010608d:	83 3d 04 e0 26 f0 00 	cmpl   $0x0,0xf026e004
f0106094:	74 13                	je     f01060a9 <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f0106096:	55                   	push   %ebp
f0106097:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f0106099:	ba 00 00 00 00       	mov    $0x0,%edx
f010609e:	b8 2c 00 00 00       	mov    $0x2c,%eax
f01060a3:	e8 82 fe ff ff       	call   f0105f2a <lapicw>
}
f01060a8:	5d                   	pop    %ebp
f01060a9:	f3 c3                	repz ret 

f01060ab <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f01060ab:	55                   	push   %ebp
f01060ac:	89 e5                	mov    %esp,%ebp
f01060ae:	56                   	push   %esi
f01060af:	53                   	push   %ebx
f01060b0:	8b 75 08             	mov    0x8(%ebp),%esi
f01060b3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01060b6:	ba 70 00 00 00       	mov    $0x70,%edx
f01060bb:	b8 0f 00 00 00       	mov    $0xf,%eax
f01060c0:	ee                   	out    %al,(%dx)
f01060c1:	ba 71 00 00 00       	mov    $0x71,%edx
f01060c6:	b8 0a 00 00 00       	mov    $0xa,%eax
f01060cb:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01060cc:	83 3d 88 ce 22 f0 00 	cmpl   $0x0,0xf022ce88
f01060d3:	75 19                	jne    f01060ee <lapic_startap+0x43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01060d5:	68 67 04 00 00       	push   $0x467
f01060da:	68 04 66 10 f0       	push   $0xf0106604
f01060df:	68 98 00 00 00       	push   $0x98
f01060e4:	68 d8 81 10 f0       	push   $0xf01081d8
f01060e9:	e8 52 9f ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f01060ee:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f01060f5:	00 00 
	wrv[1] = addr >> 4;
f01060f7:	89 d8                	mov    %ebx,%eax
f01060f9:	c1 e8 04             	shr    $0x4,%eax
f01060fc:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0106102:	c1 e6 18             	shl    $0x18,%esi
f0106105:	89 f2                	mov    %esi,%edx
f0106107:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010610c:	e8 19 fe ff ff       	call   f0105f2a <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0106111:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0106116:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010611b:	e8 0a fe ff ff       	call   f0105f2a <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0106120:	ba 00 85 00 00       	mov    $0x8500,%edx
f0106125:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010612a:	e8 fb fd ff ff       	call   f0105f2a <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f010612f:	c1 eb 0c             	shr    $0xc,%ebx
f0106132:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0106135:	89 f2                	mov    %esi,%edx
f0106137:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010613c:	e8 e9 fd ff ff       	call   f0105f2a <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0106141:	89 da                	mov    %ebx,%edx
f0106143:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106148:	e8 dd fd ff ff       	call   f0105f2a <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f010614d:	89 f2                	mov    %esi,%edx
f010614f:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0106154:	e8 d1 fd ff ff       	call   f0105f2a <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0106159:	89 da                	mov    %ebx,%edx
f010615b:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106160:	e8 c5 fd ff ff       	call   f0105f2a <lapicw>
		microdelay(200);
	}
}
f0106165:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0106168:	5b                   	pop    %ebx
f0106169:	5e                   	pop    %esi
f010616a:	5d                   	pop    %ebp
f010616b:	c3                   	ret    

f010616c <lapic_ipi>:

void
lapic_ipi(int vector)
{
f010616c:	55                   	push   %ebp
f010616d:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f010616f:	8b 55 08             	mov    0x8(%ebp),%edx
f0106172:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0106178:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010617d:	e8 a8 fd ff ff       	call   f0105f2a <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0106182:	8b 15 04 e0 26 f0    	mov    0xf026e004,%edx
f0106188:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f010618e:	f6 c4 10             	test   $0x10,%ah
f0106191:	75 f5                	jne    f0106188 <lapic_ipi+0x1c>
		;
}
f0106193:	5d                   	pop    %ebp
f0106194:	c3                   	ret    

f0106195 <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0106195:	55                   	push   %ebp
f0106196:	89 e5                	mov    %esp,%ebp
f0106198:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f010619b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f01061a1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01061a4:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f01061a7:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f01061ae:	5d                   	pop    %ebp
f01061af:	c3                   	ret    

f01061b0 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f01061b0:	55                   	push   %ebp
f01061b1:	89 e5                	mov    %esp,%ebp
f01061b3:	56                   	push   %esi
f01061b4:	53                   	push   %ebx
f01061b5:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f01061b8:	83 3b 00             	cmpl   $0x0,(%ebx)
f01061bb:	74 14                	je     f01061d1 <spin_lock+0x21>
f01061bd:	8b 73 08             	mov    0x8(%ebx),%esi
f01061c0:	e8 7d fd ff ff       	call   f0105f42 <cpunum>
f01061c5:	6b c0 74             	imul   $0x74,%eax,%eax
f01061c8:	05 20 d0 22 f0       	add    $0xf022d020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f01061cd:	39 c6                	cmp    %eax,%esi
f01061cf:	74 07                	je     f01061d8 <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f01061d1:	ba 01 00 00 00       	mov    $0x1,%edx
f01061d6:	eb 20                	jmp    f01061f8 <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f01061d8:	8b 5b 04             	mov    0x4(%ebx),%ebx
f01061db:	e8 62 fd ff ff       	call   f0105f42 <cpunum>
f01061e0:	83 ec 0c             	sub    $0xc,%esp
f01061e3:	53                   	push   %ebx
f01061e4:	50                   	push   %eax
f01061e5:	68 e8 81 10 f0       	push   $0xf01081e8
f01061ea:	6a 41                	push   $0x41
f01061ec:	68 4c 82 10 f0       	push   $0xf010824c
f01061f1:	e8 4a 9e ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f01061f6:	f3 90                	pause  
f01061f8:	89 d0                	mov    %edx,%eax
f01061fa:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f01061fd:	85 c0                	test   %eax,%eax
f01061ff:	75 f5                	jne    f01061f6 <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0106201:	e8 3c fd ff ff       	call   f0105f42 <cpunum>
f0106206:	6b c0 74             	imul   $0x74,%eax,%eax
f0106209:	05 20 d0 22 f0       	add    $0xf022d020,%eax
f010620e:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0106211:	83 c3 0c             	add    $0xc,%ebx

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0106214:	89 ea                	mov    %ebp,%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0106216:	b8 00 00 00 00       	mov    $0x0,%eax
f010621b:	eb 0b                	jmp    f0106228 <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f010621d:	8b 4a 04             	mov    0x4(%edx),%ecx
f0106220:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0106223:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0106225:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0106228:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f010622e:	76 11                	jbe    f0106241 <spin_lock+0x91>
f0106230:	83 f8 09             	cmp    $0x9,%eax
f0106233:	7e e8                	jle    f010621d <spin_lock+0x6d>
f0106235:	eb 0a                	jmp    f0106241 <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f0106237:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f010623e:	83 c0 01             	add    $0x1,%eax
f0106241:	83 f8 09             	cmp    $0x9,%eax
f0106244:	7e f1                	jle    f0106237 <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f0106246:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0106249:	5b                   	pop    %ebx
f010624a:	5e                   	pop    %esi
f010624b:	5d                   	pop    %ebp
f010624c:	c3                   	ret    

f010624d <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f010624d:	55                   	push   %ebp
f010624e:	89 e5                	mov    %esp,%ebp
f0106250:	57                   	push   %edi
f0106251:	56                   	push   %esi
f0106252:	53                   	push   %ebx
f0106253:	83 ec 4c             	sub    $0x4c,%esp
f0106256:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0106259:	83 3e 00             	cmpl   $0x0,(%esi)
f010625c:	74 18                	je     f0106276 <spin_unlock+0x29>
f010625e:	8b 5e 08             	mov    0x8(%esi),%ebx
f0106261:	e8 dc fc ff ff       	call   f0105f42 <cpunum>
f0106266:	6b c0 74             	imul   $0x74,%eax,%eax
f0106269:	05 20 d0 22 f0       	add    $0xf022d020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f010626e:	39 c3                	cmp    %eax,%ebx
f0106270:	0f 84 a5 00 00 00    	je     f010631b <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0106276:	83 ec 04             	sub    $0x4,%esp
f0106279:	6a 28                	push   $0x28
f010627b:	8d 46 0c             	lea    0xc(%esi),%eax
f010627e:	50                   	push   %eax
f010627f:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0106282:	53                   	push   %ebx
f0106283:	e8 e5 f6 ff ff       	call   f010596d <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0106288:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f010628b:	0f b6 38             	movzbl (%eax),%edi
f010628e:	8b 76 04             	mov    0x4(%esi),%esi
f0106291:	e8 ac fc ff ff       	call   f0105f42 <cpunum>
f0106296:	57                   	push   %edi
f0106297:	56                   	push   %esi
f0106298:	50                   	push   %eax
f0106299:	68 14 82 10 f0       	push   $0xf0108214
f010629e:	e8 b7 d3 ff ff       	call   f010365a <cprintf>
f01062a3:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f01062a6:	8d 7d a8             	lea    -0x58(%ebp),%edi
f01062a9:	eb 54                	jmp    f01062ff <spin_unlock+0xb2>
f01062ab:	83 ec 08             	sub    $0x8,%esp
f01062ae:	57                   	push   %edi
f01062af:	50                   	push   %eax
f01062b0:	e8 f7 eb ff ff       	call   f0104eac <debuginfo_eip>
f01062b5:	83 c4 10             	add    $0x10,%esp
f01062b8:	85 c0                	test   %eax,%eax
f01062ba:	78 27                	js     f01062e3 <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f01062bc:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f01062be:	83 ec 04             	sub    $0x4,%esp
f01062c1:	89 c2                	mov    %eax,%edx
f01062c3:	2b 55 b8             	sub    -0x48(%ebp),%edx
f01062c6:	52                   	push   %edx
f01062c7:	ff 75 b0             	pushl  -0x50(%ebp)
f01062ca:	ff 75 b4             	pushl  -0x4c(%ebp)
f01062cd:	ff 75 ac             	pushl  -0x54(%ebp)
f01062d0:	ff 75 a8             	pushl  -0x58(%ebp)
f01062d3:	50                   	push   %eax
f01062d4:	68 5c 82 10 f0       	push   $0xf010825c
f01062d9:	e8 7c d3 ff ff       	call   f010365a <cprintf>
f01062de:	83 c4 20             	add    $0x20,%esp
f01062e1:	eb 12                	jmp    f01062f5 <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f01062e3:	83 ec 08             	sub    $0x8,%esp
f01062e6:	ff 36                	pushl  (%esi)
f01062e8:	68 73 82 10 f0       	push   $0xf0108273
f01062ed:	e8 68 d3 ff ff       	call   f010365a <cprintf>
f01062f2:	83 c4 10             	add    $0x10,%esp
f01062f5:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f01062f8:	8d 45 e8             	lea    -0x18(%ebp),%eax
f01062fb:	39 c3                	cmp    %eax,%ebx
f01062fd:	74 08                	je     f0106307 <spin_unlock+0xba>
f01062ff:	89 de                	mov    %ebx,%esi
f0106301:	8b 03                	mov    (%ebx),%eax
f0106303:	85 c0                	test   %eax,%eax
f0106305:	75 a4                	jne    f01062ab <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f0106307:	83 ec 04             	sub    $0x4,%esp
f010630a:	68 7b 82 10 f0       	push   $0xf010827b
f010630f:	6a 67                	push   $0x67
f0106311:	68 4c 82 10 f0       	push   $0xf010824c
f0106316:	e8 25 9d ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f010631b:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0106322:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0106329:	b8 00 00 00 00       	mov    $0x0,%eax
f010632e:	f0 87 06             	lock xchg %eax,(%esi)
	// respect to any other instruction which references the same memory.
	// x86 CPUs will not reorder loads/stores across locked instructions
	// (vol 3, 8.2.2). Because xchg() is implemented using asm volatile,
	// gcc will not reorder C statements across the xchg.
	xchg(&lk->locked, 0);
}
f0106331:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0106334:	5b                   	pop    %ebx
f0106335:	5e                   	pop    %esi
f0106336:	5f                   	pop    %edi
f0106337:	5d                   	pop    %ebp
f0106338:	c3                   	ret    
f0106339:	66 90                	xchg   %ax,%ax
f010633b:	66 90                	xchg   %ax,%ax
f010633d:	66 90                	xchg   %ax,%ax
f010633f:	90                   	nop

f0106340 <__udivdi3>:
f0106340:	55                   	push   %ebp
f0106341:	57                   	push   %edi
f0106342:	56                   	push   %esi
f0106343:	53                   	push   %ebx
f0106344:	83 ec 1c             	sub    $0x1c,%esp
f0106347:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010634b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010634f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0106353:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0106357:	85 f6                	test   %esi,%esi
f0106359:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010635d:	89 ca                	mov    %ecx,%edx
f010635f:	89 f8                	mov    %edi,%eax
f0106361:	75 3d                	jne    f01063a0 <__udivdi3+0x60>
f0106363:	39 cf                	cmp    %ecx,%edi
f0106365:	0f 87 c5 00 00 00    	ja     f0106430 <__udivdi3+0xf0>
f010636b:	85 ff                	test   %edi,%edi
f010636d:	89 fd                	mov    %edi,%ebp
f010636f:	75 0b                	jne    f010637c <__udivdi3+0x3c>
f0106371:	b8 01 00 00 00       	mov    $0x1,%eax
f0106376:	31 d2                	xor    %edx,%edx
f0106378:	f7 f7                	div    %edi
f010637a:	89 c5                	mov    %eax,%ebp
f010637c:	89 c8                	mov    %ecx,%eax
f010637e:	31 d2                	xor    %edx,%edx
f0106380:	f7 f5                	div    %ebp
f0106382:	89 c1                	mov    %eax,%ecx
f0106384:	89 d8                	mov    %ebx,%eax
f0106386:	89 cf                	mov    %ecx,%edi
f0106388:	f7 f5                	div    %ebp
f010638a:	89 c3                	mov    %eax,%ebx
f010638c:	89 d8                	mov    %ebx,%eax
f010638e:	89 fa                	mov    %edi,%edx
f0106390:	83 c4 1c             	add    $0x1c,%esp
f0106393:	5b                   	pop    %ebx
f0106394:	5e                   	pop    %esi
f0106395:	5f                   	pop    %edi
f0106396:	5d                   	pop    %ebp
f0106397:	c3                   	ret    
f0106398:	90                   	nop
f0106399:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01063a0:	39 ce                	cmp    %ecx,%esi
f01063a2:	77 74                	ja     f0106418 <__udivdi3+0xd8>
f01063a4:	0f bd fe             	bsr    %esi,%edi
f01063a7:	83 f7 1f             	xor    $0x1f,%edi
f01063aa:	0f 84 98 00 00 00    	je     f0106448 <__udivdi3+0x108>
f01063b0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01063b5:	89 f9                	mov    %edi,%ecx
f01063b7:	89 c5                	mov    %eax,%ebp
f01063b9:	29 fb                	sub    %edi,%ebx
f01063bb:	d3 e6                	shl    %cl,%esi
f01063bd:	89 d9                	mov    %ebx,%ecx
f01063bf:	d3 ed                	shr    %cl,%ebp
f01063c1:	89 f9                	mov    %edi,%ecx
f01063c3:	d3 e0                	shl    %cl,%eax
f01063c5:	09 ee                	or     %ebp,%esi
f01063c7:	89 d9                	mov    %ebx,%ecx
f01063c9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01063cd:	89 d5                	mov    %edx,%ebp
f01063cf:	8b 44 24 08          	mov    0x8(%esp),%eax
f01063d3:	d3 ed                	shr    %cl,%ebp
f01063d5:	89 f9                	mov    %edi,%ecx
f01063d7:	d3 e2                	shl    %cl,%edx
f01063d9:	89 d9                	mov    %ebx,%ecx
f01063db:	d3 e8                	shr    %cl,%eax
f01063dd:	09 c2                	or     %eax,%edx
f01063df:	89 d0                	mov    %edx,%eax
f01063e1:	89 ea                	mov    %ebp,%edx
f01063e3:	f7 f6                	div    %esi
f01063e5:	89 d5                	mov    %edx,%ebp
f01063e7:	89 c3                	mov    %eax,%ebx
f01063e9:	f7 64 24 0c          	mull   0xc(%esp)
f01063ed:	39 d5                	cmp    %edx,%ebp
f01063ef:	72 10                	jb     f0106401 <__udivdi3+0xc1>
f01063f1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01063f5:	89 f9                	mov    %edi,%ecx
f01063f7:	d3 e6                	shl    %cl,%esi
f01063f9:	39 c6                	cmp    %eax,%esi
f01063fb:	73 07                	jae    f0106404 <__udivdi3+0xc4>
f01063fd:	39 d5                	cmp    %edx,%ebp
f01063ff:	75 03                	jne    f0106404 <__udivdi3+0xc4>
f0106401:	83 eb 01             	sub    $0x1,%ebx
f0106404:	31 ff                	xor    %edi,%edi
f0106406:	89 d8                	mov    %ebx,%eax
f0106408:	89 fa                	mov    %edi,%edx
f010640a:	83 c4 1c             	add    $0x1c,%esp
f010640d:	5b                   	pop    %ebx
f010640e:	5e                   	pop    %esi
f010640f:	5f                   	pop    %edi
f0106410:	5d                   	pop    %ebp
f0106411:	c3                   	ret    
f0106412:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0106418:	31 ff                	xor    %edi,%edi
f010641a:	31 db                	xor    %ebx,%ebx
f010641c:	89 d8                	mov    %ebx,%eax
f010641e:	89 fa                	mov    %edi,%edx
f0106420:	83 c4 1c             	add    $0x1c,%esp
f0106423:	5b                   	pop    %ebx
f0106424:	5e                   	pop    %esi
f0106425:	5f                   	pop    %edi
f0106426:	5d                   	pop    %ebp
f0106427:	c3                   	ret    
f0106428:	90                   	nop
f0106429:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106430:	89 d8                	mov    %ebx,%eax
f0106432:	f7 f7                	div    %edi
f0106434:	31 ff                	xor    %edi,%edi
f0106436:	89 c3                	mov    %eax,%ebx
f0106438:	89 d8                	mov    %ebx,%eax
f010643a:	89 fa                	mov    %edi,%edx
f010643c:	83 c4 1c             	add    $0x1c,%esp
f010643f:	5b                   	pop    %ebx
f0106440:	5e                   	pop    %esi
f0106441:	5f                   	pop    %edi
f0106442:	5d                   	pop    %ebp
f0106443:	c3                   	ret    
f0106444:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106448:	39 ce                	cmp    %ecx,%esi
f010644a:	72 0c                	jb     f0106458 <__udivdi3+0x118>
f010644c:	31 db                	xor    %ebx,%ebx
f010644e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0106452:	0f 87 34 ff ff ff    	ja     f010638c <__udivdi3+0x4c>
f0106458:	bb 01 00 00 00       	mov    $0x1,%ebx
f010645d:	e9 2a ff ff ff       	jmp    f010638c <__udivdi3+0x4c>
f0106462:	66 90                	xchg   %ax,%ax
f0106464:	66 90                	xchg   %ax,%ax
f0106466:	66 90                	xchg   %ax,%ax
f0106468:	66 90                	xchg   %ax,%ax
f010646a:	66 90                	xchg   %ax,%ax
f010646c:	66 90                	xchg   %ax,%ax
f010646e:	66 90                	xchg   %ax,%ax

f0106470 <__umoddi3>:
f0106470:	55                   	push   %ebp
f0106471:	57                   	push   %edi
f0106472:	56                   	push   %esi
f0106473:	53                   	push   %ebx
f0106474:	83 ec 1c             	sub    $0x1c,%esp
f0106477:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010647b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010647f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0106483:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0106487:	85 d2                	test   %edx,%edx
f0106489:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010648d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0106491:	89 f3                	mov    %esi,%ebx
f0106493:	89 3c 24             	mov    %edi,(%esp)
f0106496:	89 74 24 04          	mov    %esi,0x4(%esp)
f010649a:	75 1c                	jne    f01064b8 <__umoddi3+0x48>
f010649c:	39 f7                	cmp    %esi,%edi
f010649e:	76 50                	jbe    f01064f0 <__umoddi3+0x80>
f01064a0:	89 c8                	mov    %ecx,%eax
f01064a2:	89 f2                	mov    %esi,%edx
f01064a4:	f7 f7                	div    %edi
f01064a6:	89 d0                	mov    %edx,%eax
f01064a8:	31 d2                	xor    %edx,%edx
f01064aa:	83 c4 1c             	add    $0x1c,%esp
f01064ad:	5b                   	pop    %ebx
f01064ae:	5e                   	pop    %esi
f01064af:	5f                   	pop    %edi
f01064b0:	5d                   	pop    %ebp
f01064b1:	c3                   	ret    
f01064b2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01064b8:	39 f2                	cmp    %esi,%edx
f01064ba:	89 d0                	mov    %edx,%eax
f01064bc:	77 52                	ja     f0106510 <__umoddi3+0xa0>
f01064be:	0f bd ea             	bsr    %edx,%ebp
f01064c1:	83 f5 1f             	xor    $0x1f,%ebp
f01064c4:	75 5a                	jne    f0106520 <__umoddi3+0xb0>
f01064c6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01064ca:	0f 82 e0 00 00 00    	jb     f01065b0 <__umoddi3+0x140>
f01064d0:	39 0c 24             	cmp    %ecx,(%esp)
f01064d3:	0f 86 d7 00 00 00    	jbe    f01065b0 <__umoddi3+0x140>
f01064d9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01064dd:	8b 54 24 04          	mov    0x4(%esp),%edx
f01064e1:	83 c4 1c             	add    $0x1c,%esp
f01064e4:	5b                   	pop    %ebx
f01064e5:	5e                   	pop    %esi
f01064e6:	5f                   	pop    %edi
f01064e7:	5d                   	pop    %ebp
f01064e8:	c3                   	ret    
f01064e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01064f0:	85 ff                	test   %edi,%edi
f01064f2:	89 fd                	mov    %edi,%ebp
f01064f4:	75 0b                	jne    f0106501 <__umoddi3+0x91>
f01064f6:	b8 01 00 00 00       	mov    $0x1,%eax
f01064fb:	31 d2                	xor    %edx,%edx
f01064fd:	f7 f7                	div    %edi
f01064ff:	89 c5                	mov    %eax,%ebp
f0106501:	89 f0                	mov    %esi,%eax
f0106503:	31 d2                	xor    %edx,%edx
f0106505:	f7 f5                	div    %ebp
f0106507:	89 c8                	mov    %ecx,%eax
f0106509:	f7 f5                	div    %ebp
f010650b:	89 d0                	mov    %edx,%eax
f010650d:	eb 99                	jmp    f01064a8 <__umoddi3+0x38>
f010650f:	90                   	nop
f0106510:	89 c8                	mov    %ecx,%eax
f0106512:	89 f2                	mov    %esi,%edx
f0106514:	83 c4 1c             	add    $0x1c,%esp
f0106517:	5b                   	pop    %ebx
f0106518:	5e                   	pop    %esi
f0106519:	5f                   	pop    %edi
f010651a:	5d                   	pop    %ebp
f010651b:	c3                   	ret    
f010651c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106520:	8b 34 24             	mov    (%esp),%esi
f0106523:	bf 20 00 00 00       	mov    $0x20,%edi
f0106528:	89 e9                	mov    %ebp,%ecx
f010652a:	29 ef                	sub    %ebp,%edi
f010652c:	d3 e0                	shl    %cl,%eax
f010652e:	89 f9                	mov    %edi,%ecx
f0106530:	89 f2                	mov    %esi,%edx
f0106532:	d3 ea                	shr    %cl,%edx
f0106534:	89 e9                	mov    %ebp,%ecx
f0106536:	09 c2                	or     %eax,%edx
f0106538:	89 d8                	mov    %ebx,%eax
f010653a:	89 14 24             	mov    %edx,(%esp)
f010653d:	89 f2                	mov    %esi,%edx
f010653f:	d3 e2                	shl    %cl,%edx
f0106541:	89 f9                	mov    %edi,%ecx
f0106543:	89 54 24 04          	mov    %edx,0x4(%esp)
f0106547:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010654b:	d3 e8                	shr    %cl,%eax
f010654d:	89 e9                	mov    %ebp,%ecx
f010654f:	89 c6                	mov    %eax,%esi
f0106551:	d3 e3                	shl    %cl,%ebx
f0106553:	89 f9                	mov    %edi,%ecx
f0106555:	89 d0                	mov    %edx,%eax
f0106557:	d3 e8                	shr    %cl,%eax
f0106559:	89 e9                	mov    %ebp,%ecx
f010655b:	09 d8                	or     %ebx,%eax
f010655d:	89 d3                	mov    %edx,%ebx
f010655f:	89 f2                	mov    %esi,%edx
f0106561:	f7 34 24             	divl   (%esp)
f0106564:	89 d6                	mov    %edx,%esi
f0106566:	d3 e3                	shl    %cl,%ebx
f0106568:	f7 64 24 04          	mull   0x4(%esp)
f010656c:	39 d6                	cmp    %edx,%esi
f010656e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0106572:	89 d1                	mov    %edx,%ecx
f0106574:	89 c3                	mov    %eax,%ebx
f0106576:	72 08                	jb     f0106580 <__umoddi3+0x110>
f0106578:	75 11                	jne    f010658b <__umoddi3+0x11b>
f010657a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010657e:	73 0b                	jae    f010658b <__umoddi3+0x11b>
f0106580:	2b 44 24 04          	sub    0x4(%esp),%eax
f0106584:	1b 14 24             	sbb    (%esp),%edx
f0106587:	89 d1                	mov    %edx,%ecx
f0106589:	89 c3                	mov    %eax,%ebx
f010658b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010658f:	29 da                	sub    %ebx,%edx
f0106591:	19 ce                	sbb    %ecx,%esi
f0106593:	89 f9                	mov    %edi,%ecx
f0106595:	89 f0                	mov    %esi,%eax
f0106597:	d3 e0                	shl    %cl,%eax
f0106599:	89 e9                	mov    %ebp,%ecx
f010659b:	d3 ea                	shr    %cl,%edx
f010659d:	89 e9                	mov    %ebp,%ecx
f010659f:	d3 ee                	shr    %cl,%esi
f01065a1:	09 d0                	or     %edx,%eax
f01065a3:	89 f2                	mov    %esi,%edx
f01065a5:	83 c4 1c             	add    $0x1c,%esp
f01065a8:	5b                   	pop    %ebx
f01065a9:	5e                   	pop    %esi
f01065aa:	5f                   	pop    %edi
f01065ab:	5d                   	pop    %ebp
f01065ac:	c3                   	ret    
f01065ad:	8d 76 00             	lea    0x0(%esi),%esi
f01065b0:	29 f9                	sub    %edi,%ecx
f01065b2:	19 d6                	sbb    %edx,%esi
f01065b4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01065b8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01065bc:	e9 18 ff ff ff       	jmp    f01064d9 <__umoddi3+0x69>
