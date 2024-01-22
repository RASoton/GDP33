import numpy as np
import math
import softposit as sp

# Function to generate test cases
def generate(start, end, num_values, output_file_path):
    values = np.linspace(start, end, num_values)
    #print(values)
    with open(output_file_path, 'w') as output_file:
        for val in values:
            p32 = sp.posit32(val).toBinaryFormatted()
            output_file.write(f"{p32}\n")

# Function to convert regime value to binary
def regime_to_bits(value):
    # Positive regime value
    if value >= 0:
        return '1' * (value + 1) + '0'
    # Negative regime value
    else:
        return '0' * (-value) + '1'

# Function to convert integer to binary
def to_binary(num):
    if num == 0:
        return "0"
    binary = []
    while num > 0:
        binary.append(str(num % 2))
        num = num // 2
    return ''.join(binary[::-1])

# Function to convert fraction binary to decimal
def get_fraction(bits):
    val = int(bits, 2)
    num = val / (2**len(bits))
    print(num)

# Function to convert decimal to posit binary
def d2p(value):
    sign = ""
    regime = ""
    exponent = ""
    fraction = ""
    ES = 2
    useed = 2**2**ES

    if (value < 0):
        sign = "1"
        value = value * -1
    else:
        sign = "0"
        
    if (value > 0 and value < 1):
        temp = math.floor(math.log((1/value), useed)) + 1
        temp = -temp
        r = useed ** temp
    else:
        temp = math.floor(math.log(value, useed))
        r = useed ** temp

    exp = math.floor(math.log((value/r),2))
    frac =  (value/(r * (2**exp))) - 1
    regime = regime_to_bits(temp)
    exponent = to_binary(exp)
    if (exponent == "0"):
        exponent = "00"
    elif(exponent == "1"):
        exponent = "10"
    frac_len = 32 - 1 - ES - len(regime)
    f = math.floor(frac *  (2**frac_len))
    fraction = to_binary(f)
    fill = 32 - 1 - ES - len(regime) - len(fraction)
    result = sign + regime + exponent +  (fill*"0") + fraction 
    return result

# Function to convert posit binary to decimal
def p2d(posit_str):
    #if(len(posit_str) != 32):
        #raise ValueError(f"{len(posit_str)}: Not 32-bit")
    if(posit_str == 32*"0"):
        result = 0
    elif(posit_str == "1"+31*"0"):
        result = "NaN"
    else:
        posit = int(posit_str, 2)
        sign = (posit >> 31) & 1
        if sign == 1:
            posit = (posit ^ 0x7fffffff) + 1
        remaining_bits = 30
        regime = 0
        regime_bit = (posit >> remaining_bits) & 1
        while ((posit >> remaining_bits) & 1) == regime_bit:
            regime += 1
            remaining_bits -= 1
            if remaining_bits < 0:
                break 
        if regime_bit == 0:
            regime = -regime
        else:
            regime -= 1
        exponent = 0
        if remaining_bits >= 2:
            exponent = (posit >> (remaining_bits - 2)) & 0x3
            remaining_bits -= 2
        fraction = 1.0  
        for i in range(remaining_bits):
            if (posit >> i) & 1:
                fraction += 2.0 ** (-1.0 * (remaining_bits - i))
                
        decimal = (2 ** (4*regime + exponent)) * fraction
        result =  -decimal if sign == 1 else decimal
    #print(result)
    return result

# Function to read Posit values from a file, convert them, and write the results to another file
def convert_posit_file(input_file_path, output_file_path):
    with open(input_file_path, 'r') as input_file, open(output_file_path, 'w') as output_file:
        for line in input_file:
            posit_str = line.strip()
            if posit_str: 
                decimal_value = p2d(posit_str)
                output_file.write(f"{decimal_value}\n")

# Function to read decimal values from a file, square root them, and write the results to another file
def sqrt_values_from_file(input_file_path, output_file_path):
    with open(input_file_path, 'r') as input_file, open(output_file_path, 'w') as output_file:
        for line in input_file:
            try:
                value = float(line.strip())
                sqrt_value = math.sqrt(value)
                output_file.write(f"{sqrt_value}\n")
            except ValueError:
                print(f"Could not convert line to float: {line.strip()}")

# Function to read decimals values from two files, find their differences, and write the results to another file
def write_error_differences(file1_path, file2_path, diff_file_path):
    with open(file1_path, 'r') as file1:
        file1_numbers = [float(line.strip()) for line in file1]
    
    with open(file2_path, 'r') as file2:
        file2_numbers = [float(line.strip()) for line in file2]
    
    differences = [f"{a - b}" for a, b in zip(file1_numbers, file2_numbers)]
    
    with open(diff_file_path, 'w') as diff_file:
        for line in differences:
            diff_file.write(line + '\n')

# Function to read decimal values from a file, convert them to posit binary, square root using the Softposit algorithm, and write the results to another file
def softposit_sqrt(input_file_path, output_file_path):
    with open(input_file_path, 'r') as input_file:
        numbers = [float(line.strip()) for line in input_file]

    sqrt_results = []
    for num in numbers:
        posit_num = sp.posit32(num)  
        sqrt_result = posit_num.sqrt() 
        sqrt_results.append(sqrt_result)

    with open(output_file_path, 'w') as output_file:
        for result in sqrt_results:
            output_file.write(f"{result}\n")

def find_max_min_in_file(file_path):
    try:
        with open(file_path, 'r') as file:
            numbers = [float(line.strip()) for line in file if line.strip()]
        print(max(numbers), min(numbers)) 
    except FileNotFoundError:
        return "The file was not found."
    except ValueError:
        return "The file contains non-numeric data."
    except Exception as e:
        return f"An error occurred: {e}"
    
"""
# convert posit to decimal
input_file_path = 'sqrt_test.txt'
output_file_path = 'decimal.txt'
convert_posit_file(input_file_path, output_file_path)
"""

"""
# square root the decimal
input_file_path = 'decimal.txt'
output_file_path = 'sqrt_decimal.txt'
sqrt_values_from_file(input_file_path, output_file_path)
"""

"""
# convert posit sqrt output to decimal
input_file_path = 'sqrt_output.txt'
output_file_path = 'sqrt_output_decimal.txt'
convert_posit_file(input_file_path, output_file_path)
"""

"""
# convert softposit sqrt output to decimal
input_file_path = 'data_test4/softposit_sqrt_output.txt'
output_file_path = 'data_test4/softposit_sqrt_output_decimal.txt'
convert_posit_file(input_file_path, output_file_path)
"""

"""
# square root using softposit
input_file_path = 'decimal.txt'
output_file_path = 'softposit_sqrt_output_decimal.txt'
softposit_sqrt(input_file_path, output_file_path)
"""

"""
# find difference 
file1_path = 'sqrt_decimal.txt'
file2_path = 'sqrt_output_decimal.txt'
error_path = 'error.txt'
write_error_differences(file1_path, file2_path, error_path)
"""

"""
# find difference from softposit sqrt
file1_path = 'sqrt_decimal.txt'
file2_path = 'softposit_sqrt_output_decimal.txt'
error_path = 'softposit_error.txt'
write_error_differences(file1_path, file2_path, error_path)
"""

"""
# find difference from softposit sqrt and custom
file1_path = 'softposit_sqrt_output_decimal.txt'
file2_path = 'sqrt_output_decimal.txt'
error_path = 'compare_error.txt'
write_error_differences(file1_path, file2_path, error_path)
"""

"""
# find max and min
input_file_path = 'data_test4/compare_error.txt'
find_max_min_in_file(input_file_path)
"""





