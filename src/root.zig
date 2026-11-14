//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const Io = std.Io;
const Uri = std.Uri;

const testing = std.testing;
const expectEqual = testing.expectEqual;

pub const Connection = @import("connection.zig").Connection;
const Config = @import("config.zig").Config;
const Frontend = @import("frontend.zig").Frontend;

const text: []const u8 = "postgres://postgres:pass@127.0.0.1:5432/pgdb";

test "Connection init" {
    var threaded: std.Io.Threaded = .init(testing.allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const alloc = std.testing.allocator;

    var conn: Connection = try .init(alloc, io, text);
    defer conn.deinit(alloc);

    try conn.startupMsg(conn.frontend.writer, conn.cfg.user.?, conn.cfg.db);

    const bytes = try conn.frontend.reader.take(9);
    const size = std.mem.readVarInt(u32, bytes[1..5], .big);
    const auth = std.mem.readVarInt(u32, bytes[5..9], .big);

    try expectEqual('R', bytes[0]);
    try expectEqual(8, size);
    try expectEqual(0, auth);

    try conn.frontend.writer.writeByte('X');
    try conn.frontend.writer.writeInt(u32, 4, .big);
    try conn.frontend.writer.flush();

    std.debug.print("test \"Connection init\" OK!\n ", .{});
}
