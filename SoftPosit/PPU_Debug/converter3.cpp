#include "source/include/softposit.h"
#include <iostream>
#include <random>
#include <cstdlib>
#include <time.h>
#include <set>
#include <iomanip>
#include <windows.h>
#include <chrono>
#include <cmath>

using namespace std;

double rand_gen(double min, double max);

int main()
{
    // std::random_device rd;
    auto currentTime = std::chrono::system_clock::now();

    // 转换为毫秒
    auto milliseconds = std::chrono::duration_cast<std::chrono::milliseconds>(currentTime.time_since_epoch());

    // 获取毫秒数作为种子
    unsigned long seed = static_cast<unsigned long>(milliseconds.count());

    std::default_random_engine generator(seed);
    std::uniform_int_distribution<int> distribution(-10, 10); // 范围：(0, 1]

    double power;
    std::set<int> rand_power;
    // for(int i = -45; i <= 36; i++)
    for (int i = 0; i < 21;)
    {
        // Generate random power
        int temp = distribution(generator);

        // if not in rand_power list
        if(rand_power.find(temp) == rand_power.end())
        {
        power = pow(10, temp);
        // cout << power << endl;
        rand_gen(-1.33 * power, 1.33 * power);
        i++;
        }
    }
    return 0;
}

double rand_gen(double min, double max)
{
    // std::random_device rd;

    auto currentTime = std::chrono::system_clock::now();

    // 转换为毫秒
    auto milliseconds = std::chrono::duration_cast<std::chrono::milliseconds>(currentTime.time_since_epoch());

    // 获取毫秒数作为种子
    unsigned long seed = static_cast<unsigned long>(milliseconds.count());

    std::default_random_engine generator(seed);
    std::uniform_real_distribution<double> distribution(min, max); // 范围：(0, 1]

    // double temp = -1.33e36;

    std::set<double> uniqueNumbers; // 用于存储唯一随机数的集合

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

    posit32_t p1, p2;
    double random_value, temp;
    // Generage double in [min, max]
    int count = 1;
    for (int i = 0; i < 10000;)
    {
        random_value = distribution(generator);
        if (uniqueNumbers.find(random_value) == uniqueNumbers.end())
        {
            uniqueNumbers.insert(random_value);
            p1 = convertDoubleToP32(random_value);
            std::cout << std::showpoint << std::fixed << std::setprecision(55) << ": " << random_value << ",";
            printBinary((uint64_t *)&p1.v, 32);
            i++;
            Sleep(10);
        }
    }
    // double randomValue = distribution(generator);

    return 0;
}