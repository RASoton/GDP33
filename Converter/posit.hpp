#ifndef _POSIT_H_
#define _POSIT_H_

#include <vector>
// test Pull
class posit
{
private:
    std::vector<bool> regime;
    std::vector<bool> exp;
    std::vector<bool> frac;

    void dec2bin();

public:
    posit();
    posit(int integer, int decimal);

    void P2F();
    void F2P();
    void P2D();
    void D2P();

};

posit::posit()
{
    regime = {1,0};
    exp = {0,0,0,0};
    frac = {0};
}

posit::posit(int integer, unsigned decimal)
{
    // change int to usinged-int and a sign bit

    // change the decimal to 
}

void posit::P2F()
{}

void posit::F2P()
{}

void posit::P2D()
{}

void posit::D2P()
{}

// Private
void posit::dec2bin()
{

}

#endif //_POSIT_H_