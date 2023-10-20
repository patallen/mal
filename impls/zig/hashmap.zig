const std = @import("std");
const types = @import("./types.zig");

const ObjStringContext = struct {
    pub fn hash(self: @This(), s: *types.MalObject.String) u64 {
        _ = self;
        return s.hash;
    }
    pub fn eql(self: @This(), a: *types.MalObject.String, b: *types.MalObject.String) bool {
        _ = self;
        return std.hash_map.eqlString(a.bytes, b.bytes);
    }
};

pub fn ObjStringHashMap(comptime V: type) type {
    return std.HashMap(
        *types.MalObject.String,
        V,
        ObjStringContext,
        std.hash_map.default_max_load_percentage,
    );
}

test ObjStringHashMap {
    const MashHap = ObjStringHashMap(types.MalValue);
    var hm = MashHap.init(std.testing.allocator);
    defer hm.deinit();

    var string: *types.MalObject.String = try types.MalObject.String.init(std.testing.allocator, "mal key");
    defer string.deinit(std.testing.allocator);

    try hm.put(string, types.MalValue.number(69));
    try std.testing.expectEqual(hm.unmanaged.size, 1);
    try std.testing.expectEqual(hm.get(string).?.number, 69);
}
