module traffic_controller #(
    parameter CLOCK_HZ = 50000000
)(
    input clk,
    input [4:0] sw,
    output reg [7:0] led
);

    localparam GREEN_TIME   = 5 * CLOCK_HZ;
    localparam YELLOW_TIME  = 2 * CLOCK_HZ;
    localparam ALL_RED_TIME = 1 * CLOCK_HZ;

    localparam GREEN       = 3'd0;
    localparam YELLOW      = 3'd1;
    localparam CLEAR_RED   = 3'd2;
    localparam EMERGENCY   = 3'd3;
    localparam RETURN_RED  = 3'd4;

    reg [2:0] state;
    reg [31:0] timer;

    reg [1:0] road;
    reg [1:0] emergency_road;
    reg emergency_pending;

    // FSM
    always @(posedge clk) begin

        if (sw[0]) begin
            state <= GREEN;
            timer <= 0;
            road <= 0;
            emergency_road <= 0;
            emergency_pending <= 0;
        end
        else begin

            case (state)

                GREEN: begin
                    if (sw[1] && !emergency_pending) begin
                        emergency_road <= sw[3:2];
                        emergency_pending <= 1'b1;
                        timer <= 0;
                        state <= YELLOW;
                    end
                    else if (timer >= GREEN_TIME - 1) begin
                        timer <= 0;
                        state <= YELLOW;
                    end
                    else begin
                        timer <= timer + 1'b1;
                    end
                end

                YELLOW: begin
                    if (timer >= YELLOW_TIME - 1) begin
                        timer <= 0;

                        if (emergency_pending || sw[1]) begin
                            if (sw[1] && !emergency_pending) begin
                                emergency_road <= sw[3:2];
                                emergency_pending <= 1'b1;
                            end
                            state <= CLEAR_RED;
                        end
                        else begin
                            road <= road + 1'b1;
                            state <= GREEN;
                        end
                    end
                    else begin
                        timer <= timer + 1'b1;
                    end
                end

                CLEAR_RED: begin
                    if (timer >= ALL_RED_TIME - 1) begin
                        timer <= 0;
                        state <= EMERGENCY;
                    end
                    else begin
                        timer <= timer + 1'b1;
                    end
                end

                EMERGENCY: begin
                    timer <= 0;
                    if (sw[4])
                        state <= RETURN_RED;
                end

                RETURN_RED: begin
                    if (timer >= ALL_RED_TIME - 1) begin
                        timer <= 0;
                        emergency_pending <= 0;
                        road <= emergency_road;
                        state <= GREEN;
                    end
                    else begin
                        timer <= timer + 1'b1;
                    end
                end

                default: begin
                    state <= GREEN;
                    timer <= 0;
                end

            endcase
        end
    end

    // LED output decoder
    always @(*) begin

        led = 8'b00000000;

        case (state)

            GREEN: begin
                case (road)
                    2'd0: led[1:0] = 2'b10;
                    2'd1: led[3:2] = 2'b10;
                    2'd2: led[5:4] = 2'b10;
                    2'd3: led[7:6] = 2'b10;
                endcase
            end

            YELLOW: begin
                case (road)
                    2'd0: led[1:0] = 2'b01;
                    2'd1: led[3:2] = 2'b01;
                    2'd2: led[5:4] = 2'b01;
                    2'd3: led[7:6] = 2'b01;
                endcase
            end

            CLEAR_RED, RETURN_RED: begin
                led = 8'b00000000;
            end

            EMERGENCY: begin
                case (emergency_road)
                    2'd0: led[1:0] = 2'b10;
                    2'd1: led[3:2] = 2'b10;
                    2'd2: led[5:4] = 2'b10;
                    2'd3: led[7:6] = 2'b10;
                endcase
            end

            default: led = 8'b00000000;

        endcase
    end

endmodule