//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const Io = std.Io;
const Uri = std.Uri;

const Connection = @import("connection.zig").Connection;
const Config = @import("config.zig").Config;
const Frontend = @import("frontend.zig").Frontend;

const text: []const u8 = "postgres://postgres:pass@127.0.0.1:5432/pgdb";

test "Config init" {
    var cfg: Config = .{};
    try cfg.parseURI(text);

    try std.testing.expectEqualStrings(cfg.scheme.?, "postgres");
    try std.testing.expectEqualStrings(cfg.user.?, "postgres");
    try std.testing.expectEqualStrings(cfg.password.?, "pass");
    try std.testing.expectEqualStrings(cfg.host.?, "127.0.0.1");
    try std.testing.expectEqual(cfg.port.?, 5432);
    try std.testing.expectEqualStrings(cfg.db.?, "pgdb");

    std.debug.print("test \"Config init\" OK!\n", .{});
}

test "Connection init" {
    var cfg: Config = .{};
    try cfg.parseURI(text);
    var threaded: std.Io.Threaded = .init(std.testing.allocator, .{});
    defer threaded.deinit();

    const io = threaded.io();

    var conn = try Connection.init(io, cfg.host.?, cfg.port.?);
    defer conn.deinit();

    try conn.startupMsg(conn.frontend.writer, cfg.user.?, cfg.db.?);

    _ = try conn.frontend.reader.take(5);

    try conn.frontend.writer.writeByte('X');
    try conn.frontend.writer.writeInt(u32, 4, .big);
    try conn.frontend.writer.flush();

    std.debug.print("test \"Connection init\" OK!\n ", .{});
}
