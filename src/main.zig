const std = @import("std");
const bf = @import("brainfuck.zig");

pub fn main() !void {
    try bf.interpret_brainfuck(@embedFile("../test/hanoi.b"));
}
