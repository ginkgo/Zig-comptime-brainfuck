#!/usr/bin/env bash

gcc ./brainfucc.c -o brainfucc

./brainfucc <../test/hello.b >hello.c
gcc ./hello.c -O3 -o hello

./brainfucc <../test/hanoi.b >hanoi.c
gcc ./hanoi.c -O3 -o hanoi

./brainfucc <../test/mandel.b >mandel.c
gcc ./mandel.c -O3 -o mandel
