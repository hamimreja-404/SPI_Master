module Master_FPGA(
    input clk, rst,
    input  spi_miso,AMP_DOUT,
    output reg amp_cs, ad_conv, amp_shdn, spi_mosi,
    output reg spi_sck,  // Divided clock for SPI communication
    output reg spi_ss_b = 1, dac_cs = 1, sf_ce0 = 1, fpga_init_b = 0, // Disabling all peripherals of FPGA
    output reg [13:0] adc_data1, adc_data2, // ADC data 1
    output reg [15:0] channel1 = 16'b0,channel2=16'b0,      // 16-bit ADC data including 2 high impedance bits
    output reg [5:0] adc_clk_count
);

/*    reg [5:0] adc_clk_count;      // 34 Clock for ADC input*/
    reg [7:0] gain = 8'b00010001; // gain of the amplifiers (A-Gain, B-Gain)
    reg [3:0] gain_count = 8;
    reg [4:0] adc_bit_count;
    reg [5:0] state;

    reg [3:0] clk_div_count = 0;  // Clock divider counter for 50 MHz to 14 MHz
    reg spi_sck_en = 0;           // SPI clock enable signal

    
    

    // Clock divider for generating 14 MHz SPI clock from 50 MHz input clock
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_div_count <= 0;
            spi_sck <= 0;
        end else begin
            if (clk_div_count == 3) begin 
                spi_sck <= ~spi_sck;
                clk_div_count <= 0;
            end else begin
                clk_div_count <= clk_div_count + 1;
            end
        end
    end
    always @(posedge spi_sck or posedge rst)
        if(rst)
            adc_clk_count<=0;
        else
        adc_clk_count <= adc_clk_count+1'b1;
    // State machine for controlling SPI and ADC
    always @(posedge spi_sck or posedge rst) begin
        if (rst) begin
            amp_cs <= 1;
            amp_shdn <= 0;
            spi_mosi <= 0;
            ad_conv <= 0;
            state <= 6'd1;
            gain_count <= 8;
        end else begin
            case (state)
                1: begin
                    amp_cs <= 0;  // Select amplifier
                    state <= 6'd2;
                    spi_sck <= 0;
                end
                2: begin
                    // Transmit gain(one bit per spi_sck cycle)
                    if(gain_count >0) begin
                    spi_sck <= 1;
                    amp_shdn <= 0;
                    spi_mosi <= gain[gain_count - 1];
                    gain_count <= gain_count - 1;
                    end
                    else if(gain_count == 0)
                        amp_cs<= 1;
                    state <= (gain_count > 0) ? 6'd2 : 6'd3;
                end
                3: begin
                    spi_mosi <= gain[0];
                    amp_cs <= 1;  
                    spi_sck <= 0;
                    state <= 6'd6; 
                end
                6: begin
                    spi_sck <=0;
                    ad_conv <= 1;  
                    state <= 6'd7;
                end
                7: begin
                    spi_sck <= 0;
                    ad_conv <= 0; 
                    adc_bit_count <= 14;
                    state <= 6'd8;
                end
                8: begin
                    spi_sck <= 1;
                    state <= 6'd9;  
                end
                9: begin
                    if(adc_clk_count > 13 && adc_clk_count <30) begin
                        adc_data1[adc_bit_count - 1] <= spi_miso; 
                        adc_bit_count <= adc_bit_count -1'b1;      
                    end else begin
                        channel1 <= {2'b0, adc_data1[13:0]};       
                        adc_bit_count <= 14;
                        state <= 6'd10;                            
                    end
                end
                
                10: begin
                    if(adc_clk_count > 30 && adc_clk_count <45) begin
                        adc_data2[adc_bit_count - 1] <= spi_miso;  
                        adc_bit_count <= adc_bit_count -1'b1;      
                    end else begin
                        channel2 <= {2'b0, adc_data2[13:0]};       
                        adc_bit_count <= 14;
                       state <=6'd11;
                    end
                end 
                11: begin
                    ad_conv <= 1;
                end

            endcase
        end
    end
endmodule

