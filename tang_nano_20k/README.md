## Notes
Basic architecture:
- Write:
    - Python - addr, data -> uart_rx -> parser -> memory -> memory controller -> uart_tx - "\x0h" -> Python
- Read:
    - Python - addr -> uart_rx -> parser -> memory -> memory controller -> uart_tx - data -> Python

#### Gowin Specifics
- Device: `GW2AR-LV18QN88C8/I7 C`
- User buttons: 88, 87 (also inverted)
- Leds: 15, 16, 17, 18, 19, 20
- Clock: 4

#### Python Serial Port
- In terminal, run `ls /dev/cu.*` for all serial connections
- For each non text connection (eg. not Bluetooth-Incoming-Port or debug-console), run `screen /dev/cu.___ 11520`
- When you press any button, the `screen` that is able to connect to an interface is the Tang Nano UART port, use that for any python port