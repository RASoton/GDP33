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
    unsigned input;
    cout << "Input = ";
    cin >>input;
    posit32_t a = castP32(input);
    printBinary((uint64_t *)&a.v, 32);
    double b = convertP32ToDouble(a);
    std::cout << std::showpoint << std::fixed << std::setprecision(55) << ": " << b << ",";
    // // std::random_device rd;
    // auto currentTime = std::chrono::system_clock::now();

    // // 转换为毫秒
    // auto milliseconds = std::chrono::duration_cast<std::chrono::milliseconds>(currentTime.time_since_epoch());

    // // 获取毫秒数作为种子
    // unsigned long seed = static_cast<unsigned long>(milliseconds.count());

    // std::default_random_engine generator(seed);
    // std::uniform_int_distribution<int> distribution(-1, 1); // 范围：(0, 1]

    // for(int i = 0; i < 10; i++)
    // {
    //     cout << (int)distribution(generator) << endl;
    // }

    return 0;
}