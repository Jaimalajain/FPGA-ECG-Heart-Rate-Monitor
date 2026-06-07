`timescale 1ns / 1ps

module bpm_calculator(
    input clk,
    input rst,
    input beat_pulse,
    output reg [7:0] bpm
);

    reg [31:0] rr_counter;
    reg first_beat;

    always @(posedge clk) begin
        if(rst) begin
            rr_counter <= 0;
            bpm <= 0;
            first_beat <= 0;
        end
        else begin
            rr_counter <= rr_counter + 1;

            if(beat_pulse) begin

                if(first_beat) begin

                    // Fast Simulation Formula
                    if(rr_counter > 0)
                        bpm <= 60_000_000 / rr_counter;

                end
                else begin
                    first_beat <= 1;
                end

                rr_counter <= 0;
            end
        end
    end

endmodule