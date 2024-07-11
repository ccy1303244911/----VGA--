//串口接收模块uart_rx和RAM写入模块ram_wr的控制器
module rx_wr_ctrl(
input wire clk,
input wire rst_n,
input wire [7:0] rx_data,
input wire rx_done,
output reg ram_wren,            //写使能
output reg [15:0] ram_wraddr,   //ram写地址
output reg [15:0] ram_wrdata,   //ram写数据
output reg LED
);

reg [16:0] data_cnt;        //串口接收数据次数寄存器
reg [15:0] rx_data_tmp;     //串口接收数据暂存器，每接收两次读入一次

always @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) 
    begin
        data_cnt<=0;    
    end    
    else if (rx_done)   //每发送完毕一次计数一次，
    begin
        data_cnt<=data_cnt+1;    
    end
end
//串口接收数据寄存器rx_data_tmp
always @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) 
    begin
        rx_data_tmp<=0;    
    end    
    else if (rx_done)  
    begin
        rx_data_tmp<={rx_data_tmp[7:0],rx_data}; //每组八位信号，每接受完一次移位一次
    end
end

//RAM写使能信号 ram_wren
always @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) 
    begin
        ram_wren<=0;    
    end
    else if (rx_done&&data_cnt[0]) //每接受完两次数据后ram读使能拉高，此时数据计数器最低为为1
    begin
        ram_wren<=1;    
    end
    else
        ram_wren<=0;
end

//产生RAM写地址
always @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) 
    begin
        ram_wraddr<=0;    
    end    
    else if (rx_done&&data_cnt[0]) 
    begin
        ram_wraddr<=data_cnt[16:1];  //地址数为接收次数除以2  
    end
end

//将串口数据写入RAM
always @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) 
    begin
        ram_wrdata<=0;    
    end    
    else
        ram_wrdata<=rx_data_tmp;
end

endmodule


