const std = @import("std");
const Reader = @import("./reader.zig").Reader;
const readForm = @import("./reader.zig").readForm;
const printStr = @import("./printer.zig").printStr;

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
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var output = std.ArrayList(u8).init(arena.allocator());

    var buf: [2048]u8 = undefined;
    while (true) {
        output.clearRetainingCapacity();
        try writer.print("user> ", .{});
        try out.flush();
        var input = try stdin.reader().readUntilDelimiter(&buf, '\n');
        var reader = Reader.init(input);
        var form = readForm(arena.allocator(), &reader) catch {
            try writer.print("Error: EOF\n", .{});
            continue;
        };

        try printStr(output.writer(), form);
        try writer.print("{s}\n", .{output.items});
        try out.flush();
    }
}
