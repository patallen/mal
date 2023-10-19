const std = @import("std");

pub const ObjectType = enum {
    list,
    string,
};

pub const Object = struct {
    ty: ObjectType,
};

pub const ListObject = struct {
    obj: Object,
    id: u64,
    data: [10]u8,
};

test "ObjectList" {
    var allocator = std.testing.allocator;
    var list = try allocator.create(ListObject);
    defer allocator.destroy(list);
    list.* = .{
        .obj = .{ .ty = .list },
        .id = 420,
        .data = [_]u8{5} ** 10,
    };

    try std.testing.expectEqual(list.id, 420);
    try std.testing.expectEqual(list.data[0], 5);

    var repointed = @fieldParentPtr(ListObject, "obj", &list.obj);
    try std.testing.expectEqual(repointed.id, 420);
    try std.testing.expectEqual(repointed.data[0], 5);
}
