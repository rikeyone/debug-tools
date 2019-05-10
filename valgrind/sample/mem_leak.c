#include <stdio.h>
#include <stdlib.h>
#include <string.h>


/*
 * This test program include two error:
 * 1. malloc but don't free (mem leak)
 * 2. mem access violation, heap block overrun
 */
int main (int argc, char *argv[])
{
	char *buf;
	buf = (char *)malloc(10); // problem 1
	buf[10] = 0;              //problem 2
	return 0;
}
