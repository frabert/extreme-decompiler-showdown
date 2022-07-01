int a[2] = {0, 42};
int printf(const char*, ...);

int main(void) {
  int b = a[0];
  a[0] = a[1];
  a[1] = b;
  printf("%d %d\n", a[0], a[1]);
  return a[0];
}