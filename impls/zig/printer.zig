const std = @import("std");
const types = @import("./types.zig");

const MalValue = types.MalValue;

const Error = error{OutOfMemory};

const ListishType = enum {
    list,
    vector,
};

pub fn printStr(writer: std.ArrayList(u8).Writer, value: MalValue) Error!void {
    switch (value) {
        .number => try writer.print("{d}", .{value.number}),
        .object => switch (value.object.ty) {
            .list => try printListish(writer, value, .list),
            .vector => try printListish(writer, value, .vector),
            .string => try printString(writer, value.object.asStringObject()),
            .symbol => try writer.print("{s}", .{value.object.asSymbolObject().name}),
            .hashmap => try printHashMap(writer, value),
        },
    }
}

pub fn printListish(writer: std.ArrayList(u8).Writer, value: MalValue, ty: ListishType) Error!void {
    switch (ty) {
        .list => try writer.print("(", .{}),
        .vector => try writer.print("[", .{}),
    }
    var list = value.object.asListObject();
    for (list.values.items, 0..) |val, i| {
        if (i != 0) {
            try writer.print(" ", .{});
        }
        try printStr(writer, val);
    }
    switch (ty) {
        .list => try writer.print(")", .{}),
        .vector => try writer.print("]", .{}),
    }
}

pub fn printHashMap(writer: std.ArrayList(u8).Writer, value: MalValue) Error!void {
    var hm = value.object.asHashMapObject();

    try writer.print("{{", .{});
    var i: usize = 0;
    var it = hm.data.iterator();
    while (it.next()) |entry| {
        if (i > 0) {
            try writer.print(" ", .{});
        }
        var k = entry.key_ptr.*;
        var v = entry.value_ptr;
        try printString(writer, k);
        try writer.print(" ", .{});
        try printStr(writer, v.*);
        i += 1;
    }
    try writer.print("}}", .{});
}

pub fn printString(writer: std.ArrayList(u8).Writer, strobj: *types.MalObject.String) Error!void {
    if (strobj.isKeyword) {
        try writer.print("{s}", .{strobj.bytes});
    } else {
        try writer.print("\"{s}\"", .{strobj.bytes});
    }
}
