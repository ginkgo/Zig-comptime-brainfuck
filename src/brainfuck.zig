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
