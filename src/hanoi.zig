const std = @import("std");
const bf = @import("brainfuck.zig");

pub fn main() !void {
    var buffer = [_]u8{0} ** 30000;
    const bf_runner = bf.compile_brainfuck(@embedFile("test/hanoi.b"));
    _ = bf_runner.execute(&buffer);
}
