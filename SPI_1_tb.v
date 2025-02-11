`timescale 1ns / 1ps

module Master_FPGA_tb;

    // Inputs
    reg clk;
    reg rst;
    reg spi_miso;

    // Outputs
    wire spi_sck;
    wire amp_cs;
    wire ad_conv;
    wire amp_shdn;
    wire spi_mosi;
    wire spi_ss_b;
    wire dac_cs;
    wire sf_ce0;
    wire fpga_init_b;
    wire [13:0] adc_data1;
    wire [13:0] adc_data2;
    wire [15:0]channel1,channel2; 
    wire [5:0]adc_clk_count;
    reg [13:0] data1 = 14'b10101100111011;
    reg [13:0] data2 = 14'b11001010101100;
    integer spi_sck_cycle_count = 0;
    integer i;
    
    // Instantiate the Unit Under Test (UUT)
    Master_FPGA uut (
        .clk(clk),
        .rst(rst),
        .spi_miso(spi_miso),
        .spi_sck(spi_sck),
        .amp_cs(amp_cs),
        .ad_conv(ad_conv),
        .amp_shdn(amp_shdn),
        .spi_mosi(spi_mosi),
        .spi_ss_b(spi_ss_b),
        .dac_cs(dac_cs),
        .sf_ce0(sf_ce0),
        .fpga_init_b(fpga_init_b),
        .adc_data1(adc_data1),
        .adc_data2(adc_data2),
        .channel1(channel1),
        .channel2(channel2),
        .adc_clk_count(adc_clk_count)
    );

    // Clock generation (50 MHz)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;  // 50 MHz clock -> Period = 20 ns (10 ns high, 10 ns low)
    end

    // Testbench logic
    initial begin
        // Initial reset and stabilization
        rst = 1;
        spi_miso = 2'b0;
        
        #100;  // Wait 100 ns before deasserting reset
        rst = 0;

        // Count 50 spi_sck clock cycles
        @(posedge spi_sck);  // Wait for the first positive edge of spi_sck
        while (spi_sck_cycle_count < 50) begin
            @(posedge spi_sck);  // Wait for each positive edge
            spi_sck_cycle_count = spi_sck_cycle_count + 1;
        end
    end

    // Simulate MISO data transmission for Channel 1
    initial begin

        #2010 for (i = 13; i >= 0; i = i - 1) begin
            spi_miso = data1[i]; 
            @(posedge spi_sck); 
        end


        
        
        // Send the Channel 2 data (14 bits)
        #4070 for (i = 13; i >= 0; i = i - 1) begin
            spi_miso = data2[i];  
            @(posedge spi_sck);  
        end
    end

endmodule
