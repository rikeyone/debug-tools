CC=gcc
CFLAG=-g -Wall
SRC=$(wildcard *.c)
BIN=$(patsubst %.c,%,$(SRC))

all:$(BIN)

$(BIN): %:%.c
	$(CC) $(CFLAG) $< -o $@ 
