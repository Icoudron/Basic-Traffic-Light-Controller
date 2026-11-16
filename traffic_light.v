`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
// Create Date: 07/22/2026 05:36:13 PM
// Design Name: Basic Stoplight Intersection
// Module Name: traffic_light
// Project Name: Controlled Stoplight Intersection
// Description: Imjplements a traffic light controller for a Basys 3 FPGA 
// board using a Finite State Machine (FSM). 
//
// The controller cycles through Green, Yellow, and Red traffic light
// states using the 100 MHz clock. A clock divider generates a one-second
// timing pulse used by FSM
//
// The remaining time is displayed on the onboard seven-segment display.
// During the Yellow and Red States, the display flashes 0 once per second
// as a warning indication.
// 
// Hrdware Used:
// - 100MHz onboard clock
// - Green LED (LED 0) that runs for 20 seconds
// - Yellow LED (LED 1) that runs for 3 seconds
// - RED LED (LED 2) that runs for 10 seconds
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
    input [15:0] sw, // Emergency Service Switch
    
    // Outputs
    
    output reg [15:0] led,    // Traffic Light LEDs
    
    output reg [6:0] seg,   // Seven Segment Display
    output reg [3:0] an
  
    );
    
    // State Defintions: Each state represents a traffic light
        // There are only two bits because there are only 3 possible states
    
    parameter GREEN = 2'd0;
    parameter YELLOW = 2'd1;
    parameter RED = 2'd2;
    
    // Traffic-Light Duration in Seconds
    // These constants define how long each traffic light remain active before the FSM
    // transitions to the next state.
    
    parameter GREEN_TIME    = 20;
    parameter  YELLOW_TIME  = 3;
    parameter   RED_TIME    = 10; 
    // FSM Registers
    
    reg [1:0] state= GREEN;     // Stores the current Traffic Light State
    reg [4:0] seconds = 0;      // Counts the number of seconds that have elapsed

    reg[26:0] divider = 0;      // Clock divider used to convert the 100MHz clock
                                // Into a one-second timing pulse.
                                
    reg tick = 0;               // One clock pulse generated every second
    reg [4:0] countdown;        // Remaining time in current state
    reg blink = 0;              // Controls flashing display when light is Red/Yellow
    reg [15:0] refresh_counter = 0;     // Multiplex Refresh Timer
    reg digit_select = 0;       // Selects active display digit
    reg [3:0] tens;             // Tens digit
    reg [3:0] ones;             // Ones digit
    reg [3:0] display_value;        // Current digit sent to decoder
    reg emergency_previous = 0;     // Emergency switch detection
    
   
    
    // Clock Divider
    
        // Basys 3 runs at 100 MHz
            // 100,000,000 clock cycles = 1 second
        
        // Once one second has passed, it generates a signal tick pulse
        // that tells the FSM to update
 
    always @(posedge clk)
    begin
        if(btnC)
    begin
        divider <= 0;
        tick <= 0;
        blink <= 0;
    end
        else if(divider == 100000000-1)
        begin   
            divider <= 0;
            tick <= 1;              // Generate one-clock-cycle timing pulse
            blink <= ~blink;        // changes blink from 0 to 1 or 1 to 0 every second
        end
        else
        begin
            divider <= divider + 1;     // Continue counting towards one second
            tick <= 0;
        end
    end
    
    
    
    always @(posedge clk)
    begin
        if(btnC)
            emergency_previous <= 0;
        else
            emergency_previous <= sw[15];
    end
    
    // Display Refresh Counter
    //
    // Rapidly alternates between the two seven segment digits occuring fast enough
    // that both digits appear continuouly.
    
    always @(posedge clk)
    begin
        if(btnC)
        begin
            refresh_counter <= 0;
            digit_select <= 0;
        end
        else
        begin
            refresh_counter <= refresh_counter +1;
            
            if(refresh_counter == 50000)
            begin
                refresh_counter <= 0;
                digit_select <= ~digit_select;
            end
        end
    end
    
    // Digit Multiplexer
    //
    // Selects either the tens or ones digit depending on which
    // seven segment display is enabled
    
    always @(*)
    begin
    
        
        if(digit_select)
            display_value = tens;
        else
            display_value = ones;
            
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
    
    else if(sw[15])
    begin
        // Emergency Service Mode 
        state <= state;     // Pauses normal traffic ligh sequence
        seconds <= seconds;
    end
    else if(emergency_previous)
    begin
        state <= GREEN;
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
            
                // Stay Green for 20 seconds
                if(seconds == GREEN_TIME - 1)
                begin
                    state <= YELLOW;
                    seconds <= 0;
                end
            end
            
            // Yellow State
            
            YELLOW:
            begin 
            
                // Stay Yellow for 3 seconds
                if(seconds == YELLOW_TIME - 1)
                begin
                    state <= RED;
                    seconds <= 0;
                end
            end
            
            // Red State
            
            RED:
            begin 
            
                // Stay red for 10 Seconds
                if(seconds == RED_TIME - 1)
                begin
                    state <= GREEN;
                    seconds <= 0;
                end
            end
            
        endcase
    end
end  

        // Countdown Generator
        // Calcuates how many sceonds remain in the current traffic light state
    
    always @(*)
    begin
        case(state)
        
            GREEN:
                countdown = GREEN_TIME - seconds;
            
            YELLOW:
                countdown =  YELLOW_TIME - seconds;
            RED:
                countdown = RED_TIME - seconds;
                
            default: 
                countdown = 0;
                
        endcase
        
    end     
   
    // Binary to Decimal Conversion
    //
    // Splits the countdown value into seperate tens and ones
    // digits for display on the dual seven segment display
   
     always @(*)
    begin   
        tens = countdown / 10;
        ones = countdown % 10;
    end
    
    
    // Digit Enable Logic
    //
    // Enables one display at a time.
    // AN1 diplays the tens digits and AN0 displays the ones digit.
    
    always @(*)
    begin
        if(digit_select)
            an = 4'b1101;   // Left Digit
        else
            an = 4'b1110;   // Righ Digit
    end
    
    //  Seven Segment Decoder
    //  Converts 4-bit decimal value into the corresponding seven segment pattern
    // During YELLOW and RED states the display alternates showing "0" and blank to act
    // as a no crossing warning.
    
    always @(*)
    begin
        
        if (sw[15])
        begin
            // Emergency mode: Flash zero
            
            if (blink)
                seg = 7'b1000000;       // Show 0
            else
                seg = 7'b1111111;       // Blank display 
        end
        // Flash zero during RED or YELLOW
        else if ((state == RED) || (state == YELLOW))
        begin
        
            if (blink)
                seg = 7'b1000000;       // display 0
            else
                seg = 7'b1111111;       // Blank display
                
        end
    
        // Show the normal countdown during GREEN
        
        else
        begin
        
            case(display_value)
        
                4'd0: seg = 7'b1000000;     // 0
                4'd1: seg = 7'b1111001;     // 1
                4'd2: seg = 7'b0100100;     // 2
                4'd3: seg = 7'b0110000;     // 3
                4'd4: seg = 7'b0011001;     // 4
                4'd5: seg = 7'b0010010;     // 5
                4'd6: seg = 7'b0000010;     // 6
                4'd7: seg = 7'b1111000;     // 7
                4'd8: seg = 7'b0000000;     // 8
                4'd9: seg = 7'b0010000;     // 9
            
            
                default:
                    seg = 7'b1111111;       // All Segments off
                
            endcase
        end
    end
            

            
    // Output Logic
    
        // Turns on the LED corresponding to the state
        
        // LED0 = Green
        // LED1 = Yellow
        // LED2 = RED         
                
    always @(*) begin
        if (sw[15])
        begin
            // Emergency mode: flash the red LED (LED 2)
            // LED 15 stays on (Emergency indicator)
            
            if (blink)
                led = 16'b1000000000000100;
            else
                led = 16'b1000000000000000;
        end
        else
        
        begin
        case(state)
            // Normal Traffic operation
    
            GREEN:  led = 16'b0000000000000001;
        
            YELLOW: led = 16'b0000000000000010;
        
            RED:    led = 16'b0000000000000100;
        
            default: led = 16'b0000000000000000;
        endcase  
    end
end
endmodule
