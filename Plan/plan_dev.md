# RV32I 单周期 CPU 开发计划（修订版 v2）

## 项目概述

本项目以学习 FPGA 与数字逻辑设计为目的，从零实现一个可运行
`riscv32-unknown-elf-gcc` 编译产物的 RV32I 单周期 CPU。

项目定位：

- 不做“课程作业式”的空壳 CPU；
- 不追求高性能与复杂微架构；
- 优先保证指令正确、可仿真、可综合、可上板运行；
- 在成功运行真实编译产物后，再回头做精简、校验与优化。

---

## 设计基线

| 项目 | 决策 |
|---|---|
| ISA | RV32I |
| 微架构 | 单周期 |
| 目标器件 | Xilinx Artix-7 XC7A35T |
| 指令存储器 | 不单独实现“物理 ROM”，用 LUTRAM 初始化 `.hex`（`rom.sv`） |
| 数据存储器 | LUTRAM，异步读、同步写、支持字节使能（`ram.sv`） |
| 顶层结构 | `top.sv` 平级例化 CPU、指令 ROM、数据 RAM |
| 寄存器堆 | 不复位，x0 硬连线为 0 |
| 非法指令校验 | 当前阶段不做，后续补充 |
| 冗余逻辑清理 | 当前阶段不做，跑通后统一重构 |

---

## 目标与里程碑

### M1：基础数据通路跑通 ✅

- [x] 完成 ALU、RegFile、Decoder、ImmGen、Controller、PC。
- [x] 完成简单指令的逐模块仿真。

### M2：完整 CPU 可运行 ✅（手写程序已跑通）

- [x] 完成 `cpu.sv`：例化 Decoder、Controller、Datapath。
- [x] 完成指令存储器 `rom.sv`：LUTRAM + `.hex` 初始化，异步只读。
- [x] 完成数据存储器 `ram.sv`：LUTRAM，异步读、同步写、字节使能。
- [x] 完成 `top.sv`：顶层平级例化 CPU、ROM、RAM。
- [x] 完成 `sim/top_tb.sv` 并跑通第一个手写小程序。
- [x] 验证基础指令通路：ADDI、ADD、SW、LW 等。
- [ ] 运行由 `riscv32-unknown-elf-gcc` 编译的真实程序。

M2 覆盖的指令类型（设计中已支持，仍需更完整测试）：

- R-type
- I-type ALU
- Load / Store（LB/LH/LW/LBU/LHU/SB/SH/SW）
- Branch（BEQ/BNE/BLT/BGE/BLTU/BGEU）
- JAL / JALR
- LUI / AUIPC

### M3：设计与代码整理

- [ ] 清理冗余数据通路与控制逻辑。
- [ ] 增加非法指令、保留编码等防御性处理。
- [ ] 完善 testbench 与回归测试。
- [ ] 综合 / 上板验证。

---

## 当前进度

### 已完成

- [x] `cpu_pkg.sv`：全局类型与枚举定义
- [x] `alu.sv`：组合 ALU
- [x] `regfile.sv`：2R1W 寄存器堆，x0 只读为 0
- [x] `decoder.sv`：指令字段提取与 opcode 分类
- [x] `controller.sv`：控制信号生成
- [x] `pc.sv`：PC 寄存器
- [x] `imm_gen.sv`：I/S/B/U/J 立即数生成
- [x] `datapath.sv`：数据通路
- [x] `rom.sv`：指令存储器（LUTRAM + `.hex` 初始化）
- [x] `ram.sv`：数据存储器（异步读、同步写、字节使能）
- [x] `cpu.sv`：CPU 核心例化与连线
- [x] `top.sv`：顶层例化 CPU / ROM / RAM
- [x] `sim/top_tb.sv`：顶层仿真 testbench
- [x] 顶层行为仿真通过第一个小程序
- [x] 整理出 `README.md` 与 `.gitignore`

### 未完成 / 待办

- [ ] 运行第一个 gcc 编译产物
- [ ] `ram_tb.sv`：数据存储器定向测试
- [ ] `cpu_tb.sv` / 更完整的 CPU 回归测试
- [ ] Branch / JAL / JALR / LUI / AUIPC / Load-Store 全类型覆盖测试
- [ ] `top_tb.sv` 增加自动断言（不只看波形）
- [ ] 综合、实现、上板
- [ ] 非法指令处理
- [ ] 冗余逻辑清理

---

## 设计决策记录

### D1：单周期 + LUTRAM

为尽快看到可运行 CPU，采用单周期架构。

XC7A35T 的 LUTRAM 官方上限约为 **400 Kb（≈ 50 KB）**。
实际使用中需为 CPU 逻辑保留资源，因此建议初始容量：

```text
指令 LUTRAM：8 KB（约 2048 条指令）
数据 LUTRAM：8 KB
合计：16 KB（约 128 Kb）
```

### D2：顶层采用“CPU 与存储器平级例化”

`top.sv` 中平级例化：

```text
top.sv
├── cpu.sv（纯核心，不含存储器）
├── rom.sv（指令存储器）
└── ram.sv（数据存储器）
```

优点：

- 各模块可单独测试；
- 波形调试时在 top 层直接看到 `pc/instr/dmem_*`；
- 以后更换存储器类型、增加外设/总线时不需要改 CPU 核心。

### D3：ROM 用“只读 LUTRAM + 初始化”实现

FPGA 中没有物理“只读 ROM”，采用上电/仿真初始化 + 无写端口的 LUTRAM 充当 ROM，
符合 FPGA 实际做法，也便于仿真加载 `.hex`。

### D4：数据 RAM 采用“异步读 + 同步写”

- 异步读：保证单周期内 Load 能拿到数据；
- 同步写：写使能 + 时钟沿写入，避免毛刺；
- 字节使能：配合 SB/SH/SW 部分写入。

---

## 下一步建议

1. 用 gcc 编译一个稍大的 C 程序并生成 `.hex`，验证真实编译产物；
2. 补 `ram_tb.sv`、`cpu_tb.sv` 与自动断言；
3. 覆盖 Branch/JAL/JALR/LUI/AUIPC/Load-Store 全指令；
4. 跑综合，观察 LUT/存储资源占用；
5. 上板前补约束文件，并规划简单的 LED / UART 结果展示。
