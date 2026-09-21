#include <stdint.h>
//#include <stdio.h>
static const uint8_t n = 5;
void swap(uint8_t *a,uint8_t *b){
    uint8_t t = *a;
    *a = *b;
    *b = t;
}
int main(){
    uint8_t a[5] = {0x5,0x2,0x3,0x4,0x1};
    uint8_t i,j;
    uint32_t r=0;
    for(i=0;i<n-1;i++){
        for(j=i+1;j<n;j++){
            if(a[i]>a[j])
            {
                swap(&a[i],&a[j]);
            }
        }
    }
    r += a[0];
    for(i=1;i<n;i++){
        
        r *= 0x10;
        r += a[i];
    }
    //printf("%X\n",r);
    return r;
}