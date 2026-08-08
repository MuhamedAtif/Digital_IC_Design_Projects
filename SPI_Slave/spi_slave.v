module SPI_Slave (
    input MOSI, SS_n, clk, rst_n, tx_valid,
    input [7:0] tx_data,
    output reg [9:0] rx_data,
    output reg rx_valid, MISO
);

    reg [3:0] serial_to_parallel_counter;
    reg [2:0] parallel_to_serial_counter;
    reg addr_read_rec;
    
    // Test different encodings here: "one_hot", "gray", or "sequential"
    (*fsm_encoding="one_hot"*)
    reg [2:0] cs, ns;

    parameter IDLE = 3'b000, CHK_CMD = 3'b001, WRITE = 3'b010;
    parameter READ_ADD = 3'b011, READ_DATA = 3'b100;

    // Next State Logic
    always @(*) begin
        if (SS_n) begin
            ns = IDLE; // If Slave Select is disabled, immediately go to IDLE
        end else begin
            case(cs)
                IDLE:      ns = CHK_CMD;
                CHK_CMD:   ns = (~MOSI) ? WRITE : ((~addr_read_rec) ? READ_ADD : READ_DATA);
                WRITE:     ns = WRITE;
                READ_ADD:  ns = READ_ADD;
                READ_DATA: ns = READ_DATA;
                default:   ns = IDLE; 
            endcase
        end
    end

    // State Memory
    always @(posedge clk) begin
        if (~rst_n) cs <= IDLE;
        else        cs <= ns;
    end

    // Output Logic
    always @(posedge clk) begin
        if (~rst_n) begin
            rx_data <= 0;
            rx_valid <= 0;
            MISO <= 0;
            addr_read_rec <= 0;
            serial_to_parallel_counter <= 0;
            parallel_to_serial_counter <= 0;
        end else begin
            case(cs)
                IDLE, CHK_CMD: begin
                    rx_valid <= 0;
                    serial_to_parallel_counter <= 0;
                    parallel_to_serial_counter <= 0;
                end
                
                WRITE, READ_ADD: begin
                    if (serial_to_parallel_counter < 10) begin
                        rx_data <= {rx_data[8:0], MOSI};
                        serial_to_parallel_counter <= serial_to_parallel_counter + 1;
                        rx_valid <= 0;
                    end else begin
                        rx_valid <= 1;
                        if (cs == READ_ADD) addr_read_rec <= 1;
                    end
                end
                
                READ_DATA: begin
                    if (tx_valid && parallel_to_serial_counter < 8) begin
                        MISO <= tx_data[7 - parallel_to_serial_counter]; 
                        parallel_to_serial_counter <= parallel_to_serial_counter + 1;
                    end else if (serial_to_parallel_counter < 10) begin
                        rx_data <= {rx_data[8:0], MOSI};
                        serial_to_parallel_counter <= serial_to_parallel_counter + 1;
                        rx_valid <= 0;
                    end else begin
                        rx_valid <= 1;
                        addr_read_rec <= 0; // Reset for next transaction
                    end
                end
            endcase
        end
    end
endmodule