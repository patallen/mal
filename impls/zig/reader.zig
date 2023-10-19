const types = @import("./types.zig");
const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Token = struct {
    pub const Type = enum {
        invalid,
        valid,
        eof,
    };
    pub const Loc = struct {
        start: usize,
        end: usize,
    };
    ty: Type,
    loc: Loc,
    slice: []const u8,
};

pub const Tokenizer = struct {
    start: usize = 0,
    current: usize = 0,
    source: []const u8,

    const Self = @This();

    pub fn nextToken(self: *Self) ?Token {
        // eof
        if (self.current >= self.source.len) {
            return self.makeToken(.eof);
        }
        var current = self.advance();
        switch (current) {
            '\n', ' ', '\t', ',', '\r' => {
                self.skipWhitespace();
                return self.nextToken();
            },
            '(', ')', '[', ']', '{', '}' => {
                self.current -= 1;
                return self.makeToken(.valid);
            },
            '~' => {
                if (self.peekNext() == '@') self.current += 1;
                return self.makeToken(.valid);
            },
            '"' => return self.string(),
            ';' => return self.comment(),
            else => {
                return self.nonSpecial();
            },
        }
    }

    fn nonSpecial(self: *Self) Token {
        while (true) {
            if (self.current >= self.source.len) {
                self.current -= 1;
                return self.makeToken(.valid);
            }
            var current = self.peek();
            if (self.isSpecial(current) or
                isWhitespace(current))
            {
                self.current -= 1;
                return self.makeToken(.valid);
            }
            self.current += 1;
        }
    }

    fn isSpecial(self: *Self, ch: u8) bool {
        _ = self;
        return switch (ch) {
            '[', ']', '(', ')', '~', '@', '{', '}', '`', '^' => true,
            else => false,
        };
    }
    fn isNonSpecial(self: *Self, ch: u8) bool {
        return !self.isSpecial(ch);
    }

    fn comment(self: *Self) Token {
        while (self.peek() != '\n') {
            self.current += 1;
        }
        return self.makeToken(.valid);
    }

    fn skipWhitespace(self: *Self) void {
        while (isWhitespace(self.peek())) {
            self.current += 1;
        }
        self.start = self.current;
    }

    fn isWhitespace(ch: u8) bool {
        return switch (ch) {
            '\n', '\t', ' ', '\r', ',' => true,
            else => false,
        };
    }

    fn string(self: *Self) Token {
        while (true) {
            if (self.current >= self.source.len or self.peek() == '\n') {
                return self.makeToken(.invalid);
            }
            switch (self.peek()) {
                '"' => {
                    if (self.peekPrev() == '\\') {} else {
                        var tok = self.makeToken(.valid);
                        self.current += 1;
                        return tok;
                    }
                },
                else => {},
            }
            self.current += 1;
        }
    }

    fn advance(self: *Self) u8 {
        self.current += 1;
        return self.source[self.current - 1];
    }

    fn makeToken(self: *Self, ty: Token.Type) Token {
        self.current += 1;
        var token = Token{
            .ty = ty,
            .loc = .{ .start = self.start, .end = self.current },
            .slice = self.source[self.start..self.current],
        };
        self.start = self.current;
        return token;
    }

    fn peek(self: *Self) u8 {
        return self.source[self.current];
    }

    fn peekPrev(self: *Self) u8 {
        return self.source[self.current - 1];
    }

    fn peekNext(self: *Self) u8 {
        return self.source[self.current + 1];
    }
};

pub const Reader = struct {
    tokenizer: Tokenizer,

    prev: Token = undefined,
    current: Token = undefined,

    const Self = @This();

    pub fn init(source: []const u8) Self {
        var reader = Reader{ .tokenizer = .{ .source = source } };
        _ = reader.next().?;
        return reader;
    }

    pub fn next(self: *Self) ?Token {
        var tok = self.tokenizer.nextToken();
        if (tok) |t| {
            self.prev = self.current;
            self.current = t;
            return self.current;
        }
        return null;
    }
};

test Tokenizer {
    var tokenizer = Tokenizer{ .source = "1234\n" };
    try std.testing.expectEqualSlices(u8, "1234", tokenizer.nextToken().?.slice);

    tokenizer = Tokenizer{ .source = "1\n" };
    try std.testing.expectEqualSlices(u8, "1", tokenizer.nextToken().?.slice);
}

const Error = error{ OutOfMemory, ReaderEOFError };

pub fn readForm(allocator: Allocator, reader: *Reader) Error!types.MalValue {
    // std.debug.print("READING FORM {s}\n", .{reader.current.slice});
    var token = reader.current;
    return switch (token.slice[0]) {
        '(' => try readList(allocator, reader),
        else => try readAtom(allocator, reader),
    };
}
pub fn readList(allocator: Allocator, reader: *Reader) Error!types.MalValue {
    // std.debug.print("-> LIST {s}\n", .{reader.current.slice});
    var list = try types.MalObject.List.init(allocator);
    _ = reader.next().?;
    while (reader.current.slice[0] != ')') {
        if (reader.current.ty == .eof) {
            std.debug.print("Expected ')', got EOF\n", .{});
            return error.ReaderEOFError;
        }
        try list.append(try readForm(allocator, reader));
    }
    _ = reader.next() orelse {};
    // std.debug.print("<- LIST {s}\n", .{reader.current.slice});
    return types.MalValue.object(&list.obj);
}

pub fn readAtom(allocator: Allocator, reader: *Reader) Error!types.MalValue {
    // std.debug.print("READING ATOM {s}\n", .{reader.current.slice});
    var data = reader.current.slice;
    _ = reader.next().?;
    if (data[0] == '"') {
        var string = try types.MalObject.String.init(allocator, data[1 .. data.len - 1]);
        return types.MalValue.object(&string.obj);
    }

    var integer = std.fmt.parseInt(u8, data, 10) catch {
        var sym = try types.MalObject.Symbol.init(allocator, data);
        return types.MalValue.object(&sym.obj);
    };

    return types.MalValue.number(integer);
}

test "printStr" {
    const printStr = @import("./printer.zig").printStr;

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    var reader = Reader.init("(defun add (a b) (+ a b)");
    var value = try readForm(arena.allocator(), &reader);

    var output = std.ArrayList(u8).init(arena.allocator());
    try printStr(output.writer(), value);
    std.debug.print("{s}\n", .{output.items});
}
