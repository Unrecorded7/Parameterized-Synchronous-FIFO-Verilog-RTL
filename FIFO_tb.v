
`timescale 1ns/1ps

module fifo_tb;

    parameter WIDTH = 8;
    parameter DEPTH = 10;

    reg clk, rst;
    reg w_en, r_en;
    reg [WIDTH-1:0] data_in;

    wire full, empty;
    wire [WIDTH-1:0] data_out;


    fifo #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .w_en(w_en),
        .r_en(r_en),
        .data_in(data_in),
        .full(full),
        .empty(empty),
        .data_out(data_out)
    );

    
    reg [WIDTH-1:0] model [0:DEPTH-1];

    integer head = 0;
    integer tail = 0;
    integer count = 0;

    integer i;

 
    initial clk = 0;
    always #2 clk = ~clk;

    task step;
        input wr;
        input rd;
        input [WIDTH-1:0] din;

        reg accept_read;
        reg accept_write;
        reg [WIDTH-1:0] expected_data;
        reg [WIDTH-1:0] previous_data;

        begin
            
            @(negedge clk);

            w_en = wr;
            r_en = rd;
            data_in = din;

           
            accept_read = rd && (count > 0);

            accept_write = wr &&
                           ((count < DEPTH) || accept_read);

            expected_data = model[head];
            previous_data = data_out;

            
            @(posedge clk);
            #1;

            
            if (accept_read) begin
                if (data_out !== expected_data) begin
                    $display("DATA MISMATCH!");
                    $display("Expected = %h, Got = %h",
                             expected_data, data_out);
                    $fatal(1);
                end
            end
            else begin
                if (data_out !== previous_data) begin
                    $display("DATA_OUT changed unexpectedly!");
                    $fatal(1);
                end
            end

            
            if (accept_read) begin
                head = (head + 1) % DEPTH;
            end

            if (accept_write) begin
                model[tail] = din;
                tail = (tail + 1) % DEPTH;
            end

            if (accept_write && !accept_read)
                count = count + 1;
            else if (accept_read && !accept_write)
                count = count - 1;

            
            if (full !== (count == DEPTH)) begin
                $display("FULL FLAG ERROR!");
                $display("Count = %0d, Full = %b",
                         count, full);
                $fatal(1);
            end

            
            if (empty !== (count == 0)) begin
                $display("EMPTY FLAG ERROR!");
                $display("Count = %0d, Empty = %b",
                         count, empty);
                $fatal(1);
            end

            $display(
                "W=%b R=%b DATA=%h | COUNT=%0d FULL=%b EMPTY=%b",
                wr, rd, din, count, full, empty
            );

        end
    endtask

    
    initial begin
        $dumpfile("FIFO.vcd");
        $dumpvars(0,fifo_tb);
        rst = 1;
        w_en = 0;
        r_en = 0;
        data_in = 0;

        
        repeat(2) @(posedge clk);
        #1;

        if (!empty || full)
            $fatal(1, "RESET FAILED");

        @(negedge clk);
        rst = 0;

        $display("\n========== RESET COMPLETE ==========\n");

      
        $display("\nTEST 1: FILL FIFO");

        for(i = 0; i < DEPTH; i = i+1)
            step(1, 0, i + 8'h10);

        
        $display("\nTEST 2: OVERFLOW");

        step(1, 0, 8'hFF);

        
        $display("\nTEST 3: READ + WRITE WHEN FULL");

        step(1, 1, 8'hA5);

       
        $display("\nTEST 4: EMPTY FIFO");

        while(count > 0)
            step(0, 1, 0);

        
        $display("\nTEST 5: UNDERFLOW");

        step(0, 1, 0);

        
        $display("\nTEST 6: READ + WRITE WHEN EMPTY");

        step(1, 1, 8'h5A);

        step(0, 1, 0);

       
        $display("\nTEST 7: RANDOM TESTING");

        for(i = 0; i < 500; i = i+1) begin
            step($random, $random, $random);
        end

        $display("\n=================================");
        $display("ALL TESTS PASSED");
        $display("=================================");

        $finish;

    end

endmodule
