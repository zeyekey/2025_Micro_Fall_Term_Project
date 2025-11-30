# 2025_Micro_Fall_Term_Project
A project made by student group  in microcomputer class with Assembly lang.

BOARD 1 TEAM
1. SÜLEYMAN NURİ (Analog & Control)

Files: temp_control.asm, tachometer.asm

Task: Read the LM35 sensor and calculate Ambient_Temp. Count the fan rotation speed (RPS) using Timer1. Turn the Heater/Cooler pins on or off based on Desired and Ambient temperatures.

2. OZAN (Input Unit)

Files: keypad.asm, input_validation.asm

Task: Receive data when the user presses the Keypad (Interrupt). Convert keystrokes like "2", "5", ".", "5" into the number 25.5. Reject inputs outside the range of 10 to 50 degrees.

3. HAKAN (Visual & Communication)

Files: display_7seg.asm, uart_board1.asm, Board1_Main.asm

Task: Display the data produced by Süleyman and Ozan sequentially on the 7-Segment display. Receive the "Set Temperature" command from the PC and write it to memory. Merge/Integrate all Board 1 codes.

BOARD 2 & API TEAM
1. ZEYNEP (Team Lead & Integrator)

PC (API): core/, api/, main.py

Establishes the brain of the system. Determines which command corresponds to which byte (e.g., 0x01) (protocol.md).

Board 2 (Firmware): lcd_driver.asm, uart_board2.asm, Board2_Main.asm

Writes sensor data to the Board 2 LCD screen. Manages UART traffic.

2. NAZLI (Motor & Device Implementation)

PC (API): devices/

Implements the "Curtain" and "Air Conditioner" objects using the API structure established by Zeynep. (E.g., writes the setCurtain(50) function).

Board 2 (Firmware): motor_logic.asm

Drives the curtain motor. Writes the math in Assembly to rotate the motor 1000 steps when a 100% command is received.

3. CİHAN (Sensor & Transport)

PC (API): transports/

Ensures the system does not crash when the serial port (USB) disconnects (serial_transport.py). Generates virtual data to test the software when hardware is absent (mock_transport.py).

Board 2 (Firmware): sensors_i2c.asm, sensors_analog.asm

Reads the Pressure sensor via I2C protocol and Light/Potentiometer sensors via ADC.