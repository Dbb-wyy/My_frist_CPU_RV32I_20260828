`timescale 1ns / 1ps

module uart_tx_tb;

    //============================================================
    // 1. 测试参数
    //============================================================

    // 测试时钟：1 MHz，即时钟周期 1000 ns
    localparam integer CLK_FREQ_HZ = 1_000_000;

    // 测试波特率：100000 baud
    // 每个 UART bit 需要 1_000_000 / 100_000 = 10 个时钟周期
    localparam integer BAUD_RATE = 100_000;

    localparam integer CLKS_PER_BIT = CLK_FREQ_HZ / BAUD_RATE;

    //============================================================
    // 2. 连接 UART TX 模块的测试信号
    //============================================================

    logic       clk;
    logic       rst;

    logic       txdata_we;   // 写发送数据寄存器的使能
    logic [7:0] txdata;      // 要发送的 8 位数据

    logic       txe;         // 发送数据寄存器可写
    logic       tc;          // 当前发送全部完成
    logic       tx;          // UART 串行发送引脚

    // 本次测试发送的数据：1010_0101
    // UART 按最低位优先发送：1、0、1、0、0、1、0、1
    logic [7:0] test_data;

    integer i;

    //============================================================
    // 3. 实例化待测模块 uart_tx
    //============================================================

    uart_tx #(
        .CLK_FREQ_HZ (CLK_FREQ_HZ),
        .BAUD_RATE   (BAUD_RATE)
    ) u_uart_tx (
        .clk        (clk),
        .rst        (rst),
        .txdata_we  (txdata_we),
        .txdata     (txdata),
        .txe        (txe),
        .tc         (tc),
        .tx         (tx)
    );

    //============================================================
    // 4. 产生时钟
    //============================================================

    // 时钟周期 = 10 ns，频率 = 100 MHz
    //
    // 注意：
    // 这里的实际仿真时钟周期是 10 ns。
    // UART 模块内部使用参数 CLK_FREQ_HZ 计算波特率分频。
    // 因此，参数必须和实际仿真时钟频率匹配！
    //
    // 为了让 1 MHz 参数正确，下面改用 500 ns 半周期。
    always #500 clk = ~clk;

    //============================================================
    // 5. 检查指定 UART bit 的任务
    //============================================================

    // 等待指定 bit 的采样中心，然后检查 TX 电平。
    //
    // UART 每个 bit 持续 CLKS_PER_BIT 个时钟周期。
    // 从起始位下降沿开始：
    //   半个 bit 周期后采样起始位；
    //   再经过一个 bit 周期，采样数据位 0；
    //   依此类推。
    task automatic check_uart_bit(
        input logic expected_bit,
        input integer bit_index
    );
        begin
            repeat (CLKS_PER_BIT) @(posedge clk);

            // 避免与 DUT 在同一时钟沿的非阻塞赋值发生竞争
            #1;

            if (tx !== expected_bit) begin
                $error(
                    "UART bit check failed: bit_index=%0d, expected=%b, actual=%b, time=%0t",
                    bit_index, expected_bit, tx, $time
                );
                $fatal(1, "UART TX test FAILED");
            end
            else begin
                $display(
                    "PASS: bit_index=%0d, value=%b, time=%0t",
                    bit_index, tx, $time
                );
            end
        end
    endtask

    //============================================================
    // 6. 测试流程
    //============================================================

    initial begin
        $display("========================================");
        $display("       UART TX Testbench Started");
        $display("========================================");

        // 初始化所有输入
        clk       = 1'b0;
        rst       = 1'b1;
        txdata_we = 1'b0;
        txdata    = 8'h00;
        test_data = 8'hA5;

        // -------------------------------------------------------
        // 测试 1：复位状态
        // -------------------------------------------------------

        repeat (5) @(negedge clk);
        #1;

        if (tx !== 1'b1) begin
            $fatal(1, "FAIL: TX should be HIGH during reset");
        end

        if (txe !== 1'b1) begin
            $fatal(1, "FAIL: TXE should be HIGH after reset");
        end

        if (tc !== 1'b1) begin
            $fatal(1, "FAIL: TC should be HIGH after reset");
        end

        $display("PASS: Reset state");

        // 解除复位
        @(negedge clk);
        rst = 1'b0;

        repeat (2) @(negedge clk);

        // -------------------------------------------------------
        // 测试 2：写入待发送数据
        // -------------------------------------------------------

        // 等待发送数据寄存器可以接收数据
        wait (txe === 1'b1);

        // 在下降沿设置数据，留出建立时间
        @(negedge clk);
        txdata    = test_data;
        txdata_we = 1'b1;

        // 保持一个时钟周期的写使能
        @(negedge clk);
        txdata_we = 1'b0;

        $display(
            "INFO: Wrote TX data = 0x%02h at time %0t",
            test_data, $time
        );

        // -------------------------------------------------------
        // 测试 3：检测起始位
        // -------------------------------------------------------

        // UART 空闲时 TX 为高电平。
        // 开始发送时，TX 应从高电平跳变为低电平。
        @(negedge tx);

        $display("INFO: Start bit detected at time %0t", $time);

        // 起始位在下降沿之后持续一个 bit 周期。
        // 在半个 bit 周期处采样起始位。
        repeat (CLKS_PER_BIT / 2) @(posedge clk);
        #1;

        if (tx !== 1'b0) begin
            $fatal(1, "FAIL: Start bit should be LOW");
        end

        $display("PASS: Start bit = 0");

        // -------------------------------------------------------
        // 测试 4：检查 8 个数据位
        // -------------------------------------------------------

        // 注意：UART 是最低有效位（LSB）先发送。
        for (i = 0; i < 8; i = i + 1) begin
            // 从起始位中心走到下一个 bit 的中心，
            // 每次跨越一个完整 bit 周期。
            repeat (CLKS_PER_BIT) @(posedge clk);
            #1;

            if (tx !== test_data[i]) begin
                $error(
                    "FAIL: Data bit %0d, expected=%b, actual=%b",
                    i, test_data[i], tx
                );
                $fatal(1, "UART TX test FAILED");
            end

            $display(
                "PASS: Data bit %0d = %b",
                i, tx
            );
        end

        // -------------------------------------------------------
        // 测试 5：检查停止位
        // -------------------------------------------------------

        // 数据位 7 的采样点之后，再过一个 bit 周期，
        // 应当到达停止位的中心。
        repeat (CLKS_PER_BIT) @(posedge clk);
        #1;

        if (tx !== 1'b1) begin
            $fatal(1, "FAIL: Stop bit should be HIGH");
        end

        $display("PASS: Stop bit = 1");

        // -------------------------------------------------------
        // 测试 6：检查发送完成状态
        // -------------------------------------------------------

        // 等待 TC 拉高，设置超时防止仿真一直卡住。
        fork
            begin
                wait (tc === 1'b1);
            end

            begin
                repeat (CLKS_PER_BIT * 3) @(posedge clk);
                #1;

                if (tc !== 1'b1) begin
                    $fatal(
                        1,
                        "FAIL: Timeout waiting for TC to become HIGH"
                    );
                end
            end
        join_any

        disable fork;

        #1;

        if (txe !== 1'b1) begin
            $fatal(1, "FAIL: TXE should be HIGH after transmission");
        end

        if (tc !== 1'b1) begin
            $fatal(1, "FAIL: TC should be HIGH after transmission");
        end

        if (tx !== 1'b1) begin
            $fatal(1, "FAIL: TX should return to idle HIGH");
        end

        $display("PASS: TXE = 1");
        $display("PASS: TC  = 1");
        $display("PASS: TX returns to idle HIGH");

        // -------------------------------------------------------
        // 全部测试通过
        // -------------------------------------------------------

        $display("========================================");
        $display("       ALL UART TX TESTS PASSED");
        $display("========================================");

        $finish;
    end

    //============================================================
    // 7. 全局仿真超时保护
    //============================================================

    // 如果模块卡死或没有产生预期的 TX 下降沿，
    // 避免仿真无限运行。
    initial begin
        #100_000_000;
        $fatal(1, "FAIL: Global simulation timeout");
    end

endmodule