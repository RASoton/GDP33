

#include <stdio.h>
#include <stdlib.h>

union PositBinary {
    float f;
    unsigned int i;
};

void solve_quadratic(union PositBinary a, union PositBinary b, union PositBinary c){
    union PositBinary two, four, discriminant, sqrt_discriminant, root1, root2;
    two.i = 0x48000000; // Posit representation of 2
    four.i = 0x50000000; // Posit representation of 4

    discriminant.f = b.f * b.f - four.f * a.f * c.f;
    if (discriminant.f < 0) {
        printf("No real roots.\n");
        return;
    }

    __asm__ ("fsqrt.s %0, %1" : "=f" (sqrt_discriminant.f) : "f" (discriminant.f));
  
    root1.f = (-b.f + sqrt_discriminant.f) / (two.f * a.f);
    root2.f = (-b.f - sqrt_discriminant.f) / (two.f * a.f);
  
    printf("Roots: %08x, %08x\n", root1.i, root2.i); // Answer in Posit hex representation
}

int main(int argc, char *argv[])
{
    union PositBinary a, b, c;
    // Roundabout way to assign Posit values
    a.i = 0x4c000000; // Posit representation of 3
    b.i = 0x6a400000; // Posit representation of 100
    c.i = 0x48000000; // Posit representation of 2 

    solve_quadratic(a, b, c);
    //root1 = e6e07d55 = -0.0200120
    //root2 = 9bd5f945 = -33.313321

    return EXIT_SUCCESS;
}


