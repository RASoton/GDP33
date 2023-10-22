#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <bitset>
#include <windows.h>

#include "source/include/softposit.h"

int main()
{
    std::ifstream file_in1("in1_fin.txt"); // 打开文本文件 in1_fin.txt
    std::ifstream file_in2("in2_fin.txt"); // 打开文本文件 in2_fin.txt
    

    if (!file_in1.is_open())
    {
        std::cerr << "无法打开 in1_fin" << std::endl;
        return 1;
    }

    if (!file_in2.is_open())
    {
        std::cerr << "无法打开 in2_fin" << std::endl;
        return 1;
    }

    std::string line_in1;
    std::string line_in2;

    posit32_t pin1, pin2, pout;

    while (std::getline(file_in1, line_in1)) {  // 按行读取文件内容
    // for (int i = 0; i < 10; i++)
    // {
    //     std::getline(file_in1, line_in1);
        std::getline(file_in2, line_in2);
                                                    // 确保每行包含32个0或1
            uint32_t value_in1 = std::bitset<32>(line_in1).to_ulong(); // 将二进制字符串转换为 uint32_t
            uint32_t value_in2 = std::bitset<32>(line_in2).to_ulong(); // 将二进制字符串转换为 uint32_t
            
            pin1 = castP32(value_in1);
            pin2 = castP32(value_in2);

            pout = p32_add(pin1,pin2);

            // printBinary((uint64_t *)&pin1.v, 32);
            // printBinary((uint64_t *)&pin2.v, 32);
            printBinary((uint64_t *)&pout.v, 32);
            // Sleep(1000);
    }

    file_in1.close(); // close file
    file_in2.close(); // close file
    return 0;
}