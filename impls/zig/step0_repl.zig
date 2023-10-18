const std = @import("std");

fn READ(a: []u8) []u8 {
    return a;
}

fn EVAL(a: []u8) []u8 {
    return a;
}

fn PRINT(a: []u8) []u8 {
    return a;
}

fn rep(input: []u8) []u8 {
    var read_input = READ(input);
    var eval_input = EVAL(read_input);
    var print_input = PRINT(eval_input);
    return print_input;
}

pub fn main() !void {
    var stdin = std.io.getStdIn();
    var stdout = std.io.getStdOut();
    var out = std.io.bufferedWriter(stdout.writer());
    var writer = out.writer();

    var buf: [2048]u8 = undefined;
    while (true) {
        try writer.print("user> ", .{});
        try out.flush();
        var input = try stdin.reader().readUntilDelimiter(&buf, '\n');

        try writer.print("{s}\n", .{rep(input)});
        try out.flush();
    }
}
