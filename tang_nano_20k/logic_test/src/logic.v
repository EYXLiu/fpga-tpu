module logic (
    input a,
    input b,
    output x,
    output y
);
    
    // since buttons are action-low
    assign x = (~a) & (~b);
    assign y = (~a) | (~b);

endmodule