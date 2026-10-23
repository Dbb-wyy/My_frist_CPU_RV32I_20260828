volatile const int test_data = 0x12345678;

int main(void)
{
    return test_data == 0x12345678 ? 0x12345678 : 0x87654321;
}