# My_frist_CPU_RV32I

用 SystemVerilog 从零实现的 **RV32I 单周期 CPU**，运行在 Xilinx Artix-7 上。

设计目标是能真正跑通 `riscv64-unknown-elf-gcc` 编译出来的程序，而不是只做几条手写指令的演示。
目前 CPU 核心、指令 ROM、数据 RAM 已完成，汇编与 C 两类程序均已通过行为仿真验证。

> 学习项目定位：优先保证「指令正确、可仿真、可综合、可上板」，不追求高性能与复杂微架构。

---

## 当前进度

| 阶段 | 状态 |
| --- | --- |
| CPU 核心（译码 / 控制 / 数据通路 / ALU / 寄存器堆 / PC / 立即数） | ✅ 完成 |
| 指令存储器 `rom.sv` | ✅ 完成 |
| 数据存储器 `ram.sv` | ✅ 完成 |
| 各子模块单元 testbench | ✅ 完成 |
| 汇编程序仿真测试（6 个） | ✅ 通过 |
| C 程序仿真测试（3 个，含启动代码 / `.data` / `.bss`） | ✅ 通过 |
| **UART 模块** | ⬜ 未开始 |
| **板级验证** | ⬜ 等 UART 完成后进行 |
| 非法指令处理、冗余逻辑清理 | ⬜ 待办 |

**当前验证锚点**：`Test/test_C/test_bubble.hex`（冒泡排序 + 十六进制拼装）已在 `sim/top_tb.sv`
顶层行为仿真中跑通，程序返回值出现在寄存器 `x31`，等于 `0x12345`。

---

## 设计规格

| 项目 | 内容 |
| --- | --- |
| ISA | RV32I（基础整数指令集） |
| 微架构 | 单周期（Single-Cycle），无流水线 |
| 目标器件 | Xilinx Artix-7 `xc7a35tfgg484-2` |
| 开发工具 | Vivado 2025.2.1 |
| 指令存储器 | 只读 LUTRAM + `$readmemh` 初始化，异步读（`rom.sv`） |
| 数据存储器 | LUTRAM，异步读 / 同步写 / 4 位字节使能（`ram.sv`） |
| 寄存器堆 | 2 读 1 写，`x0` 硬连线为 0，**不复位** |
| 顶层结构 | `top.sv` 平级例化 CPU、ROM、RAM |
| 复位 | 同步复位，`PC <= 0`，程序从 `0x0000_0000` 开始执行 |
| 外设 | 无（UART 待实现） |
| 中断 / 异常 / CSR | 无 |

### 存储器映射

| 区域 | 起始地址 | 容量 | 实现 |
| --- | --- | --- | --- |
| 指令 ROM | `0x0000_0000` | 8 KB（2048 × 32 bit） | `rtl/rom.sv`，无写端口 |
| 数据 RAM | `0x1000_0000` | 8 KB（2048 × 32 bit） | `rtl/ram.sv` |

地址映射由 `Test/*/linker.ld` 与 `rtl/ram.sv` 的 `RAM_BASE` 参数共同约定，
栈顶 `_stack_top = 0x1000_2000`。

### 支持的指令

- **R-type**：ADD / SUB / SLL / SLT / SLTU / XOR / SRL / SRA / OR / AND
- **I-type ALU**：ADDI / SLTI / SLTIU / XORI / ORI / ANDI / SLLI / SRLI / SRAI
- **Load**：LB / LH / LW / LBU / LHU
- **Store**：SB / SH / SW
- **Branch**：BEQ / BNE / BLT / BGE / BLTU / BGEU
- **Jump**：JAL / JALR
- **Upper immediate**：LUI / AUIPC

---

## 目录结构

```text
My_frist_CPU_RV32I_20260828/
├── My_frist_CPU_RV32I_20260828.xpr   # Vivado 工程（综合顶层 = top，仿真顶层 = top_tb）
├── rtl/                              # 设计源码
│   ├── cpu_pkg.sv
│   ├── top.sv
│   ├── cpu.sv
│   ├── decoder.sv
│   ├── controller.sv
│   ├── datapath.sv
│   ├── pc.sv
│   ├── imm_gen.sv
│   ├── regfile.sv
│   ├── alu.sv
│   ├── rom.sv
│   └── ram.sv
├── sim/                              # 仿真 testbench
│   ├── top_tb.sv                     # 顶层集成仿真（当前仿真顶层）
│   ├── alu_tb.sv
│   ├── regfile_tb.sv
│   ├── decoder_tb.sv
│   ├── controller_tb.sv
│   ├── imm_gen_tb.sv
│   └── pc_tb.sv
├── Test/                             # 测试程序（汇编 / C）与工具链构建脚本
│   ├── test_S/                       # 纯汇编测试：*.S + Makefile + linker.ld
│   └── test_C/                       # C 测试：*.c + start.S + Makefile + linker.ld
├── constraint/
│   └── top_v1.xdc                    # 目前仅约束 clk / rst
└── Plan/
    └── plan_dev.md                   # 开发计划与设计决策记录
```

### 层次结构

```text
top.sv
├── cpu.sv                  # 纯 CPU 核心，不含存储器
│   ├── decoder.sv          # 指令字段提取 + opcode 分类
│   ├── controller.sv       # 控制信号生成（含 R/I 型 ALU 子译码）
│   └── datapath.sv         # 数据通路
│       ├── pc.sv           # PC 寄存器
│       ├── imm_gen.sv      # I/S/B/U/J 立即数生成
│       ├── regfile.sv      # 寄存器堆
│       └── alu.sv          # 组合 ALU
├── rom.sv                  # 指令存储器（PC 直接作为字节地址输入）
└── ram.sv                  # 数据存储器
```

公共枚举与类型（`alu_op_t` / `imm_type_t` / `instr_type_t` / `mem_size_t` / `wb_sel_t` /
`branch_type_t` 等）统一定义在 `rtl/cpu_pkg.sv`，所有模块通过 `import cpu_pkg::*;` 使用。

---

## 关键设计说明

### 顶层把 CPU 与存储器平级例化

`top.sv` 只做例化与连线，CPU 核心不关心存储器是 LUTRAM 还是 BRAM：

- 各模块可单独仿真测试；
- 波形调试时在 `top` 层就能同时看到 `pc` / `instr` / `dmem_*`；
- 日后换成 BRAM 或接入总线 / 外设时，不需要改动 CPU 核心。

### ROM 用「只读 LUTRAM + 初始化」实现

FPGA 里没有物理 ROM，`rom.sv` 采用无写端口的 LUTRAM，在上电 / 仿真时清零后用
`$readmemh` 载入 `.hex`。程序镜像通过 `top.sv` 的 `PROGRAM_HEX` 参数传入，仿真时由
testbench 指定具体文件。

> 注意：`PROGRAM_HEX` 默认为空字符串。综合上板前必须把要运行的程序通过参数
> 或综合属性固化进去，否则 ROM 全为 `0x0000_0000`（等价于 `add x0, x0, x0`）。

### 数据 RAM 采用「异步读 + 同步写」

- **异步读**：保证单周期内 Load 能在同一周期拿到数据；
- **同步写**：写使能 + 时钟沿写入，避免毛刺；
- **字节使能**：`datapath.sv` 根据地址低位把 SB / SH 的数据对齐到正确的 byte lane，
  再由 `dmem_be` 选择写入哪些字节，`ram.sv` 内部按字节拆分写入。

### Load 数据的提取与扩展

RAM 返回一个完整 32 bit word，`datapath.sv` 依据 `dmem_addr[1:0]` 选出 byte / halfword，
再按 `mem_unsigned` 决定符号扩展（LB/LH）还是零扩展（LBU/LHU）。

---

## 仿真验证

### 1. 子模块单元测试

`sim/` 下的 testbench 针对单个模块做定向测试，均使用 `check` 任务 + `$error` 自动判定，
仿真日志里直接看 `[PASS]` / `[FAIL]`：

| testbench | 覆盖范围 |
| --- | --- |
| `alu_tb.sv` | 全部 ALU 操作、`zero` 标志、边界值 |
| `regfile_tb.sv` | 双端口读、写使能、`x0` 恒为 0 |
| `decoder_tb.sv` | 字段提取与 opcode 分类 |
| `controller_tb.sv` | 各指令类型的控制信号 |
| `imm_gen_tb.sv` | I/S/B/U/J 五种立即数格式（含负数边界） |
| `pc_tb.sv` | 复位与 `next_pc` 更新 |

### 2. 汇编测试（`Test/test_S/`）

6 个纯汇编程序，覆盖指令类型。它们**不含自检逻辑**，跑完后停在 `jal x0, loop` 死循环，
结论需要从波形或 `$monitor` 输出的寄存器值判断。

| 文件 | 覆盖内容 |
| --- | --- |
| `test_01_alu.S` | ADD/SUB/AND/OR/XOR、SLL/SRL/SRA（含负数）、SLT/SLTU |
| `test_02_imm.S` | 各 I 型立即数指令、立即数边界（-1 / 2047）、移位立即数 |
| `test_03_branch.S` | BEQ/BNE/BLT/BGE/BLTU/BGEU，用累积寄存器 `x10` 记录错误分支 |
| `test_04_jump.S` | JAL 跳转与 link 值、JALR 间接返回，最终 `x10 = 6` |
| `test_05_lui_auipc.S` | LUI 与 AUIPC（`x1 = 0x12345000`，`x2 = PC + 0x1000`） |
| `test_06_mem_word.S` | 在 `0x1000_0000` 附近的 SW / LW 读写与覆盖写 |

> `test_03_branch.S` 的技巧：`x10` 初值 0，每条分支若走错路径就加上一个错误码
> （1/2/4/8/16/32）。跑完后 `x10 = 0` 即全部正确。

### 3. C 测试（`Test/test_C/`）

C 程序需要启动代码，`start.S` 负责四件事：

1. 设置栈指针 `sp = _stack_top`；
2. 把 `.data` 段从 ROM 中的 LMA 拷贝到 RAM 中的 VMA；
3. 清零 `.bss` 段；
4. 调用 `main`，返回后把 `a0` 搬到 **`x31`** 作为返回码，然后死循环。

用 `x31` 当返回码是为了方便在 `$monitor` 里一眼看到结果而不必翻波形。

| 文件 | 测试内容 | 期望 `x31` |
| --- | --- | --- |
| `test_06_mem_word.c` | RAM 读写、覆盖写、`.data` 初值、`.bss` 清零 | `0x600D`（"GOOD"） |
| `test_bubble.c` | 冒泡排序 + 结果拼成十六进制数 | `0x12345` |
| `test_narc_v1.c` | 求 100~999 的水仙花数，返回最后一个 | `0x197`（407） |

`test_06_mem_word.c` 内部还有多个失败返回码（`0x1` / `0x2` / `0x3` / `0xBAD`），
用于定位是哪一步出错。

### 4. 顶层集成仿真

`sim/top_tb.sv` 例化 `top`，产生 100 MHz（周期 10 ns）时钟，复位 2 个时钟沿后释放，
跑固定周期数后 `$finish`，并用 `$monitor` 打印 PC、指令与若干寄存器：

```systemverilog
top #(
    .PROGRAM_HEX("../../../../Test/test_C/test_bubble.hex")
) u_top (...);
```

该相对路径是相对于 Vivado 的 xsim 运行目录
（`<工程>.sim/sim_1/behav/xsim/`）而言的，往上四级正好回到工程根目录。

> 冒泡排序需要较多周期，因此 `top_tb.sv` 里的等待周期数为 950000。
> 跑更小的程序时建议把它改小，避免仿真时间过长。

---

## 如何运行仿真

1. 用 Vivado 打开工程 `My_frist_CPU_RV32I_20260828.xpr`。
2. 生成要运行的程序镜像（见下一节），例如 `Test/test_C/test_bubble.hex`。
3. 修改 `sim/top_tb.sv` 中 `PROGRAM_HEX` 的路径，指向目标 `.hex` 文件。
4. 确认仿真顶层是 `top_tb`，然后 **Run Behavioral Simulation**。
5. 观察 `$monitor` 输出与波形：
   - 汇编测试看对应寄存器（如 `test_04_jump` 的 `x10` 应为 6）；
   - C 测试看 `x31` 返回码。

工程中所有源码都以相对路径 `$PPRDIR/rtl/...`、`$PPRDIR/sim/...` 引用，
文件本身不需要复制进 `srcs/`。

---

## 如何编译出自己的测试程序

工具链使用 `riscv64-unknown-elf-`（`-march=rv32i -mabi=ilp32`）。

### 汇编程序

```bash
cd Test/test_S
make                 # 由 *.S 生成 *.elf 与 *.hex
```

### C 程序

```bash
cd Test/test_C
make                 # start.S + test_*.c -> *.elf -> *.hex
```

Makefile 中的关键选项：`-nostdlib -nostartfiles -ffreestanding -fno-builtin -fno-common -Os -Wall`，
并链接 `-lgcc`。链接脚本 `linker.ld` 描述 ROM / RAM 两段地址空间，
并导出 `_data_lma` / `_data_start` / `_data_end` / `_bss_start` / `_bss_end` / `_stack_top`
供 `start.S` 使用。

### 转换格式

```bash
riscv64-unknown-elf-objcopy -O verilog --verilog-data-width 4 program.elf program.hex
```

`--verilog-data-width 4` 输出的是每行 4 字节、可直接被 `$readmemh` 加载的格式：

```text
@00000000
00500093 00300113 002081B3 00302023
00002203 00000000
```

`@` 行给出起始字节地址，因此程序必须链接到 `0x0000_0000`。

---

## 综合与上板

- Vivado 工程中综合顶层为 `top`，约束文件为 `constraint/top_v1.xdc`；
- 当前约束只定义了 `clk`（`V4`）与 `rst`（`U7`）两个引脚，均为 LVCMOS33；
- **上板验证尚未进行**：需要先完成 UART 模块，把程序运行结果输出到串口，
  才能形成可观测的板级闭环。

上板前的必要工作：

1. 实现 UART 发送模块（后续可再加接收），并映射到板上的串口引脚；
2. 让程序通过 UART 输出结果（替代现在仅用于仿真的 `x31` 返回码约定）；
3. 把程序镜像固化进 `rom`（`PROGRAM_HEX` 参数或综合属性），而不是依赖 testbench 传参；
4. 补齐时钟 / 复位 / 串口引脚的完整约束。

---

## 已知限制

- **无非法指令处理**：未识别 opcode 归为 `INST_INVALID`，控制器输出全默认值，
  行为等价于空操作，不产生异常或 trap。
- **不对齐访问不报错**：非对齐的 LW / SW 在 `datapath.sv` 中被直接判为无效（读出 0 / 不写入），
  不会触发异常。SH / LH 只支持自然对齐。
- **寄存器堆无复位**：`regfile.sv` 没有复位端口，依赖 `x0` 恒 0 与程序自身初始化。
- **ROM 无地址越界保护**：`rom.sv` 的读地址只取低位，PC 越界会回绕到存储器内部。
- **单周期、无流水线**，且没有中断、异常与 CSR，不能运行需要特权态的程序。
- **暂无 UART 等外设**，仿真结果只能通过寄存器 / 波形观察。

---

## 后续计划

1. 实现 UART 模块，打通板级输出；
2. 在 `xc7a35tfgg484-2` 上综合、实现、生成比特流并上板验证；
3. 补充 `ram_tb.sv` 与更完整的 CPU 回归测试，为顶层 testbench 增加自动断言；
4. 增加非法指令、保留编码等防御性处理；
5. 清理冗余逻辑与遗留文件（如 `rtl/ram.sv.bak`、`Test/test_C/Makefile*.txt` 等）；
6. 视资源占用决定是否把 LUTRAM 换成 BRAM，并引入简单的总线 / 外设接口。

---

## 说明

本项目是作者自学 FPGA 与计算机组成原理的练习项目，代码以清晰、可读、可仿真为主要目标，
难免存在不完善之处，欢迎交流指正。
