//*************************************************************
//file: permutation.sv
//module: permutation
//des: implement ROUNDS_PER_CYCLE
//*************************************************************
module permutation #(
    parameter ROUNDS_PER_CYCLE = 3
)(
    input logic [3:0] round_cnt_i,
    input logic [63:0] x0_i,
    input logic [63:0] x1_i,
    input logic [63:0] x2_i,
    input logic [63:0] x3_i,
    input logic [63:0] x4_i,
    //
    output logic [63:0] x0_o,
    output logic [63:0] x1_o,
    output logic [63:0] x2_o,
    output logic [63:0] x3_o,
    output logic [63:0] x4_o  //
);
    //
    //import cfg::*;
    //internal signals: packed type (horizontal)
    logic [ROUNDS_PER_CYCLE:0][63:0] x0, x1, x2, x3, x4;
    logic [ROUNDS_PER_CYCLE-1:0][63:0] x0_linear, x1_linear, x2_linear, x3_linear, x4_linear;
    logic [ROUNDS_PER_CYCLE-1:0][63:0] x0_map, x1_map, x2_map, x3_map, x4_map;
    logic [ROUNDS_PER_CYCLE-1:0][63:0] x0_affi, x1_affi, x2_affi, x3_affi, x4_affi;
    logic [ROUNDS_PER_CYCLE-1:0][3:0] c;
    //data assign
    assign x0[0] = x0_i;
    assign x1[0] = x1_i;
    assign x2[0] = x2_i;
    assign x3[0] = x3_i;
    assign x4[0] = x4_i;

    genvar i;
    generate
       for(i=0; i<ROUNDS_PER_CYCLE; i=i+1) begin: permutation_block
            //*-------------------rounds constant addition--------*/
            assign c[i] = 4'hC - round_cnt_i + i;

            ///*--------------sbox layer-------------------------*/
            //(1)linear layer
            assign x0_linear[i] = x0[i] ^ x4[i];
            assign x1_linear[i] = x1[i];
            assign x2_linear[i] = x2[i] ^ x1[i] ^ {56'h0, (4'hF - c[i]), c[i]};
            assign x3_linear[i] = x3[i];
            assign x4_linear[i] = x4[i] ^ x3[i];
            //(2)mapping layer
            assign x0_map[i] = x0_linear[i] ^ (~x1_linear[i] & x2_linear[i]);
            assign x1_map[i] = x1_linear[i] ^ (~x2_linear[i] & x3_linear[i]);
            assign x2_map[i] = x2_linear[i] ^ (~x3_linear[i] & x4_linear[i]);
            assign x3_map[i] = x3_linear[i] ^ (~x4_linear[i] & x0_linear[i]);
            assign x4_map[i] = x4_linear[i] ^ (~x0_linear[i] & x1_linear[i]);
            //(3)affine layer 2
            assign x0_affi[i] = x0_map[i] ^ x4_map[i];
            assign x1_affi[i] = x1_map[i] ^ x0_map[i];
            assign x2_affi[i] = ~x2_map[i];
            assign x3_affi[i] = x3_map[i] ^ x2_map[i];
            assign x4_affi[i] = x4_map[i];
            ///*-------------LINEAR LAYER-------------------*/ 
            assign x0[i+1] = x0_affi[i] ^ {x0_affi[i][18:0], x0_affi[i][63:19]} ^   {x0_affi[i][27:0], x0_affi[i][63:28]};
            assign x1[i+1] = x1_affi[i] ^ {x1_affi[i][60:0], x1_affi[i][63:61]} ^   {x1_affi[i][38:0], x1_affi[i][63:39]};
            assign x2[i+1] = x2_affi[i] ^ {x2_affi[i][0], x2_affi[i][63:1]}     ^   {x2_affi[i][5:0], x2_affi[i][63:6]};
            assign x3[i+1] = x3_affi[i] ^ {x3_affi[i][9:0], x3_affi[i][63:10]}  ^   {x3_affi[i][16:0], x3_affi[i][63:17]};
            assign x4[i+1] = x4_affi[i] ^ {x4_affi[i][6:0], x4_affi[i][63:7]}   ^   {x4_affi[i][40:0], x4_affi[i][63:41]};
			
           ///*---------------DONE------------------*/` 
        end
    endgenerate

    //output assignment
    assign x0_o = x0[ROUNDS_PER_CYCLE];
    assign x1_o = x1[ROUNDS_PER_CYCLE];
    assign x2_o = x2[ROUNDS_PER_CYCLE];
    assign x3_o = x3[ROUNDS_PER_CYCLE];
    assign x4_o = x4[ROUNDS_PER_CYCLE];

   endmodule