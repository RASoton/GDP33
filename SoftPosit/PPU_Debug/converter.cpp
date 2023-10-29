#include "source/include/softposit.h"
#include <iostream>
#include <random>
#include <windows.h>
#include <cstdlib>
#include <time.h>
#include <iostream>
#include <random>
#include <set>
#include <iomanip>
#include <windows.h>
#include <chrono>

using namespace std;

// double random_gen();
double rand_gen();

int main()
{
    // posit32_t in1, in2, out;

    // in1 = convertDoubleToP32(56.78);
    // in2 = convertDoubleToP32(67.89);

    // cout << "in1 = ";
    // printBinary((uint64_t *)&in1.v, 32);
    // cout << endl;
    // cout << "in2 = ";
    // printBinary((uint64_t *)&in2.v, 32);
    // cout << endl;

    // out = p32_add(in1, in2);
    // cout << "out = ";
    // printBinary((uint64_t *)&out.v, 32);
    // cout << endl;

    // out = convertDoubleToP32(56.78 + 67.89);
    // cout << "out = ";
    // printBinary((uint64_t *)&out.v, 32);
    // cout << endl;
    long long int i;
    long long int n = 50;

    double start = -1.33e36;
    double temp;

    posit32_t in1, in2, out;

    in2 = convertDoubleToP32(0);

    in1 = convertDoubleToP32(start);
    std::cout << std::showpoint << std::fixed << std::setprecision(25) << start;
    printBinary((uint64_t *)&in1.v, 32);
    // for (i = 0; i < n; i++)
    while(start < 1.33e36)
    {
        // in1 = convertDoubleToP32(random_gen());
        // printBinary((uint64_t *)&in1.v, 32);
        // cout << ",";
        // Sleep(1500);

        // in2 = convertDoubleToP32(random_gen());
        // printBinary((uint64_t *)&in2.v, 32);
        // cout << ",";
        // Sleep(1500);

        // out = p32_add(in1, in2);
        // printBinary((uint64_t *)&out.v, 32);
        // Sleep(1500);

        // cout << endl;
        temp = rand_gen();

        start += temp;


        in1 = convertDoubleToP32(start);

        if(!p32_eq(in1, in2))
        {
            std::cout << std::showpoint << std::fixed << std::setprecision(25) << temp << ", ";
            std::cout << std::showpoint << std::fixed << std::setprecision(25) << start << ",";
        printBinary((uint64_t *)&in1.v, 32);
        Sleep(50);
        start += 100;
        }
        in2 = in1;

    }

    return 0;
}

// double random()
// {
//     double RAND_MAX = 2 * 1.33e36;

//     cout << "RAND_MAX:" << RAND_MAX << endl;
//     srand((unsigned)time(NULL));
//     for (int i = 0; i < 5; i++)
//         cout << (rand() % 2) << " "; // 生成[0,1]范围内的随机数
//     cout << endl;
//     for (int i = 0; i < 5; i++)
//         cout << (rand() % 5 + 3) << " "; // 生成[3,7]范围内的随机数
//     cout << endl;
// }

// double random_gen()
// {
//     // 创建一个随机数生成器
//     std::random_device rd;
//     std::mt19937 gen(rd());

//     // 设置随机数的范围
//     std::uniform_real_distribution<double> distribution(-1.33e36, 1.33e36);

//     // 生成随机数
//     double random_number = distribution(gen);

//     // 输出随机数
//     // std::cout << "随机数: " << random_number << std::endl;
//     cout << random_number <<" ";
//     return random_number;
// }

double rand_gen()
{
    // std::random_device rd;

    auto currentTime = std::chrono::system_clock::now();

    // 转换为毫秒
    auto milliseconds = std::chrono::duration_cast<std::chrono::milliseconds>(currentTime.time_since_epoch());

    // 获取毫秒数作为种子
    unsigned long seed = static_cast<unsigned long>(milliseconds.count());

    std::default_random_engine generator(seed);
    std::uniform_real_distribution<double> distribution(0.0, 10); // 范围：(0, 1]

    // double temp = -1.33e36;

    // std::set<double> uniqueNumbers; // 用于存储唯一随机数的集合

    // while (uniqueNumbers.size() < 20)
    // for(int i = 0; i < 10; i++)
    // {
    //     double randomValue = distribution(generator);
    //     std::cout << std::showpoint << std::fixed << std::setprecision(25) << ": " << randomValue << std::endl;

    //     // 检查随机数是否已存在
    //     // if (uniqueNumbers.find(randomValue) == uniqueNumbers.end()) {
    //     // uniqueNumbers.insert(randomValue);
    //     Sleep(10);
    //     // }
    // }

    // // 输出生成的不同的双精度浮点数
    // int count = 1;
    // for (double number : uniqueNumbers)
    // {
    //     std::cout << std::showpoint << std::fixed << std::setprecision(25) << ": " << number << std::endl;
    //     count++;
    // }
    double randomValue = distribution(generator);

    return randomValue;
}