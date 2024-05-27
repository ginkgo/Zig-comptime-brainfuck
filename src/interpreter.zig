const std = @import("std");
const bf = @import("brainfuck.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const args = try std.process.argsAlloc(allocator);
    defer allocator.free(args);

    const brainfuck_code = try std.fs.cwd().readFileAlloc(allocator, args[1], 1024 * 1024 * 1024);
    defer allocator.free(brainfuck_code);

    try bf.interpret_brainfuck(brainfuck_code);
}
