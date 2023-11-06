#   Posit Multiplier

---

##  Implementation

### Top_Level_Posit_Multiplier
Top level of Multiplier.

### Posit_Extraction
Taking 32-bit Posit input, whose exponent size is 2 bits.
Extracting *Sign bit, regime bits, exponent bits and fraction bits* as output

### Arithmetic_Mult
Taking output from **Posit_Extraction** module, 
Doing multiplication to mantissa and computing the sum exponent for the result.
Outputting *number of regime bits, exponent bits and computed fraction*

### Rounding
Taking output from **Arithmetic_Add_Sub** module,
Rounding the computed outcome to nearest even.

---

##  Testing

### Posit_multiplier_32bits-2_tb
Taking input files generated with softposit, 
computing with modules above and comparing bit patterns generated with softposit.

### Testing Sequences
All testing sequences are in *simulation* folder.

####    mid_range_in1 / mid_range_in2 / mid_range_add_result

These three files are mainly focus on 0.0625 to 16, whose posit bit pattern use least bits for regime, giving the highest precision

####    full_range_in1 / full_range_in2 / full_range_add_result

These three files are mainly focus on ranges other than the range above up to ±65536, who has the same number of bits given to fraction

####    error_32bit
Generated from the testbench, show the difference (in bits) between our outcome and softposit result,

---
**The Multiplier module are ready for synthesis**