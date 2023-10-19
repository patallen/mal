const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn copyString(allocator: std.mem.Allocator, bytes: []const u8) ![]u8 {
    return try allocator.dupe(u8, bytes);
}

pub const ValueType = enum {
    number,
    object,
};

pub const MalValue = union(ValueType) {
    number: u64,
    object: *MalObject,

    pub fn number(value: u64) MalValue {
        return .{ .number = value };
    }

    pub fn object(value: *MalObject) MalValue {
        return .{ .object = value };
    }
};

pub const MalObject = struct {
    const Type = enum {
        symbol,
        list,
        string,
    };
    ty: Type,

    pub fn asStringObject(self: *MalObject) *String {
        return @fieldParentPtr(String, "obj", self);
    }

    pub fn asSymbolObject(self: *MalObject) *Symbol {
        return @fieldParentPtr(Symbol, "obj", self);
    }

    pub fn asListObject(self: *MalObject) *List {
        return @fieldParentPtr(List, "obj", self);
    }

    pub const String = struct {
        obj: MalObject,
        bytes: []const u8,

        pub fn init(allocator: Allocator, bytes: []const u8) !*MalObject.String {
            var new_buf = try copyString(allocator, bytes);
            var symbol = try allocator.create(String);
            symbol.obj = .{ .ty = .string };
            symbol.bytes = new_buf;
            return symbol;
        }

        pub fn deinit(self: *String, allocator: std.mem.Allocator) void {
            allocator.free(self.bytes);
            allocator.destroy(self);
        }
    };

    pub const Symbol = struct {
        obj: MalObject,
        name: []const u8,

        pub fn init(allocator: Allocator, name: []const u8) !*MalObject.Symbol {
            var new_buf = try copyString(allocator, name);
            var symbol = try allocator.create(Symbol);
            symbol.obj = .{ .ty = .symbol };
            symbol.name = new_buf;
            return symbol;
        }

        pub fn deinit(self: *Symbol, allocator: std.mem.Allocator) void {
            allocator.free(self.name);
            allocator.destroy(self);
        }
    };

    pub const List = struct {
        obj: MalObject,
        values: std.ArrayList(MalValue),

        pub fn init(allocator: Allocator) !*List {
            var arrlist = std.ArrayList(MalValue).init(allocator);
            var list = try allocator.create(List);
            list.* = .{
                .obj = .{ .ty = .list },
                .values = arrlist,
            };
            return list;
        }

        pub fn deinit(self: *List, allocator: Allocator) void {
            self.values.deinit();
            allocator.destroy(self);
        }

        pub fn append(self: *List, value: MalValue) !void {
            try self.values.append(value);
        }
    };
};

test "MalValue.number" {
    var numval = MalValue.number(100);
    try std.testing.expectEqual(numval.number, 100);
}

test "MalValue.object" {
    var obj = MalObject{ .ty = .symbol };
    var value = MalValue.object(&obj);
    try std.testing.expectEqual(value.object.ty, .symbol);
}

test "MalObject.String" {
    var string = try MalObject.String.init(std.testing.allocator, "My string");
    defer string.deinit(std.testing.allocator);

    var str = string.obj.asStringObject();

    try std.testing.expectEqualStrings(str.bytes, "My string");
}

test "MalObject.List" {
    var list = try MalObject.List.init(std.testing.allocator);
    defer list.deinit(std.testing.allocator);

    try list.append(MalValue.number(100));
    try list.append(MalValue.number(200));

    try std.testing.expectEqual(list.values.items[0].number, 100);
    try std.testing.expectEqual(list.values.items[1].number, 200);

    var listobj = list.obj.asListObject();
    try std.testing.expectEqual(listobj.values.items[1].number, 200);
}

test "MalObject.Symbol" {
    var symbol = try MalObject.Symbol.init(std.testing.allocator, "fart");
    defer symbol.deinit(std.testing.allocator);

    var sym = symbol.obj.asSymbolObject();

    try std.testing.expectEqualStrings(sym.name, "fart");
}
