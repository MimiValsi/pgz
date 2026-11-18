const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

// const pgz = @import("pgz");

pub const Config = struct {
    scheme: []u8 = undefined,
    user: []u8 = undefined,
    password: ?[]u8 = null,
    host: []u8 = undefined,
    port: u16 = undefined,
    db: []u8 = undefined,

    pub fn init(alloc: Allocator, text: []const u8) !Config {
        const uri = try std.Uri.parse(text);

        var cfg: Config = .{};

        // errdefer cfg.deinit(alloc);

        cfg.scheme = try alloc.alloc(u8, uri.scheme.len);
        @memcpy(cfg.scheme, uri.scheme);

        cfg.user = try alloc.alloc(u8, uri.user.?.percent_encoded.len);
        @memcpy(cfg.user, uri.user.?.percent_encoded);

        if (uri.password) |pw| {
            cfg.password = try alloc.alloc(u8, pw.percent_encoded.len);
            @memcpy(cfg.password.?, pw.percent_encoded);
        }

        cfg.host = try alloc.alloc(u8, uri.host.?.percent_encoded.len);
        @memcpy(cfg.host, uri.host.?.percent_encoded);

        cfg.port = uri.port.?;

        cfg.db = try alloc.alloc(u8, uri.path.percent_encoded.len);
        @memcpy(cfg.db, uri.path.percent_encoded);

        return cfg;
    }

    pub fn deinit(self: *Config, alloc: Allocator) void {
        alloc.free(self.scheme);
        alloc.free(self.user);

        if (self.password != null) {
            alloc.free(self.password.?);
        }
        alloc.free(self.host);
        alloc.free(self.db);
    }
};

pub fn main(init: std.process.Init) !void {
    _ = init;
    const text: []const u8 = "postgres://:pass@127.0.0.1:5432/pgdb";
    var gpa = std.heap.DebugAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.detectLeaks();

    var cfg: Config = try .init(alloc, text);
    defer cfg.deinit(alloc);

    std.debug.print("user: {s}\n", .{cfg.user});
    std.debug.print("pass: {s}\n", .{cfg.password.?});

    // std.debug.print("cfg: {any}", .{cfg});

}
