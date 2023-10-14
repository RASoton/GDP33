#include <iostream>
#include <random>
#include <set>
#include <iomanip>
#include <windows.h>
#include <chrono>

int main()
{
    // std::random_device rd;

    auto currentTime = std::chrono::system_clock::now();

    // 转换为毫秒
    auto milliseconds = std::chrono::duration_cast<std::chrono::milliseconds>(currentTime.time_since_epoch());

    // 获取毫秒数作为种子
    unsigned long seed = static_cast<unsigned long>(milliseconds.count());

    std::default_random_engine generator(seed);
    std::uniform_real_distribution<double> distribution(0.0, 0.5); // 范围：(0, 1]

    std::set<double> uniqueNumbers; // 用于存储唯一随机数的集合

    while (uniqueNumbers.size() < 20)
    {
        double randomValue = distribution(generator);
        std::cout << std::showpoint << std::fixed << std::setprecision(25) << ": " << randomValue << std::endl;

        // 检查随机数是否已存在
        // if (uniqueNumbers.find(randomValue) == uniqueNumbers.end()) {
        uniqueNumbers.insert(randomValue);
        Sleep(10);
        // }
    }

    // // 输出生成的不同的双精度浮点数
    // int count = 1;
    // for (double number : uniqueNumbers)
    // {
    //     std::cout << std::showpoint << std::fixed << std::setprecision(25) << ": " << number << std::endl;
    //     count++;
    // }

    return 0;
}