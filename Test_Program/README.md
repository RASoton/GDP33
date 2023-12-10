# Test program for the Posit PPU
copy the "ppu" into the "cv32e40p/rtl/" folder
replace the Makefile and cv32e40p_fp_wrapper.sv into the "cv32e40p/example_tb/core/" to change the fpnew directory to Posit directory
replace the contents in the "main.c" file located at "cv32e40p/example_tb/core/custom_fp/" folder with test programs, and run UVM test for custom-fp
