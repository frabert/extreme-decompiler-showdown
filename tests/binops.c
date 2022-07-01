int printf(const char*, ...);

unsigned int target(unsigned int n) {
  unsigned int mod = n % 4;
  unsigned int result = 0;

  if (mod == 0) {
    result = (n | 0xbaaad0bf) * (2 ^ n);
    printf("a\n");
  } else if (mod == 1) {
    result = (n & 0xbaaad0bf) * (3 + n);
    printf("b\n");
  } else if (mod == 2) {
    result = (n ^ 0xbaaad0bf) * (4 | n);
    printf("c\n");
  } else {
    result = (n + 0xbaaad0bf) * (5 & n);
    printf("d\n");
  }

  return result;
}

int main(void) { return target(0xdeadbeef); }
