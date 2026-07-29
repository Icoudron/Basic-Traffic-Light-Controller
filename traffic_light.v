`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
// Create Date: 07/22/2026 05:36:13 PM
// Design Name: Basic Stoplight Intersection
// Module Name: traffic_light
// Project Name: Controlled Stoplight Intersection
// Description: A Finite State Machine (FSM) that runs a three-light traffic signal 
// 
// Hrdware Used:
// - 100MHz onboard clock
// - Green LED (LED 0) that runs for 8 seconds
// - Yellow LED (LED 1) that runs for 2 seconds
// - RED LED (LED 2) that runs for 5 seconds
// - Reset button (btnC) thats resets the controller back to Green
// 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module traffic_light(

    // Inputs
    
    input clk,      // 100 MHz System Clock
    input btnC,     // Reset Button
    
    // Outputs
    
    output reg [2:0] led    // Traffic Light LEDs
  
    );
    
    // State Defintions: Each state represents a traffic light
        // There are only two bits because there are only 3 possible states
    
    parameter GREEN = 2'd0;
    parameter YELLOW = 2'd1;
    parameter RED = 2'd2;
    
    // Registers
    
    reg [1:0] state= GREEN;     // Stores the current Traffic Light State
    reg [2:0] seconds = 0;      // Counts the number of seconds that have elapsed

    reg[26:0] divider = 0;      // Clock divider used to convert the 100MHz clock
                                // Into a one-second timing pulse.
                                
    reg tick = 0;               // One clock pulse generated every second
    
    // Clock Divider
    
        // Basys 3 runs at 100 MHz
            // 100,000,000 clock cycles = 1 second
        
        // Once one second has passed, it generates a signal tick pulse
        // that tells the FSM to update
 
    always @(posedge clk)
    begin
        if(divider == 100000000-1)
        begin   
            divider <= 0;
            tick <= 1;
        end
        else
        begin
            divider <= divider + 1;
            tick <= 0;
        end
    end
    
    // Finite State Machine (FSM)
        
        // Controls how the traffic changes between the Traffic light colors
        // State Transitions only occur once every second when the tick
        // signal becomes high
    
    always @(posedge clk)
    begin
    
        // Reset button returns the controller to Green
        if(btnC)
        begin   state <= GREEN;
        seconds <= 0;
       
    end
    
    // Advance only once per second
    else if (tick)
    begin
    
        seconds <= seconds + 1;
        
        case(state)
        
            // Green State
        
            GREEN:
            begin
            
                // Stay Green for 8 seconds
                if(seconds == 7)
                begin
                    state <= YELLOW;
                    seconds <= 0;
                end
            end
            
            // Yellow State
            
            YELLOW:
            begin 
            
                // Stay Yellow for 2 seconds
                if(seconds == 1)
                begin
                    state <= RED;
                    seconds <= 0;
                end
            end
            
            // Red State
            
            RED:
            begin 
            
                // Stay red for 5 Seconds
                if(seconds == 4)
                begin
                    state <= GREEN;
                    seconds <= 0;
                end
            end
            
        endcase
    end
end  
            
    // Output Logic
    
        // Turns on the LED corresponding to the state
        
        // LED0 = Green
        // LED1 = Yellow
        // LED2 = RED         
                
    always @(*) begin
        case(state)
    
            GREEN:  led = 3'b001;
        
            YELLOW: led = 3'b010;
        
            RED:    led = 3'b100;
        
            default: led = 3'b000;
        endcase  
    end
endmodule
