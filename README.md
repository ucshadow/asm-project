# CAL assignment 2

## A Game for the AVR - Written in Assembler Language

### Contributors

    [Catalin Udrea](https://github.com/ucshadow/)
    [Yusuf Farah](https://github.com/yusufarah/)
    [Radu Orleanu](https://github.com/raduorleanu/)

### Activity diagram

    ![activity diagram](https://i.imgur.com/IQ9WowL.png)

### Testing

For the second assignment, testing was conducted to verify the correct functionality of the ASM program.
Although tests using the AVR board were also conducted, like testing for led flashes and user input, the results are harder to document without using something like video recordings and so they will not be provided here.
Macros were used to structure the code and even thought some macros like the store_pattern macro may seem like it could have been omitted, the thought behind constructing it was that it provides separation of concerns and scalability for future development.
There were 4 important parts of the program that needed to be thoroughly tested and simulated:

    * The storing in XRAM without using a stack, by calling the address directly
    * The custom jump of the XRAM address pointer
    * The modulo 8 used in the random seed generation
    * The shifting of a bit to the right

### XRAM data storage

Since data was saved to RAM without using a stack to point to address space, this test was written to confirm the fact that you can point to memory address directly by using the x, y, or z pointers.

```assembly
test_store_pattern:						;	tests the store_pattern macro	
	store_pattern r16					;	should store the value of r16, in register 0x420 + current index
	dec r16
	brne test_store_pattern
```
