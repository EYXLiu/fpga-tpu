module nxn_matmul_controller #(
    parameter N = 4
) (
    input logic clk,
    input logic rst,

    input logic start,

    output logic        a_rd_en,
    output logic [9:0]  a_addr,
    input  logic [31:0] a_rd_data,

    output logic        b_rd_en,
    output logic [9:0]  b_addr,
    input logic [31:0]  b_rd_data,

    output logic [7:0] a_in [0:N-1],
    output logic [7:0] b_in [0:N-1],
    input logic [31:0] c    [0:N-1][0:N-1],

    output logic done
);

    typedef enum logic [3:0] {
        IDLE,

        READ_REQ,
        READ_WAIT,
        READ_CAPTURE,

        COMPUTE,
        FLUSH,
        FINISH
    } state_t;

    state_t state;

    // store matrices, for now, we can implement streaming later
    logic [7:0] A [0:N-1][0:N-1];
    logic [7:0] B [0:N-1][0:N-1];

    // optimize for space (though an int is fine as well)
    logic [1:0] row;
    integer compute_cycle;

    always_ff @(posedge clk) begin

        if (rst) begin

            state <= IDLE;

            row <= 0;
            compute_cycle <= 0;

            a_rd_en <= 0;
            a_addr <= 0;
            b_rd_en <= 0;
            b_addr <= 0;

            done <= 0;
        
        end 
        else begin

            a_rd_en <= 0;
            b_rd_en <= 0;
            done <= 0;

            case (state)

                IDLE: begin
                    if (start) begin
                        row <= 0;
                        state <= READ_REQ;
                    end
                end

                READ_REQ: begin
                    a_rd_en <= 1;
                    a_addr <= 10'(row);

                    b_rd_en <= 1;
                    b_addr <= 10'(N + row);

                    state <= READ_WAIT;
                end

                READ_WAIT: begin
                    state <= READ_CAPTURE;
                end

                READ_CAPTURE: begin

                    A[row][0] <= a_rd_data[31:24];
                    A[row][1] <= a_rd_data[23:16];
                    A[row][2] <= a_rd_data[15:8];
                    A[row][3] <= a_rd_data[7:0];

                    B[row][0] <= b_rd_data[31:24];
                    B[row][1] <= b_rd_data[23:16];
                    B[row][2] <= b_rd_data[15:8];
                    B[row][3] <= b_rd_data[7:0];

                    if (row == 2'(N-1)) begin
                        row <= 0;
                        compute_cycle <= 0;
                        state <= COMPUTE;
                    end else begin
                        row <= row + 1;
                        state <= READ_REQ;
                    end
                end

                COMPUTE: begin

                    for (int i = 0; i < N; i++) begin

                        if (compute_cycle >= i &&
                            compute_cycle < i + N)
                            a_in[i] <= A[i][compute_cycle - i];
                        else
                            a_in[i] <= 0;

                    end

                    for (int j = 0; j < N; j++) begin

                        if (compute_cycle >= j &&
                            compute_cycle < j + N)
                            b_in[j] <= B[compute_cycle - j][j];
                        else
                            b_in[j] <= 0;

                    end 

                    if (compute_cycle == 3*N-3) begin
                        state <= FLUSH;
                    end
                    else begin
                        compute_cycle <= compute_cycle + 1;
                    end

                end

                FLUSH: begin
                    state <= FINISH;
                end

                FINISH: begin
                    done <= 1;
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule 
    