//串口传图顶层模块
module UART_RAM_TFT (
input wire clk,
input wire rst_n,
input wire uart_rx,
output wire [15:0] TFT_RGB,
output wire HSYC,
output wire VSYC,
output wire TFT_DE,
output wire TFT_BL,
output wire TFT_CLK,
output wire LED

);
wire CLK_TFT;
wire ram_data_en;
wire data_req;
wire locked;
wire rx_done;
wire [7:0] data_out;
wire [7:0] rx_data;

wire ram_wren;
wire [15:0] ram_wraddr;
wire [15:0] ram_wrdata;

wire [10:0] h_cnt;
wire [10:0] v_cnt;

reg [15:0] ram_rdaddr;
wire [15:0] ram_rddata;
wire [15:0] disp_data;

    uart_rx uart_rx_u(
        .clk(clk),
        .rst_n(rst_n),
        .uart_rx(uart_rx),
        .data_out(data_out),
        .rx_done_flag(rx_done)
    );

    rx_wr_ctrl rx_wr_ctrl_u(
        .clk(clk),
        .rst_n(rst_n),
        .rx_data(data_out),
        .rx_done(rx_done),
        .ram_wren(ram_wren),         
        .ram_wraddr(ram_wraddr),
        .ram_wrdata(ram_wrdata),
        .LED(LED)
    );

    RAM_VGA_CTRL RAM_VGA_CTRL_u(
        .clk_33M(TFT_CLK),         
        .rst_n(rst_n),
        .data_in(disp_data),
        .data_req(data_req),
        .h_cnt(h_cnt),   
        .v_cnt(v_cnt),   
        .HSYC(HSYC),           
        .VSYC(VSYC),           
        .TFT_DE(TFT_DE),         
        .TFT_CLK(CLK_TFT),
        .TFT_DATA(TFT_RGB),
        .TFT_BL(TFT_BL)     
    );

      clk_wiz_0 instance_name
   (
        .clk_out1(TFT_CLK),    
        .reset(!rst_n), 
        .locked(locked),      
        .clk_in1(clk)
        );      

    blk_mem_gen_0 RAM (
        .clka(clk),   
        .ena(1),      
        .wea(ram_wren),      
        .addra(ram_wraddr),  
        .dina(ram_wrdata),    
        .clkb(TFT_CLK),   
        .enb(1),      
        .addrb(ram_rdaddr), 
        .doutb(ram_rddata)  
    );

//RAM读控制逻辑
always @(posedge TFT_CLK or negedge rst_n) 
begin
    if (!rst_n) 
    begin
        ram_rdaddr<=0;    
    end    
    else if (ram_data_en) 
    begin
        ram_rdaddr<=ram_rdaddr+1;    
    end
end

assign ram_data_en=data_req&&(h_cnt>=272&&h_cnt<528)&&(v_cnt>=112&&v_cnt<368);
assign disp_data=ram_data_en? ram_rddata:0 ;

endmodule