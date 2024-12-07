module mult_12_bit #(
  parameter DATA_WIDTH = 12,
  parameter MULT_MODE  = 1
)(
  input                       clk,
  input                       rst_n,
  input   [DATA_WIDTH-1:0]    a_i,
  input   [DATA_WIDTH-1:0]    b_i,
  input                       en_i,
  output  [DATA_WIDTH*2-1:0]  p_o
);

  reg [DATA_WIDTH*2-1:0] p;
  reg [DATA_WIDTH*2-1:0] p_reg;

  generate
    if (MULT_MODE == 1) begin : OPTIMIZED
      assign p_o = p_reg;

      always_comb begin
          if (en_i) begin
            p = (b_i[11]  ? {a_i, 11'b0}  : 0) +
                (b_i[10]  ? {a_i, 10'b0}  : 0) +
                (b_i[9]   ? {a_i, 9'b0}   : 0) +
                (b_i[8]   ? {a_i, 8'b0}   : 0) +
                (b_i[7]   ? {a_i, 7'b0}   : 0) +
                (b_i[6]   ? {a_i, 6'b0}   : 0) +
                (b_i[5]   ? {a_i, 5'b0}   : 0) +
                (b_i[4]   ? {a_i, 4'b0}   : 0) +
                (b_i[3]   ? {a_i, 3'b0}   : 0) +
                (b_i[2]   ? {a_i, 2'b0}   : 0) +
                (b_i[1]   ? {a_i, 1'b0}   : 0) +
                (b_i[0]   ? a_i           : 0);
          end else begin
            p = p_reg;
          end
      end

      always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          p_reg <= 0;
        end else begin
          p_reg <= p;
        end
      end
    end else if (MULT_MODE == 0) begin : NORMAL
      assign p_o = p_reg;

      always_comb begin
        if (en_i) begin
          p = a_i * b_i;
        end else begin
          p = p_reg;
        end
      end

      always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          p_reg <= 0;
        end else begin
          p_reg <= p;
        end
      end
    end
  endgenerate
endmodule