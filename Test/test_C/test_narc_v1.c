#include <stdint.h>

int main() {
    uint16_t a[10];
    uint16_t i, j = 0, g, s, b;
    for (i = 100; i < 1000; i++) {
        g = i % 10;
        s = i / 10 % 10;
        b = i / 100;
        if (g * g * g + s * s * s + b * b * b == i) {
            a[j] = i;
            j++;
        }
    }
    return a[j-1];
}
