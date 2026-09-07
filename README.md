# My_first_CPU_RV32I

一个用于学习 FPGA 与数字逻辑的 **RV32I 单周期 CPU** 项目。

从零实现了一个可以运行 `riscv32-unknown-elf-gcc` 编译产物的最小 RISC-V 处理器，
并已在 Vivado 行为仿真中跑通第一个小程序。

> 本项目定位为学习项目，优先保证“指令正确、可仿真、可综合、可上板”，
> 不追求高性能与复杂微架构。

---

## 功能特性

- ISA：RV32I 基础整数指令集
- 微架构：单周期（Single-Cycle）
- 指令类型支持：
  - R-type
  - I-type ALU
  - Load / Store（LB/LH/LW/LBU/LHU/SB/SH/SW）
  - Branch（BEQ/BNE/BLT/BGE/BLTU/BGEU）
  - JAL / JALR
  - LUI / AUIPC
- 寄存器堆：2 读 1 写，`x0` 硬连线为 0，无复位
- 指令存储器：LUTRAM + `.hex` 初始化（等效 ROM）
- 数据存储器：LUTRAM，异步读、同步写、支持字节使能
- 存储器与 CPU 在顶层平级例化，便于单独测试与后续扩展

---

## 整体结构

```text
top.sv
├── cpu.sv              # CPU 核心（decoder + controller + datapath）
│   ├── decoder.sv      # 指令字段提取与指令类型译码
│   ├── controller.sv   # 控制信号生成
│   └── datapath.sv     # 数据通路
│       ├── pc.sv       # PC 寄存器
│       ├── imm_gen.sv  # 立即数生成
│       ├── regfile.sv  # 寄存器堆
│       └── alu.sv      # 组合 ALU
├── rom.sv              # 指令存储器（只读，异步读，加载 program.hex）
└── ram.sv              # 数据存储器（同步写，异步读，字节使能）
```

公共类型定义在 `rtl/cpu_pkg.sv` 中。

---

## 文件说明

| 文件 | 说明 |
|---|---|
| `rtl/cpu_pkg.sv` | 全局枚举/类型定义 |
| `rtl/top.sv` | 顶层，例化 CPU、ROM、RAM |
| `rtl/cpu.sv` | CPU 核心封装 |
| `rtl/datapath.sv` | 数据通路 |
| `rtl/rom.sv` | 指令存储器 |
| `rtl/ram.sv` | 数据存储器 |
| `program.hex` | 仿真用指令初始文件 |
| `sim/top_tb.sv` | 顶层仿真 testbench |
| `sim/*_tb.sv` | 各子模块 testbench |

---

## 环境

- Vivado 2025.2
- 目标器件：Xilinx Artix-7 XC7A35T（当前以仿真验证为主）

---

## 如何仿真

1. 用 Vivado 打开工程 `My_frist_CPU_RV32I_20260828.xpr`；
2. 确认以下文件已被加入工程：
   - `rtl/` 下所有 `.sv`
   - `sim/top_tb.sv`
3. 将 `sim/top_tb.sv` 设为 **Simulation Top**；
4. 确认 `program.hex` 路径：
   - 工程中 `top.sv` 的 `rom` 例化使用 `HEX_FILE` 指定文件；
   - 若报找不到文件，请改成绝对路径；
5. 点击 **Run Behavioral Simulation**。

预期结果（对应当前 `program.hex`）：

```asm
addi x1, x0, 5     # x1 = 5
addi x2, x0, 3     # x2 = 3
add  x3, x1, x2    # x3 = 8
sw   x3, 0(x0)     # mem[0] = 8
lw   x4, 0(x0)     # x4 = 8
```

仿真结束后应观察到：

```text
x1 = 5
x2 = 3
x3 = 8
x4 = 8
```

---

## 如何生成自己的 `program.hex`

1. 编写 C/汇编程序；
2. 使用 RISC-V 工具链编译并链接到起始地址 `0x00000000`；
3. 用 `objcopy` 转成 Verilog 可加载的 hex：

```bash
riscv32-unknown-elf-objcopy -O verilog your_program.elf program.hex
```

或手动按以下格式编写：

```text
@00000000
00500093
00300113
002081B3
00302023
00002203
```

---

## 当前进度

- [x] ALU
- [x] 寄存器堆
- [x] 译码器 / 控制器
- [x] 立即数生成
- [x] PC
- [x] 数据通路
- [x] 指令 ROM（LUTRAM + hex）
- [x] 数据 RAM
- [x] CPU 顶层例化
- [x] 顶层行为仿真通过（第一个小程序）
- [ ] 更完整的指令回归测试
- [ ] 综合 / 上板验证
- [ ] 非法指令处理
- [ ] 代码整理与冗余清理

---

## 后续计划

- 补充更全面的 testbench 与指令回归测试
- 在 XC7A35T 上综合、上板运行
- 视资源情况将 LUTRAM 替换为 BRAM
- 增加非法指令、保留编码等防御性处理
- 增加简单的总线/外设接口，为后续学习打基础

---

## 说明

本项目是作者自学 FPGA 与计算机组成原理的练习项目，
代码以清晰、可读、可仿真为主要目标，可能存在不完善之处，欢迎交流指正。
