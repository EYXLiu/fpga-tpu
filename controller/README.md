## Notes
- Memory Controller
    - Controls how memory is written to uart_tx
    - Since uart_tx can only send 1 byte at a time, the written data needs to be properly spliced such that it's send properly
- Matmul Controller
    - Our current matrix is only a systolic array, it only does caculations
    - We need a controller to set the values at the correct times, as outlined in the README 
    - In the memory model, one address is 32 bits (4 bytes), while each PE takes an input of 8 bits (1 byte). This means each address can store up to 4 memory values 