const std = @import("std");
const testing = std.testing;
const unicode = @import("std").unicode;

const cstdio = @cImport({
    @cInclude("stdio.h");
});

const BrainFuckInstr = union(enum) {
    inc_ptr: void,
    dec_ptr: void,
    inc_data: void,
    dec_data: void,
    putc: void,
    getc: void,
    block: []const BrainFuckInstr,
};

fn parse_brainfuck_block(allocator: std.mem.Allocator, iterator: *unicode.Utf8Iterator, level: u32) ![]BrainFuckInstr {
    var parsed_brainfuck = std.ArrayList(BrainFuckInstr).init(allocator);

    while (iterator.nextCodepoint()) |char| {
        switch (char) {
            '>' => try parsed_brainfuck.append(.inc_ptr),
            '<' => try parsed_brainfuck.append(.dec_ptr),
            '+' => try parsed_brainfuck.append(.inc_data),
            '-' => try parsed_brainfuck.append(.dec_data),
            '.' => try parsed_brainfuck.append(.putc),
            ',' => try parsed_brainfuck.append(.getc),
            '[' => try parsed_brainfuck.append(.{ .block = try parse_brainfuck_block(allocator, iterator, level + 1) }),
            ']' => {
                if (level > 0) {
                    return parsed_brainfuck.toOwnedSlice();
                } else {
                    return error.MismatchedParens;
                }
            },
            else => {},
        }
    }

    if (level == 0) {
        return parsed_brainfuck.toOwnedSlice();
    } else {
        return error.MismatchedParens;
    }
}

fn parse_brainfuck(allocator: std.mem.Allocator, brainfuck_code: []const u8) ![]BrainFuckInstr {
    var iterator = (try unicode.Utf8View.init(brainfuck_code)).iterator();
    return parse_brainfuck_block(allocator, &iterator, 0);
}

const BrainfuckInterpreter = struct {
    ptr: [*]u8,

    pub fn init(ptr: [*]u8) BrainfuckInterpreter {
        return BrainfuckInterpreter{ .ptr = ptr };
    }

    pub fn interpret_brainfuck_block(self: *BrainfuckInterpreter, brainfuck: []const BrainFuckInstr) void {
        for (brainfuck) |instr| {
            switch (instr) {
                .inc_ptr => {
                    self.ptr = self.ptr + 1;
                },
                .dec_ptr => {
                    self.ptr = self.ptr - 1;
                },
                .inc_data => {
                    self.ptr[0] += 1;
                },
                .dec_data => {
                    self.ptr[0] -= 1;
                },
                .putc => {
                    _ = cstdio.putchar(self.ptr[0]);
                },
                .getc => {
                    self.ptr[0] = @intCast(cstdio.getchar());
                },
                .block => |bf| {
                    while (self.ptr[0] != 0) {
                        self.interpret_brainfuck_block(bf);
                    }
                },
            }
        }
    }
};

pub fn interpret_brainfuck(brainfuck_code: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const brainfuck = try parse_brainfuck(allocator, brainfuck_code);

    var buffer = [_]u8{0} ** 30000;
    var interpreter = BrainfuckInterpreter.init(&buffer);

    interpreter.interpret_brainfuck_block(brainfuck);
}

pub fn interpret_parsed_brainfuck(brainfuck: []const BrainFuckInstr) !void {
    var buffer = [_]u8{0} ** 30000;
    var interpreter = BrainfuckInterpreter.init(&buffer);

    interpreter.interpret_brainfuck_block(brainfuck);
}

fn comptime_parse_brainfuck_block(comptime brainfuck_code: []const u8, offset: *usize, level: usize) ![]const BrainFuckInstr {
    comptime var brainfuck: []const BrainFuckInstr = &.{};

    while (offset.* < brainfuck_code.len) {
        const char = brainfuck_code[offset.*];
        offset.* += 1;
        switch (char) {
            '>' => {
                brainfuck = append(.inc_ptr, brainfuck);
            },
            '<' => {
                brainfuck = append(.dec_ptr, brainfuck);
            },
            '+' => {
                brainfuck = append(.inc_data, brainfuck);
            },
            '-' => {
                brainfuck = append(.dec_data, brainfuck);
            },
            '.' => {
                brainfuck = append(.putc, brainfuck);
            },
            ',' => {
                brainfuck = append(.getc, brainfuck);
            },
            '[' => {
                brainfuck = append(.{ .block = try comptime_parse_brainfuck_block(brainfuck_code, offset, level + 1) }, brainfuck);
            },
            ']' => {
                if (level > 0) {
                    return brainfuck;
                } else {
                    return error.MismatchedParens;
                }
            },
            else => {},
        }
    }

    if (level == 0) {
        return brainfuck;
    } else {
        return error.MismatchedParens;
    }
}

fn append(comptime instr: BrainFuckInstr, comptime list: []const BrainFuckInstr) []const BrainFuckInstr {
    return list ++ @as([]const BrainFuckInstr, &.{instr});
}

pub fn comptime_parse_brainfuck(comptime brainfuck_code: []const u8) ![]const BrainFuckInstr {
    var offset: usize = 0;
    return comptime_parse_brainfuck_block(brainfuck_code, &offset, 0);
}

pub fn compile_brainfuck(comptime brainfuck_code: []const u8) type {
    @setEvalBranchQuota(1000000);
    const brainfuck = try comptime_parse_brainfuck(brainfuck_code);
    return compile_brainfuck_block(brainfuck);
}

pub fn compile_brainfuck_block(comptime brainfuck: []const BrainFuckInstr) type {
    @setEvalBranchQuota(1000000);
    return struct {
        ptr: [*]u8,

        pub fn execute(in_ptr: [*]u8) [*]u8 {
            var ptr = in_ptr;
            inline for (brainfuck) |instr| {
                switch (instr) {
                    .inc_ptr => {
                        ptr = ptr + 1;
                    },
                    .dec_ptr => {
                        ptr = ptr - 1;
                    },
                    .inc_data => {
                        ptr[0] += 1;
                    },
                    .dec_data => {
                        ptr[0] -= 1;
                    },
                    .putc => {
                        _ = cstdio.putchar(ptr[0]);
                    },
                    .getc => {
                        ptr[0] = @intCast(cstdio.getchar());
                    },
                    .block => |bf| {
                        const block = compile_brainfuck_block(bf);
                        while (ptr[0] != 0) {
                            ptr = block.execute(ptr);
                        }
                    },
                }
            }
            return ptr;
        }
    };
}

test "parsing test" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try testing.expectEqualDeep(try parse_brainfuck(allocator, "[->+<]😹"), &[_]BrainFuckInstr{
        .{
            .block = &[_]BrainFuckInstr{
                .dec_data,
                .inc_ptr,
                .inc_data,
                .dec_ptr,
            },
        },
    });
}
