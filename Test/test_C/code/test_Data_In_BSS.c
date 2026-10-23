volatile unsigned int zero_initialized_data;

int main(void)
{
    return zero_initialized_data == 0
        ? 0x12345678
        : 0x87654321;
}