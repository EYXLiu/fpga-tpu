## GPU/TPU on an FPGA 
- Currently writing verilog and verifying through verilator  
- Next steps are to transfer it over to `Tang Nano 20k` for hardware testing 

## Notes
- Each folder has notes for the specific part its dealing with for learning purposes
- Each SystemVerilog module also has a test sim 

## Core Features
- [x] basic arithmetic
- [x] basic test synthesis + pin manipulation on Tang Nano 20k
- [x] MAC (multiply accumulate)
- [x] PE (processing element)
- [x] n x n systolic arrays
    - [x] verilator simulations
- [x] n x m systolic arrays
    - [x] verilator simulations
- [x] single and dual port unified buffer
    - [x] verilator simulations
- [x] UART to Tang Nano 20k
    - [x] UART memory controller
    - [x] memory simulations using above single port unified buffer
    - [x] read and write testing
- [x] n x n matmul controllers
    - [x] 2x2, 3x3, 4x4, 8x8 verilator simulations
- [x] n x m matmul controllers
    - [x] 2x4 * 4x3 verilator simulations
- [ ] matmul on Tang Nano 20k testing
- [ ] simulate a small neural network on the Tang Nano 20k
- [ ] possibly crux of neural networks on Verilog
    - [ ] Forward pass
    - [ ] Backpropagation