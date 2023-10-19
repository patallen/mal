const std = @import("std");
const types = @import("./types.zig");

const MalValue = types.MalValue;

const Error = error{OutOfMemory};

pub fn printStr(writer: std.ArrayList(u8).Writer, value: MalValue) Error!void {
    switch (value) {
        .number => try writer.print("{d}", .{value.number}),
        .object => switch (value.object.ty) {
            .list => try printList(writer, value),
            .string => try printString(writer, value),
            .symbol => try writer.print("{s}", .{value.object.asSymbolObject().name}),
        },
    }
}

pub fn printList(writer: std.ArrayList(u8).Writer, value: MalValue) Error!void {
    try writer.print("(", .{});
    var list = value.object.asListObject();
    for (list.values.items, 0..) |val, i| {
        if (i != 0) {
            try writer.print(" ", .{});
        }
        try printStr(writer, val);
    }
    try writer.print(")", .{});
}

pub fn printString(writer: std.ArrayList(u8).Writer, value: MalValue) Error!void {
    try writer.print("\"{s}\"", .{value.object.asStringObject().bytes});
}
