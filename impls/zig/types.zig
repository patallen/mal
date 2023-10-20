const std = @import("std");
const Allocator = std.mem.Allocator;
const ObjStringHashMap = @import("./hashmap.zig").ObjStringHashMap;

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
        vector,
        string,
        hashmap,
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

    pub fn asVectorObject(self: *MalObject) *List {
        return @fieldParentPtr(Vector, "obj", self);
    }

    pub fn asHashMapObject(self: *MalObject) *HashMap {
        return @fieldParentPtr(HashMap, "obj", self);
    }

    pub const String = struct {
        obj: MalObject,
        bytes: []const u8,
        hash: u64,
        isKeyword: bool = false,

        pub fn init(allocator: Allocator, bytes: []const u8) !*MalObject.String {
            var new_buf = try copyString(allocator, bytes);
            var string = try allocator.create(String);
            string.obj = .{ .ty = .string };
            string.bytes = new_buf;
            string.hash = std.hash_map.hashString(new_buf);
            return string;
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

    pub const Vector = struct {
        obj: MalObject,
        values: std.ArrayList(MalValue),

        pub fn init(allocator: Allocator) !*Vector {
            var arrlist = std.ArrayList(MalValue).init(allocator);
            var list = try allocator.create(Vector);
            list.* = .{
                .obj = .{ .ty = .vector },
                .values = arrlist,
            };
            return list;
        }

        pub fn deinit(self: *Vector, allocator: Allocator) void {
            self.values.deinit();
            allocator.destroy(self);
        }

        // I think Vectors are meant to be a static-sized array, wheras Lists are
        // meant to be linked lists??
        pub fn append(self: *Vector, value: MalValue) !void {
            try self.values.append(value);
        }
    };

    pub const HashMap = struct {
        obj: MalObject,
        data: ObjStringHashMap(MalValue),

        pub fn init(allocator: Allocator) !*HashMap {
            var data = ObjStringHashMap(MalValue).init(allocator);
            var hm = try allocator.create(HashMap);
            hm.* = .{
                .obj = .{ .ty = .hashmap },
                .data = data,
            };
            return hm;
        }

        pub fn deinit(self: *HashMap, allocator: Allocator) void {
            self.data.deinit();
            allocator.destroy(self);
        }

        pub fn put(self: *HashMap, key: *String, value: MalValue) !void {
            try self.data.put(key, value);
        }

        pub fn get(self: *HashMap, key: *String) ?MalValue {
            return self.data.get(key);
        }
    };
};

test "MalValue.number" {
    var numval = MalValue.number(100);
    try std.testing.expectEqual(numval.number, 100);
}

test "HashMap" {
    var hm = try MalObject.HashMap.init(std.testing.allocator);
    var key = try MalObject.String.init(std.testing.allocator, "hello");
    defer key.deinit(std.testing.allocator);
    defer hm.deinit(std.testing.allocator);

    try hm.put(key, MalValue.number(60));

    var val = hm.get(key).?;
    try std.testing.expectEqual(val.number, 60);

    var it = hm.data.iterator();
    while (it.next()) |entry| {
        var k = entry.key_ptr.*;
        var v = entry.value_ptr;
        std.debug.print("{s}: {d}\n", .{ k.bytes, v.number });
    }
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
