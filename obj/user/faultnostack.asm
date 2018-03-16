
obj/user/faultnostack:     file format elf32-i386


Disassembly of section .text:

00800020 <_start>:
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	cmpl $USTACKTOP, %esp
  800020:	81 fc 00 e0 bf ee    	cmp    $0xeebfe000,%esp
	jne args_exist
  800026:	75 04                	jne    80002c <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
  800028:	6a 00                	push   $0x0
	pushl $0
  80002a:	6a 00                	push   $0x0

0080002c <args_exist>:

args_exist:
	call libmain
  80002c:	e8 23 00 00 00       	call   800054 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

void _pgfault_upcall();

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 10             	sub    $0x10,%esp
	sys_env_set_pgfault_upcall(0, (void*) _pgfault_upcall);
  800039:	68 17 03 80 00       	push   $0x800317
  80003e:	6a 00                	push   $0x0
  800040:	e8 2c 02 00 00       	call   800271 <sys_env_set_pgfault_upcall>
	*(int*)0 = 0;
  800045:	c7 05 00 00 00 00 00 	movl   $0x0,0x0
  80004c:	00 00 00 
}
  80004f:	83 c4 10             	add    $0x10,%esp
  800052:	c9                   	leave  
  800053:	c3                   	ret    

00800054 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800054:	55                   	push   %ebp
  800055:	89 e5                	mov    %esp,%ebp
  800057:	56                   	push   %esi
  800058:	53                   	push   %ebx
  800059:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80005c:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t envid = sys_getenvid();
  80005f:	e8 c6 00 00 00       	call   80012a <sys_getenvid>
	thisenv = &envs[ENVX(envid)];
  800064:	25 ff 03 00 00       	and    $0x3ff,%eax
  800069:	6b c0 7c             	imul   $0x7c,%eax,%eax
  80006c:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800071:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800076:	85 db                	test   %ebx,%ebx
  800078:	7e 07                	jle    800081 <libmain+0x2d>
		binaryname = argv[0];
  80007a:	8b 06                	mov    (%esi),%eax
  80007c:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800081:	83 ec 08             	sub    $0x8,%esp
  800084:	56                   	push   %esi
  800085:	53                   	push   %ebx
  800086:	e8 a8 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80008b:	e8 0a 00 00 00       	call   80009a <exit>
}
  800090:	83 c4 10             	add    $0x10,%esp
  800093:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800096:	5b                   	pop    %ebx
  800097:	5e                   	pop    %esi
  800098:	5d                   	pop    %ebp
  800099:	c3                   	ret    

0080009a <exit>:

#include <inc/lib.h>

void
exit(void)
{
  80009a:	55                   	push   %ebp
  80009b:	89 e5                	mov    %esp,%ebp
  80009d:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  8000a0:	6a 00                	push   $0x0
  8000a2:	e8 42 00 00 00       	call   8000e9 <sys_env_destroy>
}
  8000a7:	83 c4 10             	add    $0x10,%esp
  8000aa:	c9                   	leave  
  8000ab:	c3                   	ret    

008000ac <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  8000ac:	55                   	push   %ebp
  8000ad:	89 e5                	mov    %esp,%ebp
  8000af:	57                   	push   %edi
  8000b0:	56                   	push   %esi
  8000b1:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000b2:	b8 00 00 00 00       	mov    $0x0,%eax
  8000b7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000ba:	8b 55 08             	mov    0x8(%ebp),%edx
  8000bd:	89 c3                	mov    %eax,%ebx
  8000bf:	89 c7                	mov    %eax,%edi
  8000c1:	89 c6                	mov    %eax,%esi
  8000c3:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000c5:	5b                   	pop    %ebx
  8000c6:	5e                   	pop    %esi
  8000c7:	5f                   	pop    %edi
  8000c8:	5d                   	pop    %ebp
  8000c9:	c3                   	ret    

008000ca <sys_cgetc>:

int
sys_cgetc(void)
{
  8000ca:	55                   	push   %ebp
  8000cb:	89 e5                	mov    %esp,%ebp
  8000cd:	57                   	push   %edi
  8000ce:	56                   	push   %esi
  8000cf:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000d0:	ba 00 00 00 00       	mov    $0x0,%edx
  8000d5:	b8 01 00 00 00       	mov    $0x1,%eax
  8000da:	89 d1                	mov    %edx,%ecx
  8000dc:	89 d3                	mov    %edx,%ebx
  8000de:	89 d7                	mov    %edx,%edi
  8000e0:	89 d6                	mov    %edx,%esi
  8000e2:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000e4:	5b                   	pop    %ebx
  8000e5:	5e                   	pop    %esi
  8000e6:	5f                   	pop    %edi
  8000e7:	5d                   	pop    %ebp
  8000e8:	c3                   	ret    

008000e9 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000e9:	55                   	push   %ebp
  8000ea:	89 e5                	mov    %esp,%ebp
  8000ec:	57                   	push   %edi
  8000ed:	56                   	push   %esi
  8000ee:	53                   	push   %ebx
  8000ef:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000f2:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000f7:	b8 03 00 00 00       	mov    $0x3,%eax
  8000fc:	8b 55 08             	mov    0x8(%ebp),%edx
  8000ff:	89 cb                	mov    %ecx,%ebx
  800101:	89 cf                	mov    %ecx,%edi
  800103:	89 ce                	mov    %ecx,%esi
  800105:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800107:	85 c0                	test   %eax,%eax
  800109:	7e 17                	jle    800122 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  80010b:	83 ec 0c             	sub    $0xc,%esp
  80010e:	50                   	push   %eax
  80010f:	6a 03                	push   $0x3
  800111:	68 ea 0f 80 00       	push   $0x800fea
  800116:	6a 23                	push   $0x23
  800118:	68 07 10 80 00       	push   $0x801007
  80011d:	e8 1b 02 00 00       	call   80033d <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800122:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800125:	5b                   	pop    %ebx
  800126:	5e                   	pop    %esi
  800127:	5f                   	pop    %edi
  800128:	5d                   	pop    %ebp
  800129:	c3                   	ret    

0080012a <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  80012a:	55                   	push   %ebp
  80012b:	89 e5                	mov    %esp,%ebp
  80012d:	57                   	push   %edi
  80012e:	56                   	push   %esi
  80012f:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800130:	ba 00 00 00 00       	mov    $0x0,%edx
  800135:	b8 02 00 00 00       	mov    $0x2,%eax
  80013a:	89 d1                	mov    %edx,%ecx
  80013c:	89 d3                	mov    %edx,%ebx
  80013e:	89 d7                	mov    %edx,%edi
  800140:	89 d6                	mov    %edx,%esi
  800142:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800144:	5b                   	pop    %ebx
  800145:	5e                   	pop    %esi
  800146:	5f                   	pop    %edi
  800147:	5d                   	pop    %ebp
  800148:	c3                   	ret    

00800149 <sys_yield>:

void
sys_yield(void)
{
  800149:	55                   	push   %ebp
  80014a:	89 e5                	mov    %esp,%ebp
  80014c:	57                   	push   %edi
  80014d:	56                   	push   %esi
  80014e:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80014f:	ba 00 00 00 00       	mov    $0x0,%edx
  800154:	b8 0a 00 00 00       	mov    $0xa,%eax
  800159:	89 d1                	mov    %edx,%ecx
  80015b:	89 d3                	mov    %edx,%ebx
  80015d:	89 d7                	mov    %edx,%edi
  80015f:	89 d6                	mov    %edx,%esi
  800161:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800163:	5b                   	pop    %ebx
  800164:	5e                   	pop    %esi
  800165:	5f                   	pop    %edi
  800166:	5d                   	pop    %ebp
  800167:	c3                   	ret    

00800168 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800168:	55                   	push   %ebp
  800169:	89 e5                	mov    %esp,%ebp
  80016b:	57                   	push   %edi
  80016c:	56                   	push   %esi
  80016d:	53                   	push   %ebx
  80016e:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800171:	be 00 00 00 00       	mov    $0x0,%esi
  800176:	b8 04 00 00 00       	mov    $0x4,%eax
  80017b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80017e:	8b 55 08             	mov    0x8(%ebp),%edx
  800181:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800184:	89 f7                	mov    %esi,%edi
  800186:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800188:	85 c0                	test   %eax,%eax
  80018a:	7e 17                	jle    8001a3 <sys_page_alloc+0x3b>
		panic("syscall %d returned %d (> 0)", num, ret);
  80018c:	83 ec 0c             	sub    $0xc,%esp
  80018f:	50                   	push   %eax
  800190:	6a 04                	push   $0x4
  800192:	68 ea 0f 80 00       	push   $0x800fea
  800197:	6a 23                	push   $0x23
  800199:	68 07 10 80 00       	push   $0x801007
  80019e:	e8 9a 01 00 00       	call   80033d <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  8001a3:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8001a6:	5b                   	pop    %ebx
  8001a7:	5e                   	pop    %esi
  8001a8:	5f                   	pop    %edi
  8001a9:	5d                   	pop    %ebp
  8001aa:	c3                   	ret    

008001ab <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  8001ab:	55                   	push   %ebp
  8001ac:	89 e5                	mov    %esp,%ebp
  8001ae:	57                   	push   %edi
  8001af:	56                   	push   %esi
  8001b0:	53                   	push   %ebx
  8001b1:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8001b4:	b8 05 00 00 00       	mov    $0x5,%eax
  8001b9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8001bc:	8b 55 08             	mov    0x8(%ebp),%edx
  8001bf:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8001c2:	8b 7d 14             	mov    0x14(%ebp),%edi
  8001c5:	8b 75 18             	mov    0x18(%ebp),%esi
  8001c8:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8001ca:	85 c0                	test   %eax,%eax
  8001cc:	7e 17                	jle    8001e5 <sys_page_map+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  8001ce:	83 ec 0c             	sub    $0xc,%esp
  8001d1:	50                   	push   %eax
  8001d2:	6a 05                	push   $0x5
  8001d4:	68 ea 0f 80 00       	push   $0x800fea
  8001d9:	6a 23                	push   $0x23
  8001db:	68 07 10 80 00       	push   $0x801007
  8001e0:	e8 58 01 00 00       	call   80033d <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  8001e5:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8001e8:	5b                   	pop    %ebx
  8001e9:	5e                   	pop    %esi
  8001ea:	5f                   	pop    %edi
  8001eb:	5d                   	pop    %ebp
  8001ec:	c3                   	ret    

008001ed <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  8001ed:	55                   	push   %ebp
  8001ee:	89 e5                	mov    %esp,%ebp
  8001f0:	57                   	push   %edi
  8001f1:	56                   	push   %esi
  8001f2:	53                   	push   %ebx
  8001f3:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8001f6:	bb 00 00 00 00       	mov    $0x0,%ebx
  8001fb:	b8 06 00 00 00       	mov    $0x6,%eax
  800200:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800203:	8b 55 08             	mov    0x8(%ebp),%edx
  800206:	89 df                	mov    %ebx,%edi
  800208:	89 de                	mov    %ebx,%esi
  80020a:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  80020c:	85 c0                	test   %eax,%eax
  80020e:	7e 17                	jle    800227 <sys_page_unmap+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800210:	83 ec 0c             	sub    $0xc,%esp
  800213:	50                   	push   %eax
  800214:	6a 06                	push   $0x6
  800216:	68 ea 0f 80 00       	push   $0x800fea
  80021b:	6a 23                	push   $0x23
  80021d:	68 07 10 80 00       	push   $0x801007
  800222:	e8 16 01 00 00       	call   80033d <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800227:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80022a:	5b                   	pop    %ebx
  80022b:	5e                   	pop    %esi
  80022c:	5f                   	pop    %edi
  80022d:	5d                   	pop    %ebp
  80022e:	c3                   	ret    

0080022f <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  80022f:	55                   	push   %ebp
  800230:	89 e5                	mov    %esp,%ebp
  800232:	57                   	push   %edi
  800233:	56                   	push   %esi
  800234:	53                   	push   %ebx
  800235:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800238:	bb 00 00 00 00       	mov    $0x0,%ebx
  80023d:	b8 08 00 00 00       	mov    $0x8,%eax
  800242:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800245:	8b 55 08             	mov    0x8(%ebp),%edx
  800248:	89 df                	mov    %ebx,%edi
  80024a:	89 de                	mov    %ebx,%esi
  80024c:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  80024e:	85 c0                	test   %eax,%eax
  800250:	7e 17                	jle    800269 <sys_env_set_status+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800252:	83 ec 0c             	sub    $0xc,%esp
  800255:	50                   	push   %eax
  800256:	6a 08                	push   $0x8
  800258:	68 ea 0f 80 00       	push   $0x800fea
  80025d:	6a 23                	push   $0x23
  80025f:	68 07 10 80 00       	push   $0x801007
  800264:	e8 d4 00 00 00       	call   80033d <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800269:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80026c:	5b                   	pop    %ebx
  80026d:	5e                   	pop    %esi
  80026e:	5f                   	pop    %edi
  80026f:	5d                   	pop    %ebp
  800270:	c3                   	ret    

00800271 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800271:	55                   	push   %ebp
  800272:	89 e5                	mov    %esp,%ebp
  800274:	57                   	push   %edi
  800275:	56                   	push   %esi
  800276:	53                   	push   %ebx
  800277:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80027a:	bb 00 00 00 00       	mov    $0x0,%ebx
  80027f:	b8 09 00 00 00       	mov    $0x9,%eax
  800284:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800287:	8b 55 08             	mov    0x8(%ebp),%edx
  80028a:	89 df                	mov    %ebx,%edi
  80028c:	89 de                	mov    %ebx,%esi
  80028e:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800290:	85 c0                	test   %eax,%eax
  800292:	7e 17                	jle    8002ab <sys_env_set_pgfault_upcall+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800294:	83 ec 0c             	sub    $0xc,%esp
  800297:	50                   	push   %eax
  800298:	6a 09                	push   $0x9
  80029a:	68 ea 0f 80 00       	push   $0x800fea
  80029f:	6a 23                	push   $0x23
  8002a1:	68 07 10 80 00       	push   $0x801007
  8002a6:	e8 92 00 00 00       	call   80033d <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  8002ab:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002ae:	5b                   	pop    %ebx
  8002af:	5e                   	pop    %esi
  8002b0:	5f                   	pop    %edi
  8002b1:	5d                   	pop    %ebp
  8002b2:	c3                   	ret    

008002b3 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  8002b3:	55                   	push   %ebp
  8002b4:	89 e5                	mov    %esp,%ebp
  8002b6:	57                   	push   %edi
  8002b7:	56                   	push   %esi
  8002b8:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8002b9:	be 00 00 00 00       	mov    $0x0,%esi
  8002be:	b8 0b 00 00 00       	mov    $0xb,%eax
  8002c3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8002c6:	8b 55 08             	mov    0x8(%ebp),%edx
  8002c9:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8002cc:	8b 7d 14             	mov    0x14(%ebp),%edi
  8002cf:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  8002d1:	5b                   	pop    %ebx
  8002d2:	5e                   	pop    %esi
  8002d3:	5f                   	pop    %edi
  8002d4:	5d                   	pop    %ebp
  8002d5:	c3                   	ret    

008002d6 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  8002d6:	55                   	push   %ebp
  8002d7:	89 e5                	mov    %esp,%ebp
  8002d9:	57                   	push   %edi
  8002da:	56                   	push   %esi
  8002db:	53                   	push   %ebx
  8002dc:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8002df:	b9 00 00 00 00       	mov    $0x0,%ecx
  8002e4:	b8 0c 00 00 00       	mov    $0xc,%eax
  8002e9:	8b 55 08             	mov    0x8(%ebp),%edx
  8002ec:	89 cb                	mov    %ecx,%ebx
  8002ee:	89 cf                	mov    %ecx,%edi
  8002f0:	89 ce                	mov    %ecx,%esi
  8002f2:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8002f4:	85 c0                	test   %eax,%eax
  8002f6:	7e 17                	jle    80030f <sys_ipc_recv+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  8002f8:	83 ec 0c             	sub    $0xc,%esp
  8002fb:	50                   	push   %eax
  8002fc:	6a 0c                	push   $0xc
  8002fe:	68 ea 0f 80 00       	push   $0x800fea
  800303:	6a 23                	push   $0x23
  800305:	68 07 10 80 00       	push   $0x801007
  80030a:	e8 2e 00 00 00       	call   80033d <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  80030f:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800312:	5b                   	pop    %ebx
  800313:	5e                   	pop    %esi
  800314:	5f                   	pop    %edi
  800315:	5d                   	pop    %ebp
  800316:	c3                   	ret    

00800317 <_pgfault_upcall>:

.text
.globl _pgfault_upcall
_pgfault_upcall:
	// Call the C page fault handler.
	pushl %esp			// function argument: pointer to UTF
  800317:	54                   	push   %esp
	movl _pgfault_handler, %eax
  800318:	a1 08 20 80 00       	mov    0x802008,%eax
	call *%eax
  80031d:	ff d0                	call   *%eax
	addl $4, %esp			// pop function argument
  80031f:	83 c4 04             	add    $0x4,%esp
	// may find that you have to rearrange your code in non-obvious
	// ways as registers become unavailable as scratch space.
	//
	// LAB 4: Your code here.

	movl 48(%esp), %eax
  800322:	8b 44 24 30          	mov    0x30(%esp),%eax
	subl $4, %eax
  800326:	83 e8 04             	sub    $0x4,%eax
	movl 40(%esp), %edx
  800329:	8b 54 24 28          	mov    0x28(%esp),%edx
	movl %edx, (%eax)
  80032d:	89 10                	mov    %edx,(%eax)
	movl %eax, 48(%esp)
  80032f:	89 44 24 30          	mov    %eax,0x30(%esp)

	// Restore the trap-time registers.  After you do this, you
	// can no longer modify any general-purpose registers.
	// LAB 4: Your code here.
	addl $8, %esp
  800333:	83 c4 08             	add    $0x8,%esp
	popal
  800336:	61                   	popa   

	// Restore eflags from the stack.  After you do this, you can
	// no longer use arithmetic operations or anything else that
	// modifies eflags.
	// LAB 4: Your code here.
	addl $4, %esp
  800337:	83 c4 04             	add    $0x4,%esp
	popfl
  80033a:	9d                   	popf   

	// Switch back to the adjusted trap-time stack.
	// LAB 4: Your code here.

	popl %esp
  80033b:	5c                   	pop    %esp

	// Return to re-execute the instruction that faulted.
	// LAB 4: Your code here.
	ret
  80033c:	c3                   	ret    

0080033d <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  80033d:	55                   	push   %ebp
  80033e:	89 e5                	mov    %esp,%ebp
  800340:	56                   	push   %esi
  800341:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800342:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800345:	8b 35 00 20 80 00    	mov    0x802000,%esi
  80034b:	e8 da fd ff ff       	call   80012a <sys_getenvid>
  800350:	83 ec 0c             	sub    $0xc,%esp
  800353:	ff 75 0c             	pushl  0xc(%ebp)
  800356:	ff 75 08             	pushl  0x8(%ebp)
  800359:	56                   	push   %esi
  80035a:	50                   	push   %eax
  80035b:	68 18 10 80 00       	push   $0x801018
  800360:	e8 b1 00 00 00       	call   800416 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800365:	83 c4 18             	add    $0x18,%esp
  800368:	53                   	push   %ebx
  800369:	ff 75 10             	pushl  0x10(%ebp)
  80036c:	e8 54 00 00 00       	call   8003c5 <vcprintf>
	cprintf("\n");
  800371:	c7 04 24 3b 10 80 00 	movl   $0x80103b,(%esp)
  800378:	e8 99 00 00 00       	call   800416 <cprintf>
  80037d:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800380:	cc                   	int3   
  800381:	eb fd                	jmp    800380 <_panic+0x43>

00800383 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800383:	55                   	push   %ebp
  800384:	89 e5                	mov    %esp,%ebp
  800386:	53                   	push   %ebx
  800387:	83 ec 04             	sub    $0x4,%esp
  80038a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  80038d:	8b 13                	mov    (%ebx),%edx
  80038f:	8d 42 01             	lea    0x1(%edx),%eax
  800392:	89 03                	mov    %eax,(%ebx)
  800394:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800397:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  80039b:	3d ff 00 00 00       	cmp    $0xff,%eax
  8003a0:	75 1a                	jne    8003bc <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8003a2:	83 ec 08             	sub    $0x8,%esp
  8003a5:	68 ff 00 00 00       	push   $0xff
  8003aa:	8d 43 08             	lea    0x8(%ebx),%eax
  8003ad:	50                   	push   %eax
  8003ae:	e8 f9 fc ff ff       	call   8000ac <sys_cputs>
		b->idx = 0;
  8003b3:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8003b9:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8003bc:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8003c0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8003c3:	c9                   	leave  
  8003c4:	c3                   	ret    

008003c5 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8003c5:	55                   	push   %ebp
  8003c6:	89 e5                	mov    %esp,%ebp
  8003c8:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8003ce:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8003d5:	00 00 00 
	b.cnt = 0;
  8003d8:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8003df:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8003e2:	ff 75 0c             	pushl  0xc(%ebp)
  8003e5:	ff 75 08             	pushl  0x8(%ebp)
  8003e8:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8003ee:	50                   	push   %eax
  8003ef:	68 83 03 80 00       	push   $0x800383
  8003f4:	e8 54 01 00 00       	call   80054d <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8003f9:	83 c4 08             	add    $0x8,%esp
  8003fc:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800402:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800408:	50                   	push   %eax
  800409:	e8 9e fc ff ff       	call   8000ac <sys_cputs>

	return b.cnt;
}
  80040e:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800414:	c9                   	leave  
  800415:	c3                   	ret    

00800416 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800416:	55                   	push   %ebp
  800417:	89 e5                	mov    %esp,%ebp
  800419:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80041c:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80041f:	50                   	push   %eax
  800420:	ff 75 08             	pushl  0x8(%ebp)
  800423:	e8 9d ff ff ff       	call   8003c5 <vcprintf>
	va_end(ap);

	return cnt;
}
  800428:	c9                   	leave  
  800429:	c3                   	ret    

0080042a <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80042a:	55                   	push   %ebp
  80042b:	89 e5                	mov    %esp,%ebp
  80042d:	57                   	push   %edi
  80042e:	56                   	push   %esi
  80042f:	53                   	push   %ebx
  800430:	83 ec 1c             	sub    $0x1c,%esp
  800433:	89 c7                	mov    %eax,%edi
  800435:	89 d6                	mov    %edx,%esi
  800437:	8b 45 08             	mov    0x8(%ebp),%eax
  80043a:	8b 55 0c             	mov    0xc(%ebp),%edx
  80043d:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800440:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800443:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800446:	bb 00 00 00 00       	mov    $0x0,%ebx
  80044b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  80044e:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800451:	39 d3                	cmp    %edx,%ebx
  800453:	72 05                	jb     80045a <printnum+0x30>
  800455:	39 45 10             	cmp    %eax,0x10(%ebp)
  800458:	77 45                	ja     80049f <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80045a:	83 ec 0c             	sub    $0xc,%esp
  80045d:	ff 75 18             	pushl  0x18(%ebp)
  800460:	8b 45 14             	mov    0x14(%ebp),%eax
  800463:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800466:	53                   	push   %ebx
  800467:	ff 75 10             	pushl  0x10(%ebp)
  80046a:	83 ec 08             	sub    $0x8,%esp
  80046d:	ff 75 e4             	pushl  -0x1c(%ebp)
  800470:	ff 75 e0             	pushl  -0x20(%ebp)
  800473:	ff 75 dc             	pushl  -0x24(%ebp)
  800476:	ff 75 d8             	pushl  -0x28(%ebp)
  800479:	e8 d2 08 00 00       	call   800d50 <__udivdi3>
  80047e:	83 c4 18             	add    $0x18,%esp
  800481:	52                   	push   %edx
  800482:	50                   	push   %eax
  800483:	89 f2                	mov    %esi,%edx
  800485:	89 f8                	mov    %edi,%eax
  800487:	e8 9e ff ff ff       	call   80042a <printnum>
  80048c:	83 c4 20             	add    $0x20,%esp
  80048f:	eb 18                	jmp    8004a9 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800491:	83 ec 08             	sub    $0x8,%esp
  800494:	56                   	push   %esi
  800495:	ff 75 18             	pushl  0x18(%ebp)
  800498:	ff d7                	call   *%edi
  80049a:	83 c4 10             	add    $0x10,%esp
  80049d:	eb 03                	jmp    8004a2 <printnum+0x78>
  80049f:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8004a2:	83 eb 01             	sub    $0x1,%ebx
  8004a5:	85 db                	test   %ebx,%ebx
  8004a7:	7f e8                	jg     800491 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8004a9:	83 ec 08             	sub    $0x8,%esp
  8004ac:	56                   	push   %esi
  8004ad:	83 ec 04             	sub    $0x4,%esp
  8004b0:	ff 75 e4             	pushl  -0x1c(%ebp)
  8004b3:	ff 75 e0             	pushl  -0x20(%ebp)
  8004b6:	ff 75 dc             	pushl  -0x24(%ebp)
  8004b9:	ff 75 d8             	pushl  -0x28(%ebp)
  8004bc:	e8 bf 09 00 00       	call   800e80 <__umoddi3>
  8004c1:	83 c4 14             	add    $0x14,%esp
  8004c4:	0f be 80 3d 10 80 00 	movsbl 0x80103d(%eax),%eax
  8004cb:	50                   	push   %eax
  8004cc:	ff d7                	call   *%edi
}
  8004ce:	83 c4 10             	add    $0x10,%esp
  8004d1:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8004d4:	5b                   	pop    %ebx
  8004d5:	5e                   	pop    %esi
  8004d6:	5f                   	pop    %edi
  8004d7:	5d                   	pop    %ebp
  8004d8:	c3                   	ret    

008004d9 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8004d9:	55                   	push   %ebp
  8004da:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8004dc:	83 fa 01             	cmp    $0x1,%edx
  8004df:	7e 0e                	jle    8004ef <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8004e1:	8b 10                	mov    (%eax),%edx
  8004e3:	8d 4a 08             	lea    0x8(%edx),%ecx
  8004e6:	89 08                	mov    %ecx,(%eax)
  8004e8:	8b 02                	mov    (%edx),%eax
  8004ea:	8b 52 04             	mov    0x4(%edx),%edx
  8004ed:	eb 22                	jmp    800511 <getuint+0x38>
	else if (lflag)
  8004ef:	85 d2                	test   %edx,%edx
  8004f1:	74 10                	je     800503 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8004f3:	8b 10                	mov    (%eax),%edx
  8004f5:	8d 4a 04             	lea    0x4(%edx),%ecx
  8004f8:	89 08                	mov    %ecx,(%eax)
  8004fa:	8b 02                	mov    (%edx),%eax
  8004fc:	ba 00 00 00 00       	mov    $0x0,%edx
  800501:	eb 0e                	jmp    800511 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800503:	8b 10                	mov    (%eax),%edx
  800505:	8d 4a 04             	lea    0x4(%edx),%ecx
  800508:	89 08                	mov    %ecx,(%eax)
  80050a:	8b 02                	mov    (%edx),%eax
  80050c:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800511:	5d                   	pop    %ebp
  800512:	c3                   	ret    

00800513 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800513:	55                   	push   %ebp
  800514:	89 e5                	mov    %esp,%ebp
  800516:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800519:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  80051d:	8b 10                	mov    (%eax),%edx
  80051f:	3b 50 04             	cmp    0x4(%eax),%edx
  800522:	73 0a                	jae    80052e <sprintputch+0x1b>
		*b->buf++ = ch;
  800524:	8d 4a 01             	lea    0x1(%edx),%ecx
  800527:	89 08                	mov    %ecx,(%eax)
  800529:	8b 45 08             	mov    0x8(%ebp),%eax
  80052c:	88 02                	mov    %al,(%edx)
}
  80052e:	5d                   	pop    %ebp
  80052f:	c3                   	ret    

00800530 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800530:	55                   	push   %ebp
  800531:	89 e5                	mov    %esp,%ebp
  800533:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  800536:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800539:	50                   	push   %eax
  80053a:	ff 75 10             	pushl  0x10(%ebp)
  80053d:	ff 75 0c             	pushl  0xc(%ebp)
  800540:	ff 75 08             	pushl  0x8(%ebp)
  800543:	e8 05 00 00 00       	call   80054d <vprintfmt>
	va_end(ap);
}
  800548:	83 c4 10             	add    $0x10,%esp
  80054b:	c9                   	leave  
  80054c:	c3                   	ret    

0080054d <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  80054d:	55                   	push   %ebp
  80054e:	89 e5                	mov    %esp,%ebp
  800550:	57                   	push   %edi
  800551:	56                   	push   %esi
  800552:	53                   	push   %ebx
  800553:	83 ec 2c             	sub    $0x2c,%esp
  800556:	8b 75 08             	mov    0x8(%ebp),%esi
  800559:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80055c:	8b 7d 10             	mov    0x10(%ebp),%edi
  80055f:	eb 12                	jmp    800573 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800561:	85 c0                	test   %eax,%eax
  800563:	0f 84 89 03 00 00    	je     8008f2 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
  800569:	83 ec 08             	sub    $0x8,%esp
  80056c:	53                   	push   %ebx
  80056d:	50                   	push   %eax
  80056e:	ff d6                	call   *%esi
  800570:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800573:	83 c7 01             	add    $0x1,%edi
  800576:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80057a:	83 f8 25             	cmp    $0x25,%eax
  80057d:	75 e2                	jne    800561 <vprintfmt+0x14>
  80057f:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800583:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80058a:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800591:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800598:	ba 00 00 00 00       	mov    $0x0,%edx
  80059d:	eb 07                	jmp    8005a6 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80059f:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8005a2:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005a6:	8d 47 01             	lea    0x1(%edi),%eax
  8005a9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8005ac:	0f b6 07             	movzbl (%edi),%eax
  8005af:	0f b6 c8             	movzbl %al,%ecx
  8005b2:	83 e8 23             	sub    $0x23,%eax
  8005b5:	3c 55                	cmp    $0x55,%al
  8005b7:	0f 87 1a 03 00 00    	ja     8008d7 <vprintfmt+0x38a>
  8005bd:	0f b6 c0             	movzbl %al,%eax
  8005c0:	ff 24 85 00 11 80 00 	jmp    *0x801100(,%eax,4)
  8005c7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8005ca:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8005ce:	eb d6                	jmp    8005a6 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005d0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005d3:	b8 00 00 00 00       	mov    $0x0,%eax
  8005d8:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8005db:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8005de:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  8005e2:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  8005e5:	8d 51 d0             	lea    -0x30(%ecx),%edx
  8005e8:	83 fa 09             	cmp    $0x9,%edx
  8005eb:	77 39                	ja     800626 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8005ed:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8005f0:	eb e9                	jmp    8005db <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8005f2:	8b 45 14             	mov    0x14(%ebp),%eax
  8005f5:	8d 48 04             	lea    0x4(%eax),%ecx
  8005f8:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8005fb:	8b 00                	mov    (%eax),%eax
  8005fd:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800600:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800603:	eb 27                	jmp    80062c <vprintfmt+0xdf>
  800605:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800608:	85 c0                	test   %eax,%eax
  80060a:	b9 00 00 00 00       	mov    $0x0,%ecx
  80060f:	0f 49 c8             	cmovns %eax,%ecx
  800612:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800615:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800618:	eb 8c                	jmp    8005a6 <vprintfmt+0x59>
  80061a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  80061d:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800624:	eb 80                	jmp    8005a6 <vprintfmt+0x59>
  800626:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800629:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  80062c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800630:	0f 89 70 ff ff ff    	jns    8005a6 <vprintfmt+0x59>
				width = precision, precision = -1;
  800636:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800639:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80063c:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800643:	e9 5e ff ff ff       	jmp    8005a6 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800648:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80064b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80064e:	e9 53 ff ff ff       	jmp    8005a6 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800653:	8b 45 14             	mov    0x14(%ebp),%eax
  800656:	8d 50 04             	lea    0x4(%eax),%edx
  800659:	89 55 14             	mov    %edx,0x14(%ebp)
  80065c:	83 ec 08             	sub    $0x8,%esp
  80065f:	53                   	push   %ebx
  800660:	ff 30                	pushl  (%eax)
  800662:	ff d6                	call   *%esi
			break;
  800664:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800667:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80066a:	e9 04 ff ff ff       	jmp    800573 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80066f:	8b 45 14             	mov    0x14(%ebp),%eax
  800672:	8d 50 04             	lea    0x4(%eax),%edx
  800675:	89 55 14             	mov    %edx,0x14(%ebp)
  800678:	8b 00                	mov    (%eax),%eax
  80067a:	99                   	cltd   
  80067b:	31 d0                	xor    %edx,%eax
  80067d:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80067f:	83 f8 08             	cmp    $0x8,%eax
  800682:	7f 0b                	jg     80068f <vprintfmt+0x142>
  800684:	8b 14 85 60 12 80 00 	mov    0x801260(,%eax,4),%edx
  80068b:	85 d2                	test   %edx,%edx
  80068d:	75 18                	jne    8006a7 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  80068f:	50                   	push   %eax
  800690:	68 55 10 80 00       	push   $0x801055
  800695:	53                   	push   %ebx
  800696:	56                   	push   %esi
  800697:	e8 94 fe ff ff       	call   800530 <printfmt>
  80069c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80069f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8006a2:	e9 cc fe ff ff       	jmp    800573 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8006a7:	52                   	push   %edx
  8006a8:	68 5e 10 80 00       	push   $0x80105e
  8006ad:	53                   	push   %ebx
  8006ae:	56                   	push   %esi
  8006af:	e8 7c fe ff ff       	call   800530 <printfmt>
  8006b4:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006b7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8006ba:	e9 b4 fe ff ff       	jmp    800573 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8006bf:	8b 45 14             	mov    0x14(%ebp),%eax
  8006c2:	8d 50 04             	lea    0x4(%eax),%edx
  8006c5:	89 55 14             	mov    %edx,0x14(%ebp)
  8006c8:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8006ca:	85 ff                	test   %edi,%edi
  8006cc:	b8 4e 10 80 00       	mov    $0x80104e,%eax
  8006d1:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8006d4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8006d8:	0f 8e 94 00 00 00    	jle    800772 <vprintfmt+0x225>
  8006de:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8006e2:	0f 84 98 00 00 00    	je     800780 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  8006e8:	83 ec 08             	sub    $0x8,%esp
  8006eb:	ff 75 d0             	pushl  -0x30(%ebp)
  8006ee:	57                   	push   %edi
  8006ef:	e8 86 02 00 00       	call   80097a <strnlen>
  8006f4:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8006f7:	29 c1                	sub    %eax,%ecx
  8006f9:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  8006fc:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8006ff:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800703:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800706:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800709:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80070b:	eb 0f                	jmp    80071c <vprintfmt+0x1cf>
					putch(padc, putdat);
  80070d:	83 ec 08             	sub    $0x8,%esp
  800710:	53                   	push   %ebx
  800711:	ff 75 e0             	pushl  -0x20(%ebp)
  800714:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800716:	83 ef 01             	sub    $0x1,%edi
  800719:	83 c4 10             	add    $0x10,%esp
  80071c:	85 ff                	test   %edi,%edi
  80071e:	7f ed                	jg     80070d <vprintfmt+0x1c0>
  800720:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800723:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  800726:	85 c9                	test   %ecx,%ecx
  800728:	b8 00 00 00 00       	mov    $0x0,%eax
  80072d:	0f 49 c1             	cmovns %ecx,%eax
  800730:	29 c1                	sub    %eax,%ecx
  800732:	89 75 08             	mov    %esi,0x8(%ebp)
  800735:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800738:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80073b:	89 cb                	mov    %ecx,%ebx
  80073d:	eb 4d                	jmp    80078c <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  80073f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800743:	74 1b                	je     800760 <vprintfmt+0x213>
  800745:	0f be c0             	movsbl %al,%eax
  800748:	83 e8 20             	sub    $0x20,%eax
  80074b:	83 f8 5e             	cmp    $0x5e,%eax
  80074e:	76 10                	jbe    800760 <vprintfmt+0x213>
					putch('?', putdat);
  800750:	83 ec 08             	sub    $0x8,%esp
  800753:	ff 75 0c             	pushl  0xc(%ebp)
  800756:	6a 3f                	push   $0x3f
  800758:	ff 55 08             	call   *0x8(%ebp)
  80075b:	83 c4 10             	add    $0x10,%esp
  80075e:	eb 0d                	jmp    80076d <vprintfmt+0x220>
				else
					putch(ch, putdat);
  800760:	83 ec 08             	sub    $0x8,%esp
  800763:	ff 75 0c             	pushl  0xc(%ebp)
  800766:	52                   	push   %edx
  800767:	ff 55 08             	call   *0x8(%ebp)
  80076a:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80076d:	83 eb 01             	sub    $0x1,%ebx
  800770:	eb 1a                	jmp    80078c <vprintfmt+0x23f>
  800772:	89 75 08             	mov    %esi,0x8(%ebp)
  800775:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800778:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80077b:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80077e:	eb 0c                	jmp    80078c <vprintfmt+0x23f>
  800780:	89 75 08             	mov    %esi,0x8(%ebp)
  800783:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800786:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800789:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80078c:	83 c7 01             	add    $0x1,%edi
  80078f:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800793:	0f be d0             	movsbl %al,%edx
  800796:	85 d2                	test   %edx,%edx
  800798:	74 23                	je     8007bd <vprintfmt+0x270>
  80079a:	85 f6                	test   %esi,%esi
  80079c:	78 a1                	js     80073f <vprintfmt+0x1f2>
  80079e:	83 ee 01             	sub    $0x1,%esi
  8007a1:	79 9c                	jns    80073f <vprintfmt+0x1f2>
  8007a3:	89 df                	mov    %ebx,%edi
  8007a5:	8b 75 08             	mov    0x8(%ebp),%esi
  8007a8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8007ab:	eb 18                	jmp    8007c5 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8007ad:	83 ec 08             	sub    $0x8,%esp
  8007b0:	53                   	push   %ebx
  8007b1:	6a 20                	push   $0x20
  8007b3:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8007b5:	83 ef 01             	sub    $0x1,%edi
  8007b8:	83 c4 10             	add    $0x10,%esp
  8007bb:	eb 08                	jmp    8007c5 <vprintfmt+0x278>
  8007bd:	89 df                	mov    %ebx,%edi
  8007bf:	8b 75 08             	mov    0x8(%ebp),%esi
  8007c2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8007c5:	85 ff                	test   %edi,%edi
  8007c7:	7f e4                	jg     8007ad <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8007c9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8007cc:	e9 a2 fd ff ff       	jmp    800573 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8007d1:	83 fa 01             	cmp    $0x1,%edx
  8007d4:	7e 16                	jle    8007ec <vprintfmt+0x29f>
		return va_arg(*ap, long long);
  8007d6:	8b 45 14             	mov    0x14(%ebp),%eax
  8007d9:	8d 50 08             	lea    0x8(%eax),%edx
  8007dc:	89 55 14             	mov    %edx,0x14(%ebp)
  8007df:	8b 50 04             	mov    0x4(%eax),%edx
  8007e2:	8b 00                	mov    (%eax),%eax
  8007e4:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8007e7:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8007ea:	eb 32                	jmp    80081e <vprintfmt+0x2d1>
	else if (lflag)
  8007ec:	85 d2                	test   %edx,%edx
  8007ee:	74 18                	je     800808 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
  8007f0:	8b 45 14             	mov    0x14(%ebp),%eax
  8007f3:	8d 50 04             	lea    0x4(%eax),%edx
  8007f6:	89 55 14             	mov    %edx,0x14(%ebp)
  8007f9:	8b 00                	mov    (%eax),%eax
  8007fb:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8007fe:	89 c1                	mov    %eax,%ecx
  800800:	c1 f9 1f             	sar    $0x1f,%ecx
  800803:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800806:	eb 16                	jmp    80081e <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
  800808:	8b 45 14             	mov    0x14(%ebp),%eax
  80080b:	8d 50 04             	lea    0x4(%eax),%edx
  80080e:	89 55 14             	mov    %edx,0x14(%ebp)
  800811:	8b 00                	mov    (%eax),%eax
  800813:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800816:	89 c1                	mov    %eax,%ecx
  800818:	c1 f9 1f             	sar    $0x1f,%ecx
  80081b:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80081e:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800821:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800824:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800829:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  80082d:	79 74                	jns    8008a3 <vprintfmt+0x356>
				putch('-', putdat);
  80082f:	83 ec 08             	sub    $0x8,%esp
  800832:	53                   	push   %ebx
  800833:	6a 2d                	push   $0x2d
  800835:	ff d6                	call   *%esi
				num = -(long long) num;
  800837:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80083a:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80083d:	f7 d8                	neg    %eax
  80083f:	83 d2 00             	adc    $0x0,%edx
  800842:	f7 da                	neg    %edx
  800844:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800847:	b9 0a 00 00 00       	mov    $0xa,%ecx
  80084c:	eb 55                	jmp    8008a3 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  80084e:	8d 45 14             	lea    0x14(%ebp),%eax
  800851:	e8 83 fc ff ff       	call   8004d9 <getuint>
			base = 10;
  800856:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  80085b:	eb 46                	jmp    8008a3 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  80085d:	8d 45 14             	lea    0x14(%ebp),%eax
  800860:	e8 74 fc ff ff       	call   8004d9 <getuint>
      			base = 8;
  800865:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  80086a:	eb 37                	jmp    8008a3 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
  80086c:	83 ec 08             	sub    $0x8,%esp
  80086f:	53                   	push   %ebx
  800870:	6a 30                	push   $0x30
  800872:	ff d6                	call   *%esi
			putch('x', putdat);
  800874:	83 c4 08             	add    $0x8,%esp
  800877:	53                   	push   %ebx
  800878:	6a 78                	push   $0x78
  80087a:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80087c:	8b 45 14             	mov    0x14(%ebp),%eax
  80087f:	8d 50 04             	lea    0x4(%eax),%edx
  800882:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800885:	8b 00                	mov    (%eax),%eax
  800887:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  80088c:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80088f:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800894:	eb 0d                	jmp    8008a3 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800896:	8d 45 14             	lea    0x14(%ebp),%eax
  800899:	e8 3b fc ff ff       	call   8004d9 <getuint>
			base = 16;
  80089e:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8008a3:	83 ec 0c             	sub    $0xc,%esp
  8008a6:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8008aa:	57                   	push   %edi
  8008ab:	ff 75 e0             	pushl  -0x20(%ebp)
  8008ae:	51                   	push   %ecx
  8008af:	52                   	push   %edx
  8008b0:	50                   	push   %eax
  8008b1:	89 da                	mov    %ebx,%edx
  8008b3:	89 f0                	mov    %esi,%eax
  8008b5:	e8 70 fb ff ff       	call   80042a <printnum>
			break;
  8008ba:	83 c4 20             	add    $0x20,%esp
  8008bd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8008c0:	e9 ae fc ff ff       	jmp    800573 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8008c5:	83 ec 08             	sub    $0x8,%esp
  8008c8:	53                   	push   %ebx
  8008c9:	51                   	push   %ecx
  8008ca:	ff d6                	call   *%esi
			break;
  8008cc:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8008cf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8008d2:	e9 9c fc ff ff       	jmp    800573 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8008d7:	83 ec 08             	sub    $0x8,%esp
  8008da:	53                   	push   %ebx
  8008db:	6a 25                	push   $0x25
  8008dd:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8008df:	83 c4 10             	add    $0x10,%esp
  8008e2:	eb 03                	jmp    8008e7 <vprintfmt+0x39a>
  8008e4:	83 ef 01             	sub    $0x1,%edi
  8008e7:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8008eb:	75 f7                	jne    8008e4 <vprintfmt+0x397>
  8008ed:	e9 81 fc ff ff       	jmp    800573 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  8008f2:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8008f5:	5b                   	pop    %ebx
  8008f6:	5e                   	pop    %esi
  8008f7:	5f                   	pop    %edi
  8008f8:	5d                   	pop    %ebp
  8008f9:	c3                   	ret    

008008fa <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8008fa:	55                   	push   %ebp
  8008fb:	89 e5                	mov    %esp,%ebp
  8008fd:	83 ec 18             	sub    $0x18,%esp
  800900:	8b 45 08             	mov    0x8(%ebp),%eax
  800903:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800906:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800909:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80090d:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800910:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800917:	85 c0                	test   %eax,%eax
  800919:	74 26                	je     800941 <vsnprintf+0x47>
  80091b:	85 d2                	test   %edx,%edx
  80091d:	7e 22                	jle    800941 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  80091f:	ff 75 14             	pushl  0x14(%ebp)
  800922:	ff 75 10             	pushl  0x10(%ebp)
  800925:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800928:	50                   	push   %eax
  800929:	68 13 05 80 00       	push   $0x800513
  80092e:	e8 1a fc ff ff       	call   80054d <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800933:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800936:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800939:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80093c:	83 c4 10             	add    $0x10,%esp
  80093f:	eb 05                	jmp    800946 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800941:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800946:	c9                   	leave  
  800947:	c3                   	ret    

00800948 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800948:	55                   	push   %ebp
  800949:	89 e5                	mov    %esp,%ebp
  80094b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  80094e:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800951:	50                   	push   %eax
  800952:	ff 75 10             	pushl  0x10(%ebp)
  800955:	ff 75 0c             	pushl  0xc(%ebp)
  800958:	ff 75 08             	pushl  0x8(%ebp)
  80095b:	e8 9a ff ff ff       	call   8008fa <vsnprintf>
	va_end(ap);

	return rc;
}
  800960:	c9                   	leave  
  800961:	c3                   	ret    

00800962 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800962:	55                   	push   %ebp
  800963:	89 e5                	mov    %esp,%ebp
  800965:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800968:	b8 00 00 00 00       	mov    $0x0,%eax
  80096d:	eb 03                	jmp    800972 <strlen+0x10>
		n++;
  80096f:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800972:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800976:	75 f7                	jne    80096f <strlen+0xd>
		n++;
	return n;
}
  800978:	5d                   	pop    %ebp
  800979:	c3                   	ret    

0080097a <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80097a:	55                   	push   %ebp
  80097b:	89 e5                	mov    %esp,%ebp
  80097d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800980:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800983:	ba 00 00 00 00       	mov    $0x0,%edx
  800988:	eb 03                	jmp    80098d <strnlen+0x13>
		n++;
  80098a:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80098d:	39 c2                	cmp    %eax,%edx
  80098f:	74 08                	je     800999 <strnlen+0x1f>
  800991:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  800995:	75 f3                	jne    80098a <strnlen+0x10>
  800997:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800999:	5d                   	pop    %ebp
  80099a:	c3                   	ret    

0080099b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  80099b:	55                   	push   %ebp
  80099c:	89 e5                	mov    %esp,%ebp
  80099e:	53                   	push   %ebx
  80099f:	8b 45 08             	mov    0x8(%ebp),%eax
  8009a2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8009a5:	89 c2                	mov    %eax,%edx
  8009a7:	83 c2 01             	add    $0x1,%edx
  8009aa:	83 c1 01             	add    $0x1,%ecx
  8009ad:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8009b1:	88 5a ff             	mov    %bl,-0x1(%edx)
  8009b4:	84 db                	test   %bl,%bl
  8009b6:	75 ef                	jne    8009a7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8009b8:	5b                   	pop    %ebx
  8009b9:	5d                   	pop    %ebp
  8009ba:	c3                   	ret    

008009bb <strcat>:

char *
strcat(char *dst, const char *src)
{
  8009bb:	55                   	push   %ebp
  8009bc:	89 e5                	mov    %esp,%ebp
  8009be:	53                   	push   %ebx
  8009bf:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8009c2:	53                   	push   %ebx
  8009c3:	e8 9a ff ff ff       	call   800962 <strlen>
  8009c8:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8009cb:	ff 75 0c             	pushl  0xc(%ebp)
  8009ce:	01 d8                	add    %ebx,%eax
  8009d0:	50                   	push   %eax
  8009d1:	e8 c5 ff ff ff       	call   80099b <strcpy>
	return dst;
}
  8009d6:	89 d8                	mov    %ebx,%eax
  8009d8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8009db:	c9                   	leave  
  8009dc:	c3                   	ret    

008009dd <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8009dd:	55                   	push   %ebp
  8009de:	89 e5                	mov    %esp,%ebp
  8009e0:	56                   	push   %esi
  8009e1:	53                   	push   %ebx
  8009e2:	8b 75 08             	mov    0x8(%ebp),%esi
  8009e5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8009e8:	89 f3                	mov    %esi,%ebx
  8009ea:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8009ed:	89 f2                	mov    %esi,%edx
  8009ef:	eb 0f                	jmp    800a00 <strncpy+0x23>
		*dst++ = *src;
  8009f1:	83 c2 01             	add    $0x1,%edx
  8009f4:	0f b6 01             	movzbl (%ecx),%eax
  8009f7:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8009fa:	80 39 01             	cmpb   $0x1,(%ecx)
  8009fd:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800a00:	39 da                	cmp    %ebx,%edx
  800a02:	75 ed                	jne    8009f1 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800a04:	89 f0                	mov    %esi,%eax
  800a06:	5b                   	pop    %ebx
  800a07:	5e                   	pop    %esi
  800a08:	5d                   	pop    %ebp
  800a09:	c3                   	ret    

00800a0a <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800a0a:	55                   	push   %ebp
  800a0b:	89 e5                	mov    %esp,%ebp
  800a0d:	56                   	push   %esi
  800a0e:	53                   	push   %ebx
  800a0f:	8b 75 08             	mov    0x8(%ebp),%esi
  800a12:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a15:	8b 55 10             	mov    0x10(%ebp),%edx
  800a18:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800a1a:	85 d2                	test   %edx,%edx
  800a1c:	74 21                	je     800a3f <strlcpy+0x35>
  800a1e:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800a22:	89 f2                	mov    %esi,%edx
  800a24:	eb 09                	jmp    800a2f <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800a26:	83 c2 01             	add    $0x1,%edx
  800a29:	83 c1 01             	add    $0x1,%ecx
  800a2c:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800a2f:	39 c2                	cmp    %eax,%edx
  800a31:	74 09                	je     800a3c <strlcpy+0x32>
  800a33:	0f b6 19             	movzbl (%ecx),%ebx
  800a36:	84 db                	test   %bl,%bl
  800a38:	75 ec                	jne    800a26 <strlcpy+0x1c>
  800a3a:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800a3c:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800a3f:	29 f0                	sub    %esi,%eax
}
  800a41:	5b                   	pop    %ebx
  800a42:	5e                   	pop    %esi
  800a43:	5d                   	pop    %ebp
  800a44:	c3                   	ret    

00800a45 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800a45:	55                   	push   %ebp
  800a46:	89 e5                	mov    %esp,%ebp
  800a48:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a4b:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800a4e:	eb 06                	jmp    800a56 <strcmp+0x11>
		p++, q++;
  800a50:	83 c1 01             	add    $0x1,%ecx
  800a53:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800a56:	0f b6 01             	movzbl (%ecx),%eax
  800a59:	84 c0                	test   %al,%al
  800a5b:	74 04                	je     800a61 <strcmp+0x1c>
  800a5d:	3a 02                	cmp    (%edx),%al
  800a5f:	74 ef                	je     800a50 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800a61:	0f b6 c0             	movzbl %al,%eax
  800a64:	0f b6 12             	movzbl (%edx),%edx
  800a67:	29 d0                	sub    %edx,%eax
}
  800a69:	5d                   	pop    %ebp
  800a6a:	c3                   	ret    

00800a6b <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800a6b:	55                   	push   %ebp
  800a6c:	89 e5                	mov    %esp,%ebp
  800a6e:	53                   	push   %ebx
  800a6f:	8b 45 08             	mov    0x8(%ebp),%eax
  800a72:	8b 55 0c             	mov    0xc(%ebp),%edx
  800a75:	89 c3                	mov    %eax,%ebx
  800a77:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800a7a:	eb 06                	jmp    800a82 <strncmp+0x17>
		n--, p++, q++;
  800a7c:	83 c0 01             	add    $0x1,%eax
  800a7f:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800a82:	39 d8                	cmp    %ebx,%eax
  800a84:	74 15                	je     800a9b <strncmp+0x30>
  800a86:	0f b6 08             	movzbl (%eax),%ecx
  800a89:	84 c9                	test   %cl,%cl
  800a8b:	74 04                	je     800a91 <strncmp+0x26>
  800a8d:	3a 0a                	cmp    (%edx),%cl
  800a8f:	74 eb                	je     800a7c <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800a91:	0f b6 00             	movzbl (%eax),%eax
  800a94:	0f b6 12             	movzbl (%edx),%edx
  800a97:	29 d0                	sub    %edx,%eax
  800a99:	eb 05                	jmp    800aa0 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800a9b:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800aa0:	5b                   	pop    %ebx
  800aa1:	5d                   	pop    %ebp
  800aa2:	c3                   	ret    

00800aa3 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800aa3:	55                   	push   %ebp
  800aa4:	89 e5                	mov    %esp,%ebp
  800aa6:	8b 45 08             	mov    0x8(%ebp),%eax
  800aa9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800aad:	eb 07                	jmp    800ab6 <strchr+0x13>
		if (*s == c)
  800aaf:	38 ca                	cmp    %cl,%dl
  800ab1:	74 0f                	je     800ac2 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800ab3:	83 c0 01             	add    $0x1,%eax
  800ab6:	0f b6 10             	movzbl (%eax),%edx
  800ab9:	84 d2                	test   %dl,%dl
  800abb:	75 f2                	jne    800aaf <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800abd:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800ac2:	5d                   	pop    %ebp
  800ac3:	c3                   	ret    

00800ac4 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800ac4:	55                   	push   %ebp
  800ac5:	89 e5                	mov    %esp,%ebp
  800ac7:	8b 45 08             	mov    0x8(%ebp),%eax
  800aca:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800ace:	eb 03                	jmp    800ad3 <strfind+0xf>
  800ad0:	83 c0 01             	add    $0x1,%eax
  800ad3:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800ad6:	38 ca                	cmp    %cl,%dl
  800ad8:	74 04                	je     800ade <strfind+0x1a>
  800ada:	84 d2                	test   %dl,%dl
  800adc:	75 f2                	jne    800ad0 <strfind+0xc>
			break;
	return (char *) s;
}
  800ade:	5d                   	pop    %ebp
  800adf:	c3                   	ret    

00800ae0 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800ae0:	55                   	push   %ebp
  800ae1:	89 e5                	mov    %esp,%ebp
  800ae3:	57                   	push   %edi
  800ae4:	56                   	push   %esi
  800ae5:	53                   	push   %ebx
  800ae6:	8b 7d 08             	mov    0x8(%ebp),%edi
  800ae9:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800aec:	85 c9                	test   %ecx,%ecx
  800aee:	74 36                	je     800b26 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800af0:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800af6:	75 28                	jne    800b20 <memset+0x40>
  800af8:	f6 c1 03             	test   $0x3,%cl
  800afb:	75 23                	jne    800b20 <memset+0x40>
		c &= 0xFF;
  800afd:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800b01:	89 d3                	mov    %edx,%ebx
  800b03:	c1 e3 08             	shl    $0x8,%ebx
  800b06:	89 d6                	mov    %edx,%esi
  800b08:	c1 e6 18             	shl    $0x18,%esi
  800b0b:	89 d0                	mov    %edx,%eax
  800b0d:	c1 e0 10             	shl    $0x10,%eax
  800b10:	09 f0                	or     %esi,%eax
  800b12:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800b14:	89 d8                	mov    %ebx,%eax
  800b16:	09 d0                	or     %edx,%eax
  800b18:	c1 e9 02             	shr    $0x2,%ecx
  800b1b:	fc                   	cld    
  800b1c:	f3 ab                	rep stos %eax,%es:(%edi)
  800b1e:	eb 06                	jmp    800b26 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800b20:	8b 45 0c             	mov    0xc(%ebp),%eax
  800b23:	fc                   	cld    
  800b24:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800b26:	89 f8                	mov    %edi,%eax
  800b28:	5b                   	pop    %ebx
  800b29:	5e                   	pop    %esi
  800b2a:	5f                   	pop    %edi
  800b2b:	5d                   	pop    %ebp
  800b2c:	c3                   	ret    

00800b2d <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800b2d:	55                   	push   %ebp
  800b2e:	89 e5                	mov    %esp,%ebp
  800b30:	57                   	push   %edi
  800b31:	56                   	push   %esi
  800b32:	8b 45 08             	mov    0x8(%ebp),%eax
  800b35:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b38:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800b3b:	39 c6                	cmp    %eax,%esi
  800b3d:	73 35                	jae    800b74 <memmove+0x47>
  800b3f:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800b42:	39 d0                	cmp    %edx,%eax
  800b44:	73 2e                	jae    800b74 <memmove+0x47>
		s += n;
		d += n;
  800b46:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800b49:	89 d6                	mov    %edx,%esi
  800b4b:	09 fe                	or     %edi,%esi
  800b4d:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800b53:	75 13                	jne    800b68 <memmove+0x3b>
  800b55:	f6 c1 03             	test   $0x3,%cl
  800b58:	75 0e                	jne    800b68 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800b5a:	83 ef 04             	sub    $0x4,%edi
  800b5d:	8d 72 fc             	lea    -0x4(%edx),%esi
  800b60:	c1 e9 02             	shr    $0x2,%ecx
  800b63:	fd                   	std    
  800b64:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800b66:	eb 09                	jmp    800b71 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800b68:	83 ef 01             	sub    $0x1,%edi
  800b6b:	8d 72 ff             	lea    -0x1(%edx),%esi
  800b6e:	fd                   	std    
  800b6f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800b71:	fc                   	cld    
  800b72:	eb 1d                	jmp    800b91 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800b74:	89 f2                	mov    %esi,%edx
  800b76:	09 c2                	or     %eax,%edx
  800b78:	f6 c2 03             	test   $0x3,%dl
  800b7b:	75 0f                	jne    800b8c <memmove+0x5f>
  800b7d:	f6 c1 03             	test   $0x3,%cl
  800b80:	75 0a                	jne    800b8c <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800b82:	c1 e9 02             	shr    $0x2,%ecx
  800b85:	89 c7                	mov    %eax,%edi
  800b87:	fc                   	cld    
  800b88:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800b8a:	eb 05                	jmp    800b91 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800b8c:	89 c7                	mov    %eax,%edi
  800b8e:	fc                   	cld    
  800b8f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800b91:	5e                   	pop    %esi
  800b92:	5f                   	pop    %edi
  800b93:	5d                   	pop    %ebp
  800b94:	c3                   	ret    

00800b95 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800b95:	55                   	push   %ebp
  800b96:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800b98:	ff 75 10             	pushl  0x10(%ebp)
  800b9b:	ff 75 0c             	pushl  0xc(%ebp)
  800b9e:	ff 75 08             	pushl  0x8(%ebp)
  800ba1:	e8 87 ff ff ff       	call   800b2d <memmove>
}
  800ba6:	c9                   	leave  
  800ba7:	c3                   	ret    

00800ba8 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800ba8:	55                   	push   %ebp
  800ba9:	89 e5                	mov    %esp,%ebp
  800bab:	56                   	push   %esi
  800bac:	53                   	push   %ebx
  800bad:	8b 45 08             	mov    0x8(%ebp),%eax
  800bb0:	8b 55 0c             	mov    0xc(%ebp),%edx
  800bb3:	89 c6                	mov    %eax,%esi
  800bb5:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800bb8:	eb 1a                	jmp    800bd4 <memcmp+0x2c>
		if (*s1 != *s2)
  800bba:	0f b6 08             	movzbl (%eax),%ecx
  800bbd:	0f b6 1a             	movzbl (%edx),%ebx
  800bc0:	38 d9                	cmp    %bl,%cl
  800bc2:	74 0a                	je     800bce <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800bc4:	0f b6 c1             	movzbl %cl,%eax
  800bc7:	0f b6 db             	movzbl %bl,%ebx
  800bca:	29 d8                	sub    %ebx,%eax
  800bcc:	eb 0f                	jmp    800bdd <memcmp+0x35>
		s1++, s2++;
  800bce:	83 c0 01             	add    $0x1,%eax
  800bd1:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800bd4:	39 f0                	cmp    %esi,%eax
  800bd6:	75 e2                	jne    800bba <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800bd8:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800bdd:	5b                   	pop    %ebx
  800bde:	5e                   	pop    %esi
  800bdf:	5d                   	pop    %ebp
  800be0:	c3                   	ret    

00800be1 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800be1:	55                   	push   %ebp
  800be2:	89 e5                	mov    %esp,%ebp
  800be4:	53                   	push   %ebx
  800be5:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800be8:	89 c1                	mov    %eax,%ecx
  800bea:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800bed:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800bf1:	eb 0a                	jmp    800bfd <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800bf3:	0f b6 10             	movzbl (%eax),%edx
  800bf6:	39 da                	cmp    %ebx,%edx
  800bf8:	74 07                	je     800c01 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800bfa:	83 c0 01             	add    $0x1,%eax
  800bfd:	39 c8                	cmp    %ecx,%eax
  800bff:	72 f2                	jb     800bf3 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800c01:	5b                   	pop    %ebx
  800c02:	5d                   	pop    %ebp
  800c03:	c3                   	ret    

00800c04 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800c04:	55                   	push   %ebp
  800c05:	89 e5                	mov    %esp,%ebp
  800c07:	57                   	push   %edi
  800c08:	56                   	push   %esi
  800c09:	53                   	push   %ebx
  800c0a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800c0d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800c10:	eb 03                	jmp    800c15 <strtol+0x11>
		s++;
  800c12:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800c15:	0f b6 01             	movzbl (%ecx),%eax
  800c18:	3c 20                	cmp    $0x20,%al
  800c1a:	74 f6                	je     800c12 <strtol+0xe>
  800c1c:	3c 09                	cmp    $0x9,%al
  800c1e:	74 f2                	je     800c12 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800c20:	3c 2b                	cmp    $0x2b,%al
  800c22:	75 0a                	jne    800c2e <strtol+0x2a>
		s++;
  800c24:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800c27:	bf 00 00 00 00       	mov    $0x0,%edi
  800c2c:	eb 11                	jmp    800c3f <strtol+0x3b>
  800c2e:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800c33:	3c 2d                	cmp    $0x2d,%al
  800c35:	75 08                	jne    800c3f <strtol+0x3b>
		s++, neg = 1;
  800c37:	83 c1 01             	add    $0x1,%ecx
  800c3a:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800c3f:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800c45:	75 15                	jne    800c5c <strtol+0x58>
  800c47:	80 39 30             	cmpb   $0x30,(%ecx)
  800c4a:	75 10                	jne    800c5c <strtol+0x58>
  800c4c:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800c50:	75 7c                	jne    800cce <strtol+0xca>
		s += 2, base = 16;
  800c52:	83 c1 02             	add    $0x2,%ecx
  800c55:	bb 10 00 00 00       	mov    $0x10,%ebx
  800c5a:	eb 16                	jmp    800c72 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800c5c:	85 db                	test   %ebx,%ebx
  800c5e:	75 12                	jne    800c72 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800c60:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800c65:	80 39 30             	cmpb   $0x30,(%ecx)
  800c68:	75 08                	jne    800c72 <strtol+0x6e>
		s++, base = 8;
  800c6a:	83 c1 01             	add    $0x1,%ecx
  800c6d:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800c72:	b8 00 00 00 00       	mov    $0x0,%eax
  800c77:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800c7a:	0f b6 11             	movzbl (%ecx),%edx
  800c7d:	8d 72 d0             	lea    -0x30(%edx),%esi
  800c80:	89 f3                	mov    %esi,%ebx
  800c82:	80 fb 09             	cmp    $0x9,%bl
  800c85:	77 08                	ja     800c8f <strtol+0x8b>
			dig = *s - '0';
  800c87:	0f be d2             	movsbl %dl,%edx
  800c8a:	83 ea 30             	sub    $0x30,%edx
  800c8d:	eb 22                	jmp    800cb1 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800c8f:	8d 72 9f             	lea    -0x61(%edx),%esi
  800c92:	89 f3                	mov    %esi,%ebx
  800c94:	80 fb 19             	cmp    $0x19,%bl
  800c97:	77 08                	ja     800ca1 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800c99:	0f be d2             	movsbl %dl,%edx
  800c9c:	83 ea 57             	sub    $0x57,%edx
  800c9f:	eb 10                	jmp    800cb1 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800ca1:	8d 72 bf             	lea    -0x41(%edx),%esi
  800ca4:	89 f3                	mov    %esi,%ebx
  800ca6:	80 fb 19             	cmp    $0x19,%bl
  800ca9:	77 16                	ja     800cc1 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800cab:	0f be d2             	movsbl %dl,%edx
  800cae:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800cb1:	3b 55 10             	cmp    0x10(%ebp),%edx
  800cb4:	7d 0b                	jge    800cc1 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800cb6:	83 c1 01             	add    $0x1,%ecx
  800cb9:	0f af 45 10          	imul   0x10(%ebp),%eax
  800cbd:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800cbf:	eb b9                	jmp    800c7a <strtol+0x76>

	if (endptr)
  800cc1:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800cc5:	74 0d                	je     800cd4 <strtol+0xd0>
		*endptr = (char *) s;
  800cc7:	8b 75 0c             	mov    0xc(%ebp),%esi
  800cca:	89 0e                	mov    %ecx,(%esi)
  800ccc:	eb 06                	jmp    800cd4 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800cce:	85 db                	test   %ebx,%ebx
  800cd0:	74 98                	je     800c6a <strtol+0x66>
  800cd2:	eb 9e                	jmp    800c72 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800cd4:	89 c2                	mov    %eax,%edx
  800cd6:	f7 da                	neg    %edx
  800cd8:	85 ff                	test   %edi,%edi
  800cda:	0f 45 c2             	cmovne %edx,%eax
}
  800cdd:	5b                   	pop    %ebx
  800cde:	5e                   	pop    %esi
  800cdf:	5f                   	pop    %edi
  800ce0:	5d                   	pop    %ebp
  800ce1:	c3                   	ret    

00800ce2 <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  800ce2:	55                   	push   %ebp
  800ce3:	89 e5                	mov    %esp,%ebp
  800ce5:	83 ec 08             	sub    $0x8,%esp
	int r;

	if (_pgfault_handler == 0) {
  800ce8:	83 3d 08 20 80 00 00 	cmpl   $0x0,0x802008
  800cef:	75 52                	jne    800d43 <set_pgfault_handler+0x61>
		// First time through!
		// LAB 4: Your code here.
		//panic("set_pgfault_handler not implemented");
		r = sys_page_alloc(0, (void *)(UXSTACKTOP - PGSIZE), PTE_U|PTE_W|PTE_P); 
  800cf1:	83 ec 04             	sub    $0x4,%esp
  800cf4:	6a 07                	push   $0x7
  800cf6:	68 00 f0 bf ee       	push   $0xeebff000
  800cfb:	6a 00                	push   $0x0
  800cfd:	e8 66 f4 ff ff       	call   800168 <sys_page_alloc>
		if (r < 0)
  800d02:	83 c4 10             	add    $0x10,%esp
  800d05:	85 c0                	test   %eax,%eax
  800d07:	79 12                	jns    800d1b <set_pgfault_handler+0x39>
			panic("sys_page_alloc: %e", r);
  800d09:	50                   	push   %eax
  800d0a:	68 84 12 80 00       	push   $0x801284
  800d0f:	6a 23                	push   $0x23
  800d11:	68 97 12 80 00       	push   $0x801297
  800d16:	e8 22 f6 ff ff       	call   80033d <_panic>
		if ((r = sys_env_set_pgfault_upcall(0, _pgfault_upcall)) < 0)
  800d1b:	83 ec 08             	sub    $0x8,%esp
  800d1e:	68 17 03 80 00       	push   $0x800317
  800d23:	6a 00                	push   $0x0
  800d25:	e8 47 f5 ff ff       	call   800271 <sys_env_set_pgfault_upcall>
  800d2a:	83 c4 10             	add    $0x10,%esp
  800d2d:	85 c0                	test   %eax,%eax
  800d2f:	79 12                	jns    800d43 <set_pgfault_handler+0x61>
			panic("sys_env_set_pgfault_upcall: %e", r);	
  800d31:	50                   	push   %eax
  800d32:	68 a8 12 80 00       	push   $0x8012a8
  800d37:	6a 25                	push   $0x25
  800d39:	68 97 12 80 00       	push   $0x801297
  800d3e:	e8 fa f5 ff ff       	call   80033d <_panic>
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  800d43:	8b 45 08             	mov    0x8(%ebp),%eax
  800d46:	a3 08 20 80 00       	mov    %eax,0x802008
}
  800d4b:	c9                   	leave  
  800d4c:	c3                   	ret    
  800d4d:	66 90                	xchg   %ax,%ax
  800d4f:	90                   	nop

00800d50 <__udivdi3>:
  800d50:	55                   	push   %ebp
  800d51:	57                   	push   %edi
  800d52:	56                   	push   %esi
  800d53:	53                   	push   %ebx
  800d54:	83 ec 1c             	sub    $0x1c,%esp
  800d57:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800d5b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800d5f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800d63:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800d67:	85 f6                	test   %esi,%esi
  800d69:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800d6d:	89 ca                	mov    %ecx,%edx
  800d6f:	89 f8                	mov    %edi,%eax
  800d71:	75 3d                	jne    800db0 <__udivdi3+0x60>
  800d73:	39 cf                	cmp    %ecx,%edi
  800d75:	0f 87 c5 00 00 00    	ja     800e40 <__udivdi3+0xf0>
  800d7b:	85 ff                	test   %edi,%edi
  800d7d:	89 fd                	mov    %edi,%ebp
  800d7f:	75 0b                	jne    800d8c <__udivdi3+0x3c>
  800d81:	b8 01 00 00 00       	mov    $0x1,%eax
  800d86:	31 d2                	xor    %edx,%edx
  800d88:	f7 f7                	div    %edi
  800d8a:	89 c5                	mov    %eax,%ebp
  800d8c:	89 c8                	mov    %ecx,%eax
  800d8e:	31 d2                	xor    %edx,%edx
  800d90:	f7 f5                	div    %ebp
  800d92:	89 c1                	mov    %eax,%ecx
  800d94:	89 d8                	mov    %ebx,%eax
  800d96:	89 cf                	mov    %ecx,%edi
  800d98:	f7 f5                	div    %ebp
  800d9a:	89 c3                	mov    %eax,%ebx
  800d9c:	89 d8                	mov    %ebx,%eax
  800d9e:	89 fa                	mov    %edi,%edx
  800da0:	83 c4 1c             	add    $0x1c,%esp
  800da3:	5b                   	pop    %ebx
  800da4:	5e                   	pop    %esi
  800da5:	5f                   	pop    %edi
  800da6:	5d                   	pop    %ebp
  800da7:	c3                   	ret    
  800da8:	90                   	nop
  800da9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800db0:	39 ce                	cmp    %ecx,%esi
  800db2:	77 74                	ja     800e28 <__udivdi3+0xd8>
  800db4:	0f bd fe             	bsr    %esi,%edi
  800db7:	83 f7 1f             	xor    $0x1f,%edi
  800dba:	0f 84 98 00 00 00    	je     800e58 <__udivdi3+0x108>
  800dc0:	bb 20 00 00 00       	mov    $0x20,%ebx
  800dc5:	89 f9                	mov    %edi,%ecx
  800dc7:	89 c5                	mov    %eax,%ebp
  800dc9:	29 fb                	sub    %edi,%ebx
  800dcb:	d3 e6                	shl    %cl,%esi
  800dcd:	89 d9                	mov    %ebx,%ecx
  800dcf:	d3 ed                	shr    %cl,%ebp
  800dd1:	89 f9                	mov    %edi,%ecx
  800dd3:	d3 e0                	shl    %cl,%eax
  800dd5:	09 ee                	or     %ebp,%esi
  800dd7:	89 d9                	mov    %ebx,%ecx
  800dd9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800ddd:	89 d5                	mov    %edx,%ebp
  800ddf:	8b 44 24 08          	mov    0x8(%esp),%eax
  800de3:	d3 ed                	shr    %cl,%ebp
  800de5:	89 f9                	mov    %edi,%ecx
  800de7:	d3 e2                	shl    %cl,%edx
  800de9:	89 d9                	mov    %ebx,%ecx
  800deb:	d3 e8                	shr    %cl,%eax
  800ded:	09 c2                	or     %eax,%edx
  800def:	89 d0                	mov    %edx,%eax
  800df1:	89 ea                	mov    %ebp,%edx
  800df3:	f7 f6                	div    %esi
  800df5:	89 d5                	mov    %edx,%ebp
  800df7:	89 c3                	mov    %eax,%ebx
  800df9:	f7 64 24 0c          	mull   0xc(%esp)
  800dfd:	39 d5                	cmp    %edx,%ebp
  800dff:	72 10                	jb     800e11 <__udivdi3+0xc1>
  800e01:	8b 74 24 08          	mov    0x8(%esp),%esi
  800e05:	89 f9                	mov    %edi,%ecx
  800e07:	d3 e6                	shl    %cl,%esi
  800e09:	39 c6                	cmp    %eax,%esi
  800e0b:	73 07                	jae    800e14 <__udivdi3+0xc4>
  800e0d:	39 d5                	cmp    %edx,%ebp
  800e0f:	75 03                	jne    800e14 <__udivdi3+0xc4>
  800e11:	83 eb 01             	sub    $0x1,%ebx
  800e14:	31 ff                	xor    %edi,%edi
  800e16:	89 d8                	mov    %ebx,%eax
  800e18:	89 fa                	mov    %edi,%edx
  800e1a:	83 c4 1c             	add    $0x1c,%esp
  800e1d:	5b                   	pop    %ebx
  800e1e:	5e                   	pop    %esi
  800e1f:	5f                   	pop    %edi
  800e20:	5d                   	pop    %ebp
  800e21:	c3                   	ret    
  800e22:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800e28:	31 ff                	xor    %edi,%edi
  800e2a:	31 db                	xor    %ebx,%ebx
  800e2c:	89 d8                	mov    %ebx,%eax
  800e2e:	89 fa                	mov    %edi,%edx
  800e30:	83 c4 1c             	add    $0x1c,%esp
  800e33:	5b                   	pop    %ebx
  800e34:	5e                   	pop    %esi
  800e35:	5f                   	pop    %edi
  800e36:	5d                   	pop    %ebp
  800e37:	c3                   	ret    
  800e38:	90                   	nop
  800e39:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800e40:	89 d8                	mov    %ebx,%eax
  800e42:	f7 f7                	div    %edi
  800e44:	31 ff                	xor    %edi,%edi
  800e46:	89 c3                	mov    %eax,%ebx
  800e48:	89 d8                	mov    %ebx,%eax
  800e4a:	89 fa                	mov    %edi,%edx
  800e4c:	83 c4 1c             	add    $0x1c,%esp
  800e4f:	5b                   	pop    %ebx
  800e50:	5e                   	pop    %esi
  800e51:	5f                   	pop    %edi
  800e52:	5d                   	pop    %ebp
  800e53:	c3                   	ret    
  800e54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e58:	39 ce                	cmp    %ecx,%esi
  800e5a:	72 0c                	jb     800e68 <__udivdi3+0x118>
  800e5c:	31 db                	xor    %ebx,%ebx
  800e5e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800e62:	0f 87 34 ff ff ff    	ja     800d9c <__udivdi3+0x4c>
  800e68:	bb 01 00 00 00       	mov    $0x1,%ebx
  800e6d:	e9 2a ff ff ff       	jmp    800d9c <__udivdi3+0x4c>
  800e72:	66 90                	xchg   %ax,%ax
  800e74:	66 90                	xchg   %ax,%ax
  800e76:	66 90                	xchg   %ax,%ax
  800e78:	66 90                	xchg   %ax,%ax
  800e7a:	66 90                	xchg   %ax,%ax
  800e7c:	66 90                	xchg   %ax,%ax
  800e7e:	66 90                	xchg   %ax,%ax

00800e80 <__umoddi3>:
  800e80:	55                   	push   %ebp
  800e81:	57                   	push   %edi
  800e82:	56                   	push   %esi
  800e83:	53                   	push   %ebx
  800e84:	83 ec 1c             	sub    $0x1c,%esp
  800e87:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800e8b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800e8f:	8b 74 24 34          	mov    0x34(%esp),%esi
  800e93:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800e97:	85 d2                	test   %edx,%edx
  800e99:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800e9d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800ea1:	89 f3                	mov    %esi,%ebx
  800ea3:	89 3c 24             	mov    %edi,(%esp)
  800ea6:	89 74 24 04          	mov    %esi,0x4(%esp)
  800eaa:	75 1c                	jne    800ec8 <__umoddi3+0x48>
  800eac:	39 f7                	cmp    %esi,%edi
  800eae:	76 50                	jbe    800f00 <__umoddi3+0x80>
  800eb0:	89 c8                	mov    %ecx,%eax
  800eb2:	89 f2                	mov    %esi,%edx
  800eb4:	f7 f7                	div    %edi
  800eb6:	89 d0                	mov    %edx,%eax
  800eb8:	31 d2                	xor    %edx,%edx
  800eba:	83 c4 1c             	add    $0x1c,%esp
  800ebd:	5b                   	pop    %ebx
  800ebe:	5e                   	pop    %esi
  800ebf:	5f                   	pop    %edi
  800ec0:	5d                   	pop    %ebp
  800ec1:	c3                   	ret    
  800ec2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800ec8:	39 f2                	cmp    %esi,%edx
  800eca:	89 d0                	mov    %edx,%eax
  800ecc:	77 52                	ja     800f20 <__umoddi3+0xa0>
  800ece:	0f bd ea             	bsr    %edx,%ebp
  800ed1:	83 f5 1f             	xor    $0x1f,%ebp
  800ed4:	75 5a                	jne    800f30 <__umoddi3+0xb0>
  800ed6:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800eda:	0f 82 e0 00 00 00    	jb     800fc0 <__umoddi3+0x140>
  800ee0:	39 0c 24             	cmp    %ecx,(%esp)
  800ee3:	0f 86 d7 00 00 00    	jbe    800fc0 <__umoddi3+0x140>
  800ee9:	8b 44 24 08          	mov    0x8(%esp),%eax
  800eed:	8b 54 24 04          	mov    0x4(%esp),%edx
  800ef1:	83 c4 1c             	add    $0x1c,%esp
  800ef4:	5b                   	pop    %ebx
  800ef5:	5e                   	pop    %esi
  800ef6:	5f                   	pop    %edi
  800ef7:	5d                   	pop    %ebp
  800ef8:	c3                   	ret    
  800ef9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800f00:	85 ff                	test   %edi,%edi
  800f02:	89 fd                	mov    %edi,%ebp
  800f04:	75 0b                	jne    800f11 <__umoddi3+0x91>
  800f06:	b8 01 00 00 00       	mov    $0x1,%eax
  800f0b:	31 d2                	xor    %edx,%edx
  800f0d:	f7 f7                	div    %edi
  800f0f:	89 c5                	mov    %eax,%ebp
  800f11:	89 f0                	mov    %esi,%eax
  800f13:	31 d2                	xor    %edx,%edx
  800f15:	f7 f5                	div    %ebp
  800f17:	89 c8                	mov    %ecx,%eax
  800f19:	f7 f5                	div    %ebp
  800f1b:	89 d0                	mov    %edx,%eax
  800f1d:	eb 99                	jmp    800eb8 <__umoddi3+0x38>
  800f1f:	90                   	nop
  800f20:	89 c8                	mov    %ecx,%eax
  800f22:	89 f2                	mov    %esi,%edx
  800f24:	83 c4 1c             	add    $0x1c,%esp
  800f27:	5b                   	pop    %ebx
  800f28:	5e                   	pop    %esi
  800f29:	5f                   	pop    %edi
  800f2a:	5d                   	pop    %ebp
  800f2b:	c3                   	ret    
  800f2c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f30:	8b 34 24             	mov    (%esp),%esi
  800f33:	bf 20 00 00 00       	mov    $0x20,%edi
  800f38:	89 e9                	mov    %ebp,%ecx
  800f3a:	29 ef                	sub    %ebp,%edi
  800f3c:	d3 e0                	shl    %cl,%eax
  800f3e:	89 f9                	mov    %edi,%ecx
  800f40:	89 f2                	mov    %esi,%edx
  800f42:	d3 ea                	shr    %cl,%edx
  800f44:	89 e9                	mov    %ebp,%ecx
  800f46:	09 c2                	or     %eax,%edx
  800f48:	89 d8                	mov    %ebx,%eax
  800f4a:	89 14 24             	mov    %edx,(%esp)
  800f4d:	89 f2                	mov    %esi,%edx
  800f4f:	d3 e2                	shl    %cl,%edx
  800f51:	89 f9                	mov    %edi,%ecx
  800f53:	89 54 24 04          	mov    %edx,0x4(%esp)
  800f57:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800f5b:	d3 e8                	shr    %cl,%eax
  800f5d:	89 e9                	mov    %ebp,%ecx
  800f5f:	89 c6                	mov    %eax,%esi
  800f61:	d3 e3                	shl    %cl,%ebx
  800f63:	89 f9                	mov    %edi,%ecx
  800f65:	89 d0                	mov    %edx,%eax
  800f67:	d3 e8                	shr    %cl,%eax
  800f69:	89 e9                	mov    %ebp,%ecx
  800f6b:	09 d8                	or     %ebx,%eax
  800f6d:	89 d3                	mov    %edx,%ebx
  800f6f:	89 f2                	mov    %esi,%edx
  800f71:	f7 34 24             	divl   (%esp)
  800f74:	89 d6                	mov    %edx,%esi
  800f76:	d3 e3                	shl    %cl,%ebx
  800f78:	f7 64 24 04          	mull   0x4(%esp)
  800f7c:	39 d6                	cmp    %edx,%esi
  800f7e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800f82:	89 d1                	mov    %edx,%ecx
  800f84:	89 c3                	mov    %eax,%ebx
  800f86:	72 08                	jb     800f90 <__umoddi3+0x110>
  800f88:	75 11                	jne    800f9b <__umoddi3+0x11b>
  800f8a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800f8e:	73 0b                	jae    800f9b <__umoddi3+0x11b>
  800f90:	2b 44 24 04          	sub    0x4(%esp),%eax
  800f94:	1b 14 24             	sbb    (%esp),%edx
  800f97:	89 d1                	mov    %edx,%ecx
  800f99:	89 c3                	mov    %eax,%ebx
  800f9b:	8b 54 24 08          	mov    0x8(%esp),%edx
  800f9f:	29 da                	sub    %ebx,%edx
  800fa1:	19 ce                	sbb    %ecx,%esi
  800fa3:	89 f9                	mov    %edi,%ecx
  800fa5:	89 f0                	mov    %esi,%eax
  800fa7:	d3 e0                	shl    %cl,%eax
  800fa9:	89 e9                	mov    %ebp,%ecx
  800fab:	d3 ea                	shr    %cl,%edx
  800fad:	89 e9                	mov    %ebp,%ecx
  800faf:	d3 ee                	shr    %cl,%esi
  800fb1:	09 d0                	or     %edx,%eax
  800fb3:	89 f2                	mov    %esi,%edx
  800fb5:	83 c4 1c             	add    $0x1c,%esp
  800fb8:	5b                   	pop    %ebx
  800fb9:	5e                   	pop    %esi
  800fba:	5f                   	pop    %edi
  800fbb:	5d                   	pop    %ebp
  800fbc:	c3                   	ret    
  800fbd:	8d 76 00             	lea    0x0(%esi),%esi
  800fc0:	29 f9                	sub    %edi,%ecx
  800fc2:	19 d6                	sbb    %edx,%esi
  800fc4:	89 74 24 04          	mov    %esi,0x4(%esp)
  800fc8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800fcc:	e9 18 ff ff ff       	jmp    800ee9 <__umoddi3+0x69>
