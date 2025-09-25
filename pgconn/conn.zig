const std = @import("std");
const printd = std.debug.print;
const cfg = @import("./config.zig");
const mem = std.mem;
const expect = std.testing.expect;

const Pgconn = struct {
    conn: std.net.Stream,
};

test "database url tokenizing" {
    const dataURL = "postgres://user:pass@host:port/database";

    var f = mem.tokenizeAny(u8, dataURL, ":/@");

    while (f.next()) |val| {
        try expect(@TypeOf(val) == []const u8);
    }

    f.reset();
    try expect(mem.eql(u8, f.next().?, "postgres"));
    try expect(mem.eql(u8, f.next().?, "user"));
    try expect(mem.eql(u8, f.next().?, "pass"));
    try expect(mem.eql(u8, f.next().?, "host"));
    try expect(mem.eql(u8, f.next().?, "port"));
    try expect(mem.eql(u8, f.next().?, "database"));
    try expect(f.next() == null);
}

