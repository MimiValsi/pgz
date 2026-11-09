const std = @import("std");
const Io = std.Io;
const net = Io.net;
const Uri = std.Uri;
const fmt = std.fmt;

const Frontend = @import("frontend.zig").Frontend;

// Protocol version 3.0 or 196608
const protocol: i32 = (3 << 16) | 0;

/// Connection struct that handles high-level abstraction.
/// r/w runs through here
/// For low-level see Frontend.zig
pub const Connection = struct {
    addr: net.IpAddress,
    io: Io,
    stream: net.Stream,
    frontend: Frontend,

    /// Initialize the Connection struct.
    /// Check the prefix of the URI, resolve the address, make TCP connection.
    pub fn init(io: Io, host: []const u8, port: u16) !Connection {
        const addr = try net.IpAddress.resolve(io, host, port);
        const stream = try net.IpAddress.connect(&addr, io, .{
            .mode = .stream,
            .protocol = .tcp,
            .timeout = .none, // timeout still not implemented
        });

        // defer only on error. This is really not necessary per-se
        // but keeps some consistency/clean.
        errdefer stream.close(io);

        const frontend = try Frontend.init(io, stream);

        return .{
            .addr = addr,
            .io = io,
            .stream = stream,
            .frontend = frontend,
        };
    }

    pub fn deinit(self: *Connection) void {
        self.stream.close(self.io);
    }

    pub fn startupMsg(_: *const Connection, writer: *Io.Writer, user: []const u8, db: []const u8) !void {
        var buf: [512]u8 = undefined;
        const msg = try fmt.bufPrint(&buf, "user\x00{s}\x00database\x00{s}\x00\x00", .{ user, db });

        try writer.writeInt(i32, @intCast(msg.len + 8), .big);
        try writer.writeInt(i32, protocol, .big);
        try writer.writeAll(msg);
        try writer.flush();
    }
};
