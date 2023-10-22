#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <bitset>

int main()
{
    std::ifstream file("in21.txt"); // 打开文本文件

    if (!file.is_open())
    {
        std::cerr << "无法打开文件" << std::endl;
        return 1;
    }

    std::vector<uint32_t> binary_data; // 用于存储读取的二进制数据

    std::string line;
    // while (std::getline(file, line)) {  // 按行读取文件内容
    for (int i = 0; i < 10; i++)
    {
        std::cout << "check point 1" << std::endl;
        std::getline(file, line);
        // if (line.size() == 34)
        // {                                                      // 确保每行包含32个0或1
            uint32_t value = std::bitset<32>(line).to_ulong(); // 将二进制字符串转换为 uint32_t
            binary_data.push_back(value);
            std::cout << value << std::endl;
        // }
        // else
        // {
        //     std::cout << "line size error" << std::endl;
        // }
    }

    file.close(); // 关闭文件

    // 打印读取的 uint32_t 数据
    for (uint32_t value : binary_data)
    {
        std::cout << "读取的值: " << value << std::endl;
    }

    return 0;
}