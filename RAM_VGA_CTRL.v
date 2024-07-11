//串口传图的VGA读写RAM控制模块，为底层模块
module RAM_VGA_CTRL(
input wire clk_33M,         //像素扫描时钟,频率为33Mhz，相邻像素点间隔为30ns
input wire rst_n,
input wire [15:0] data_in,
output reg data_req,
output reg [10:0] h_cnt,    //有效行计数器，仅包含有数据输出的位置
output reg [10:0] v_cnt,    //有效场计数器
output reg [15:0] TFT_DATA,
output wire HSYC,            //行同步信号
output wire VSYC,            //场同步信号
output wire TFT_DE,             //有效输出标志信号(DATA_ENABLE,与VGA控制器中VGA_BLK相同)
output wire TFT_CLK,
output wire TFT_BL               //LED背光控制信号，默认为高电平                         
);                              
//TFT_DATA为发给TFT的输出信号，由RGB三种颜色分量组成，每种颜色分量范围在0-255，故每种颜色八位，高低到低位分别为红，绿，蓝

reg [10:0] h_cnt_reg;       //总行计数器，包含了从行同步信号开始到结束的全部时间
reg [10:0] v_cnt_reg;

reg [3:0] TFT_DE_r; //TFT_DE信号的打拍寄存器
reg [3:0] TFT_HS_r;
reg [3:0] TFT_VS_r;

parameter HSYC_end=127;         //行同步信号结束位置
parameter h_data_begin=216;     //行显示扫描开始位置(即开始输出图像数据)
parameter h_data_end=1016;      //行显示扫描结束位置(即结束输出图像数据)
parameter h_end=1055;           //行结束位置(即开始行同步位置),也作为行计数器的最大值
parameter VSYC_end=1;           //场同步结束位置
parameter v_data_begin=35;      //场显示扫描开始位置
parameter v_data_end=515;       //场显示扫描结束位置
parameter v_end=524;            //场结束位置

//行总计数器h_cnt_reg
always @(posedge clk_33M or negedge rst_n) 
begin
    if (!rst_n) 
    begin
        h_cnt_reg<=0;    
    end    
    else if (h_cnt_reg==h_end)      //行结束的时候行计数器清零
    begin
        h_cnt_reg<=0;    
    end
    else 
        h_cnt_reg<=h_cnt_reg+1;
end
//场总计数器v_cnt_reg
always @(posedge clk_33M or negedge rst_n) 
begin
    if (!rst_n) 
    begin
        v_cnt_reg<=0;    
    end
    else if (h_cnt_reg==h_end) 
    begin
        if (v_cnt_reg==v_end) 
        begin
            v_cnt_reg<=0;    
        end
        else
            v_cnt_reg<=v_cnt_reg+1;
    end
end

//产生输出的像素时钟TFT_CLK
assign TFT_CLK=clk_33M;
//LED背光控制信号，默认为高电平
assign TFT_BL=1;
//内部控制的有效数据位置信号(即数据输出请求信号)
always @(posedge clk_33M) 
begin
    data_req<=(v_cnt_reg>=v_data_begin&&v_cnt_reg<=v_data_end)&&
                 (h_cnt_reg>=h_data_begin&&h_cnt_reg<=h_data_end)? 1'b1:1'b0;
end
//发给VGA接口的有效数据位置信号
always @(posedge clk_33M) 
begin
    TFT_DE_r[0]<=data_req;
    TFT_DE_r[3:1]<=TFT_DE_r[2:0];    
end
assign TFT_DE=TFT_DE_r[2];
//行同步信号HSYC
always @(posedge clk_33M) 
begin
    TFT_HS_r[0]<=(h_cnt<HSYC_end)?  0:1;
    TFT_HS_r[3:1]<=TFT_HS_r[2:0];
end
assign HSYC=TFT_HS_r[2];
//场同步信号VSYC
always @(posedge clk_33M) 
begin
    TFT_VS_r[0]<=(v_cnt<VSYC_end)?  0:1;
    TFT_VS_r[3:1]<=TFT_VS_r[2:0]; 
end
assign VSYC=TFT_VS_r[2];
//有效行计数器h_cnt和有效场计数器v_cnt
always @(posedge clk_33M) 
begin
    h_cnt<=data_req? (h_cnt_reg-HSYC_end):10'd0;
    v_cnt<=data_req? (v_cnt_reg-VSYC_end):10'd0;
end
//输出数据TFT_DATA
always @(posedge clk_33M) 
begin
    TFT_DATA<=data_req? (data_in):16'h0000;
end

endmodule

