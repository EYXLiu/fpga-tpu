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

    output logic done,
    output logic computing
);

    localparam ELEMENTS_PER_WORD = 4;
    localparam WORDS_PER_ROW = (N + ELEMENTS_PER_WORD - 1) / ELEMENTS_PER_WORD;

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

    integer row;
    integer compute_cycle;
    integer word_idx;

    always_ff @(posedge clk) begin

        if (rst) begin

            state <= IDLE;

            row <= 0;
            compute_cycle <= 0;
            word_idx <= 0;

            a_rd_en <= 0;
            a_addr <= 0;
            b_rd_en <= 0;
            b_addr <= 0;

            done <= 0;
            computing <= 0;
        
        end 
        else begin

            a_rd_en <= 0;
            b_rd_en <= 0;
            done <= 0;

            case (state)

                IDLE: begin
                    if (start) begin
                        row <= 0;
                        word_idx <= 0;
                        state <= READ_REQ;
                    end
                end

                READ_REQ: begin
                    a_rd_en <= 1;
                    a_addr <= 10'(row * WORDS_PER_ROW + word_idx);

                    b_rd_en <= 1;
                    b_addr <= 10'(N * WORDS_PER_ROW + row * WORDS_PER_ROW + word_idx);

                    state <= READ_WAIT;
                end

                READ_WAIT: begin
                    state <= READ_CAPTURE;
                end

                READ_CAPTURE: begin

                    for (int k = 0; k < ELEMENTS_PER_WORD; k++) begin

                        int elem_idx;

                        elem_idx = word_idx * ELEMENTS_PER_WORD + k;

                        if (elem_idx < N) begin
                            A[row][elem_idx] <= a_rd_data[31 - k*8 -: 8];
                            B[row][elem_idx] <= b_rd_data[31 - k*8 -: 8];
                        end

                    end

                    if (word_idx == WORDS_PER_ROW - 1) begin

                        word_idx <= 0;

                        if (row == N-1) begin
                            row <= 0;
                            compute_cycle <= 0;
                            state <= COMPUTE;
                        end
                        else begin
                            row <= row + 1;
                            state <= READ_REQ;
                        end

                    end
                    else begin

                        word_idx <= word_idx + 1;
                        state <= READ_REQ;

                    end
                end

                COMPUTE: begin

                    computing <= 1'b1;

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
                        computing <= 1'b0;
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
    