# Zig comptime Brainfuck compiler

This is mostly a proof-of-concept for taking a piece of Brainfuck code and using Zig comptime to convert it into a native code.

This works by loading a brainfuck program and passing it to a compiler function that generates a runner that can be called with pointer to the initialized byte table.
```
const bf = @import("brainfuck.zig");

pub fn main() !void {
    var buffer = [_]u8{0} ** 30000;
    const bf_runner = bf.compile_brainfuck(@embedFile("test/hanoi.b"));
    _ = bf_runner.execute(&buffer);
}
```

You can find most of the implementation in `src/brainfuck.zig`. The other Zig files in `src/` contain the `main()` functions for the various generated executables.

For comparison, and also as a first step to this I've also implemented a basic runtime parser and interpreter.

## Building

I recommend building for performance:
```
$ zig build -Doptimize=ReleaseFast
```

You can then run the generated binaries:
```
$ ls zig-out/bin/
brainfuck_interpreter  hanoi  hello  mandel
```

`brainfuck_interpreter` is the runtime interpreter. You can run any brainfuck program with it:
```
$ zig-out/bin/brainfuck_interpreter src/test/hello.b
Hello World!
```

The others are the compiled versions that can be run directly:
```
$ zig-out/bin/hello
Hello World!
```

## Performance

The resulting binaries are very fast. `hanoi` and obviously `hello` complete almost instantly. `mandel` takes a bit over 1.5 seconds.
```
$ time zig-out/bin/mandel >/dev/null

real	0m1.543s
user	0m1.535s
sys	0m0.009s
```

This is way faster than my interpreter at least:
```
$ time zig-out/bin/brainfuck_interpreter src/test/mandel.b >/dev/null

real	0m35.028s
user	0m35.002s
sys	0m0.015s
```

I also compared it to Brainfuck transpiled with brainfucc to C and compiled with GCC and -O3. The results seem very similar. `hello` and `hanoi` basically complete instantly and `mandel` takes slightly longer (although I could probably tweak compiler settings).
```
$ cd brainfucc/
$ ./build.sh
$ time ./mandel >/dev/null

real	0m1.701s
user	0m1.684s
sys	0m0.013s
```

One thing the brainfucc compiled binaries have over the Zig ones is that they're a lot smaller. (15-64KB vs ~1MB)
Compilation take quite some time. I also had to crank up the `@setEvalBranchQuota()` value quite a bit (not that I exactly know what it is).

## Copyright

All Zig code is either generated by `zig init` or written by me. It can be used and re-licensed under the terms of the MIT license.

The `hello.b` is from the [Brainfuck](https://en.wikipedia.org/wiki/Brainfuck#Hello_World!) Wikipedia article. `hanoi.b` has been written by [Clifford Wolf](https://clifford.at). `mandel.b` has been written by Erik Bosman.

The `brainfucc.c` transpiler has been written by Cory Burgett.
