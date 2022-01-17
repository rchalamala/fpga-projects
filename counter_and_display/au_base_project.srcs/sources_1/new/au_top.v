module seven_segment (
    input [3:0] in,
    output [7:0] segments
    );
    
    reg [7:0] segment_data;
    
    assign segments[7:0] = segment_data[7:0];
 
    always @(in)
    begin
        case (in)
            0: segment_data[7:0] = ~8'b00111111;
            1: segment_data[7:0] = ~8'b00000110;
            2: segment_data[7:0] = ~8'b01011011;
            3: segment_data[7:0] = ~8'b01001111;
            4: segment_data[7:0] = ~8'b01100110;
            5: segment_data[7:0] = ~8'b01101101;
            6: segment_data[7:0] = ~8'b01111101;
            7: segment_data[7:0] = ~8'b00000111;
            8: segment_data[7:0] = ~8'b01111111;
            9: segment_data[7:0] = ~8'b01100111;
            default: segment_data[7:0] = ~8'b00000000;
        endcase
    end
endmodule

module au_top(
    input clk,
    input rst_n,
    output [7:0] led,
    input usb_rx,
    output usb_tx,
    output [23:0] io_led,
    output [7:0] io_seg,
    output [3:0] io_sel,
    input [4:0] io_button,
    input [23:0] io_dip
    );
    
    wire rst;
    reg [37:0] counter;
    reg [15:0] segment, digits;
    reg [13:0] number;
    reg [3:0] state, segment_encoded_lower, segment_encoded_upper;
    reg [1:0] digit_bit;
    reg [0:0] change;
    
    seven_segment display_encoder(.in(state));
    
    reset_conditioner reset_conditioner(.clk(clk), .in(!rst_n), .out(rst));

    assign led[7:0] = number[7:0];
    
    assign io_seg[7:0] = display_encoder.segments[7:0];
    assign io_sel[3:0] = ~(1 << digit_bit[1:0]);
    assign io_led[13:0] = number[13:0];
    
    always @(posedge clk, posedge rst)
    begin
        if (rst)
        begin
            counter[37:0] <= 0;
            digit_bit[1:0] <= 0;
            digits[15:0] <= 0;
            state[3:0] <= 0;
        end
        else
        begin
            counter[37:0] = counter[37:0] + 1;
            
            change[0:0] = (number[13:0] != counter[37:24]);
            number[13:0] = counter[37:24];
            
            if(number == 10000)
            begin
                counter[37:0] = 37'b0;
                number[13:0] = 37'b0;
                digits[15:0] = 37'b0;
            end
            
            if(change)
            begin
                digits[3:0] = digits[3:0] + 1;
                if(digits[3:0] == 4'b1010)
                begin
                    digits[3:0] = 4'b0;
                    digits[7:4] = digits[7:4] + 1;
                    if(digits[7:4] == 4'b1010)
                    begin
                        digits[7:4] = 4'b0;
                        digits[11:8] = digits[11:8] + 1;
                        if(digits[11:8] == 4'b1010)
                        begin
                            digits[11:8] = 4'b0;
                            digits[15:12] = digits[15:12] + 1;
                            if(digits[15:12] == 4'b1010)
                            begin
                                digits[15:12] = 4'b0;
                            end
                        end
                    end
                end
            end
            
            digit_bit[1:0] = counter[13:12];
            case(digit_bit[1:0])
                0: state[3:0] = digits[3:0];
                1: state[3:0] = digits[7:4];
                2: state[3:0] = digits[11:8];
                default: state[3:0] = digits[15:12];
            endcase
        end
    end
    
    assign usb_tx = usb_rx;
    
endmodule