// ==================================================================
// File name  : num_node_controller.sv
// Project    : Acceleration of Graph Attention Networks on FPGA
// Function   : Store number of nodes of each subgraph into BRAM
// Author     : @Germanyy0410
// ==================================================================
module num_node_controller import gat_pkg::*;
(
  input                                                 clk                       ,
  input                                                 rst_n                     ,

  input                                                 spmm_vld_i                ,

  input                                                 src_flag                  ,
  input   [NUM_NODE_WIDTH-1:0]                          num_node                  ,

  // -- num_node
  output  [NUM_NODE_WIDTH-1:0]                          num_node_bram_din         ,
  output                                                num_node_bram_ena         ,
  output  [NUM_NODE_ADDR_W-1:0]                         num_node_bram_addra
);

  logic [NUM_NODE_ADDR_W-1:0] addr                  ;
  logic [NUM_NODE_ADDR_W-1:0] addr_reg              ;
  logic [1:0]                 num_node_status       ;
  logic [1:0]                 num_node_status_reg   ;

  // push to bram
  assign num_node_bram_din   = num_node;
  assign num_node_bram_ena   = (num_node_status_reg == RUN);
  assign num_node_bram_addra = addr_reg;

  always_comb begin
    case (num_node_status)
      IDLE    : if (src_flag && spmm_vld_i)  num_node_status = RUN;
      RUN     : num_node_status = DONE;
      DONE    : if (!src_flag && spmm_vld_i) num_node_status = IDLE;
      default : num_node_status = num_node_status_reg;
    endcase
  end

  assign addr = (num_node_status_reg == RUN && spmm_vld_i) ? (addr_reg + 1) : addr_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      addr_reg            <= '0;
      num_node_status_reg <= '0;

    end else begin
      addr_reg            <= addr;
      num_node_status_reg <= num_node_status;
    end
  end
endmodule