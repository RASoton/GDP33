#include <iostream>
#include <fstream>
#include <string>
#include <algorithm>

int main() {
    std::ifstream inputFile("result.txt"); // 打开要处理的文本文件
    std::ofstream outputFile("answer.txt"); // 创建一个新的输出文件

    if (!inputFile.is_open() || !outputFile.is_open()) {
        std::cerr << "无法打开文件" << std::endl;
        return 1;
    }

    std::string line;
    while (std::getline(inputFile, line)) { // 逐行读取文件内容
        // 使用算法库函数std::remove_if和lambda函数去除空格
        line.erase(std::remove_if(line.begin(), line.end(), [](char c) { return std::isspace(c); }), line.end());
        
        outputFile << line << '\n'; // 写入新行
    }

    inputFile.close();
    outputFile.close();

    std::cout << "已删除所有空格，结果保存在output.txt" << std::endl;

    return 0;
}