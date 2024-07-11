module uart_rx(
input wire clk,
input wire rst_n,
input wire uart_rx,
output reg [7:0] data_out,
output reg rx_done_flag

);//波特率计数器最大值1/156200/0.00000002=32为整数，可避免因计数器最大值四舍五入导致的数据丢失
parameter BAUD_SET=1562500; 
parameter MAX=32;   //没有舍掉小数，则32为最大值，无需减1

reg [7:0] data_out_reg;
reg [12:0] data_cnt;    //接收数据的计数器
reg [9:0] data_frequency_cnt;
reg data_cnt_en;         //接收数据计数器使能 

reg uart_rx_d0;
reg uart_rx_d1;
wire rx_flag;       //上升沿检测产生的使能标志
wire rx_done;       //一组数据接收完毕标志    

always @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) 
    begin
        uart_rx_d0<=0;
        uart_rx_d1<=0;    
    end    
    else 
        uart_rx_d0<=uart_rx;
        uart_rx_d1<=uart_rx_d0;
end

assign rx_flag=uart_rx_d1&~uart_rx_d0;

assign rx_done=(data_cnt==MAX)&&(data_frequency_cnt==9);

//data_cnt_en
always @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) 
    begin
        data_cnt_en<=0;    
    end    
    else if (rx_flag) 
    begin
        data_cnt_en<=1;
    end
    else if ((data_cnt==MAX)&&(data_frequency_cnt==9)) 
    begin
        data_cnt_en<=0;    
    end
    else if ((data_cnt==(MAX+1)/2)&&(data_frequency_cnt==0)&&(uart_rx==1)) //若接收到第一个信号非起始位0而是1
    begin                                                                 //则为毛刺信号，使能保持低电平
        data_cnt_en<=0;
    end     
end

//data_cnt
always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        data_cnt<=0;
    end
    else if (data_cnt_en) 
    begin
        if (data_cnt==MAX) 
        begin
            data_cnt<=0;    
        end    
        else 
            data_cnt<=data_cnt+1;
    end
    else
        data_cnt<=0;
end

//接收次数计数器data_frequency_cnt
always @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) 
    begin
        data_frequency_cnt<=0;    
    end    
    else if ((data_frequency_cnt)==9&&(data_cnt==MAX)) 
    begin
        data_frequency_cnt<=0;    
    end
    else if (data_cnt==MAX) 
    begin
        data_frequency_cnt<=data_frequency_cnt+1;
    end
        
end

always @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) 
    begin
        data_out_reg<=0;    
    end    
    else if (data_cnt==(MAX+1)/2)   //发送时间中间时刻进行采样赋值，防止亚稳态
    begin
        case (data_frequency_cnt)
           1: data_out_reg[1]<=uart_rx; 
           2: data_out_reg[2]<=uart_rx; 
           3: data_out_reg[3]<=uart_rx; 
           4: data_out_reg[4]<=uart_rx; 
           5: data_out_reg[5]<=uart_rx; 
           6: data_out_reg[6]<=uart_rx; 
           7: data_out_reg[7]<=uart_rx; 
           8: data_out_reg[8]<=uart_rx; 
            default: data_out_reg<=data_out_reg;
        endcase
    end
end

always @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) 
    begin
        data_out<=0;    
    end    
    else
        data_out<=data_out_reg;
end

always @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) 
    begin
        rx_done_flag<=0;    
    end
    else 
        rx_done_flag<=rx_done;
end

endmodule
