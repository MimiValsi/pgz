const std = @import("std");
const Io = std.Io;
const net = Io.net;
const Uri = std.Uri;
const fmt = std.fmt;
const log = std.log;
const debug = std.debug;
const Allocator = std.mem.Allocator;

const Frontend = @import("frontend.zig").Frontend;
const Config = @import("config.zig").Config;

// Protocol version 3.0 or 196608
const protocol: i32 = (3 << 16) | 0;

/// Connection struct that handles high-level abstraction.
/// r/w runs through here
/// For low-level see Frontend.zig
pub const Connection = struct {
    cfg: Config,
    frontend: Frontend,
    addr: net.IpAddress,
    io: Io,
    stream: net.Stream,

    /// Initialize the Connection struct.
    /// Check the prefix of the URI, resolve the address, make TCP connection.
    pub fn init(alloc: Allocator, io: Io, text: []const u8) !Connection {
        const cfg: Config = try .init(alloc, text);
        // errdefer cfg.deinit(alloc);

        const addr = try net.IpAddress.resolve(io, cfg.host, cfg.port);
        const stream = try net.IpAddress.connect(&addr, io, .{
            .mode = .stream,
            .protocol = .tcp,
            .timeout = .none, // timeout still not implemented
        });

        // defer only on error. This is really not necessary per-se
        // but keeps some consistency/clean behavior.
        errdefer stream.close(io);

        const frontend: Frontend = try .init(io, stream);

        return .{
            .cfg = cfg,
            .frontend = frontend,
            .addr = addr,
            .io = io,
            .stream = stream,
        };
    }

    pub fn deinit(self: *Connection, alloc: Allocator) void {
        self.stream.close(self.io);
        self.cfg.deinit(alloc);
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
