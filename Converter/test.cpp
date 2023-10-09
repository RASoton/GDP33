#include <iostream>
#include <bitset>
#include <string>

using namespace std;

int transfer();
int Separate();
void decimalToBinary(unsigned &binaryResult, int decimalNumber);

int main()
{
    // bool a, b;
    // cout << "input b = ";
    // cin >> b;
    // a = ~b;
    // cout << sizeof(b) << endl;
    // cout << a << endl;
    // cout << bitset<10>(b) << "," << bitset<10>(a) << endl;
    // transfer();
    unsigned temp = Separate();
    unsigned output;
    decimalToBinary(output, temp);
    cout << "二进制表示: " << bitset<32>(output) << endl;

        return 0;
}

int transfer()
{
    int32_t integer;
    uint32_t fraction;
    cin >> integer >> fraction;
    cout << integer << "." << fraction << endl;
    cout << bitset<32>(integer + fraction) << endl;

    return 0;
}

int Separate()
{
    double decimalNumber;

    // 输入十进制小数
    std::cout << "输入一个十进制小数: ";
    std::cin >> decimalNumber;

    // 将小数转换为字符串
    std::string decimalString = std::to_string(decimalNumber);

    // 查找小数点的位置
    size_t decimalPointPos = decimalString.find('.');

    unsigned unsignedIntegerPart;

    // 如果找到小数点
    if (decimalPointPos != std::string::npos)
    {
        // 提取整数部分并转换为无符号整数
        std::string integerPart = decimalString.substr(0, decimalPointPos);
        unsignedIntegerPart = std::stoul(integerPart);

        // 提取小数部分并转换为无符号整数
        std::string decimalPart = decimalString.substr(decimalPointPos + 1);
        unsigned unsignedDecimalPart = std::stoul(decimalPart);

        // 输出结果
        std::cout << "整数部分: " << unsignedIntegerPart << std::endl;
        std::cout << "小数部分: " << unsignedDecimalPart << std::endl;
        // return unsignedIntegerPart;
    }
    else
    {
        // 如果没有小数点，则整个数为整数部分
         unsignedIntegerPart = std::stoul(decimalString);
        std::cout << "整数部分: " << unsignedIntegerPart << std::endl;
        std::cout << "小数部分: 0" << std::endl;
        // return unsignedIntegerPart;
    }
        return unsignedIntegerPart;

    // return 0;
}

void decimalToBinary(unsigned &binaryResult, int decimalNumber)
{
    binaryResult = 0; // 初始化二进制结果为0

    int bitPosition = 0; // 位的位置

    while (decimalNumber > 0)
    {
        // 取出最低位
        int remainder = decimalNumber % 2;

        // 将最低位加入二进制结果
        binaryResult += remainder << bitPosition;

        // 右移十进制数，准备处理下一位
        decimalNumber /= 2;

        // 增加位的位置
        ++bitPosition;
    }
}