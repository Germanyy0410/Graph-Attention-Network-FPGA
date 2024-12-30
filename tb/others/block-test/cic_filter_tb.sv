`timescale 1ns/1ps

module cic_filter_tb;

    localparam data_width = 16;
    localparam fraction_width = 15;
    localparam filter_N = 5;
    localparam filter_R = 200;
    localparam test_input_size = filter_R * 20;

    bit aclk;
    bit rst;

    bit signed[data_width - 1 : 0] filter_input[test_input_size];
    bit signed[data_width - 1 : 0] expected_output[test_input_size / filter_R];
    bit signed[data_width - 1 : 0] real_output[$];

    bit[data_width - 1 : 0] s_axis_tdata;
    bit s_axis_tvalid;
    bit s_axis_tready;

    bit[data_width - 1 : 0] m_axis_tdata;
    bit m_axis_tvalid;
    bit m_axis_tready;

    bit a;

    initial begin
        aclk = 0;
        a = 0;
        forever begin
            aclk = #10 !aclk;
        end
    end

    initial begin
        $readmemb("./cic_mem/input.mem", filter_input);
        $readmemb("./cic_mem/expected.mem", expected_output);
    end
    
    cic_filter #(
        .data_width(data_width),
        .filter_R(filter_R),
        .filter_N(filter_N)
    ) dut (
        .aclk(aclk),
        .rst_i(rst),

        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),

        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready)
    );

    bit simulation_fail;
    event simulation_end;

    initial begin
        #0
        rst = 1;
        m_axis_tready = 0;
        repeat(2) begin
            @(negedge aclk);
        end
        rst = 0;
        m_axis_tready = 1;
        for(int i = 0; i < test_input_size; i = i + 1) begin
            @(posedge aclk);
            wait(s_axis_tready);
            s_axis_tdata = filter_input[i];
            s_axis_tvalid = 1;
        end
        @(posedge aclk);
        s_axis_tdata = 0;
        -> simulation_end;
    end

    initial begin
        @(negedge rst);
        forever begin
            @(posedge aclk);
            if(m_axis_tvalid && m_axis_tready) begin
                real_output.push_back(m_axis_tdata);
                $display("real output: %d", m_axis_tdata);
            end
        end
    end

    bit signed[data_width - 1 : 0] difference;
    bit signed[data_width - 1 : 0] max_diff;
    
    initial @(simulation_end) begin
        repeat(10000) begin
            @(negedge aclk);
        end

        a = 1;

        repeat(filter_N) begin
            real_output.pop_front();
        end

        max_diff = $ceil(0.001 * (2**fraction_width));
        $display("\nmax_diff used: %0d or %0f", max_diff, real'(max_diff) / real'(2**fraction_width));
        
        for(int i = 0; i < test_input_size / filter_R; i = i + 1) begin
            difference = $signed(real_output[i] - expected_output[i]);
            if(difference < 0) begin
                difference = -difference;
            end
            if(difference < max_diff) begin
                simulation_fail = 0;
                $display("\nreal_output[%0d] = %d, expected_output[%0d] = %d, diff = %0d", i, real_output[i], i, expected_output[i], difference);
            end
            else begin
                simulation_fail = 1;
                $display("\nWrong result! real_output[%0d] = %d, expected_output[%0d] = %d, diff = %0d", i, real_output[i], i, expected_output[i], difference);
                break;
            end
        end

        $display("\n##########################################################");
        if(simulation_fail) begin
            $display("\nSimulation failed!");
        end
        else begin
            $display("\nSimulation success!");
        end
        $display("\n##########################################################\n");
        $finish;
    end
endmodule
