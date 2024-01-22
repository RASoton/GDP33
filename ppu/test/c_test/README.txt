How to run:

1. Copy the ppu folder into the directory => core-v-verif/core-v-cores/cv32e40p/rtl 

2. Replace the cv32e40p_fp_wrapper.sv and makefile in the directory => core-v-verif/core-v-cores/cv32e40p/example_tb/core

3. Copy the the files in ppu/test/c_test into the directory => core-v-verif/core-v-cores/cv32e40p/example_tb/core/custom_fp

4. Open terminal in the directory core-v-verif/core-v-cores/cv32e40p/example_tb/core

5. Type 'make' to run

# To change to specific test: Open the makefile and edit line 247: custom_fp/main.elf: custom_fp/"testfile.c" => replace "testfile.c"
