#include <iostream>
#include <bitset>
#include <string>

using namespace std;

int transfer();
int Separate();
void decimal_To_Binary(unsigned &binaryResult, int decimalNumber);

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
    decimal_To_Binary(output, temp);
    cout << "32-bit Binay form: " << bitset<32>(output) << endl;

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
    double decimal_number;

    // Enter a Decimal number
    cout << "Enter a Decimal number (Integer/non-Integer)";
    cin >> decimal_number;

    // Transfer the input to string 
    string decimal_string = to_string(decimal_number);

    // find the position of the decimal point
    size_t decimal_Point_Posistion = decimal_string.find('.');

    unsigned unsigned_Integer_Part;
    unsigned unsigned_Decimal_Part;

    // if the input is not a integer
    if (decimal_Point_Posistion != string::npos)
    {
        string integerPart = decimal_string.substr(0, decimal_Point_Posistion);
        unsigned_Integer_Part = stoul(integerPart);

        string decimalPart = decimal_string.substr(decimal_Point_Posistion + 1);
        unsigned_Decimal_Part = stoul(decimalPart);

        cout << "Integer Part: " << unsigned_Integer_Part << endl;
        cout << "Decimal Part: " << unsigned_Decimal_Part << endl;
        // return unsigned_Integer_Part;
    }
    else
    {
         unsigned_Integer_Part = stoul(decimal_string);
        cout << "Integer Part: " << unsigned_Integer_Part << endl;
        cout << "No Decimal Part" << endl;
        // return unsigned_Integer_Part;
    }
        return unsigned_Integer_Part;

    // return 0;
}

void decimal_To_Binary(unsigned &binary_Result, int decimal_Number)
{
    binary_Result = 0;

    int bit_Position = 0;

    while (decimal_Number > 0)
    {
        int remainder = decimal_Number % 2;
        binary_Result += remainder << bit_Position;
        decimal_Number /= 2;
        ++bit_Position;
    }
}