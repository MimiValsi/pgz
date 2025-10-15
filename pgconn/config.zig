const std = @import("std");
const mem = std.mem;
const printd = std.debug.print;
const expect = std.testing.expect;
const defSet = @import("./defaults.zig");
const fmt = std.fmt;

// Let for now...
const connType = enum {
    UNIX,
    IPv4,
    IPv6
};

// TODO: This is just the beginning. May need to populate more params...
pub const Config = struct {
    user: []const u8,       // username
    password: []const u8,   // password
    host: []const u8,       // IPv4/IPv6 or unix domain socket
    port: u16,              // port number
    database: []const u8,   // database name

    /// Config creating goes throw here.
    /// alloc is used to create config struct and to tokenize url.
    pub fn createConfigAlloc(url: []const u8, alloc: std.mem.Allocator) !*Config {
        if (mem.startsWith(u8, url, "postgres://") or
            (mem.startsWith(u8, url, "postgresql://")))
        {
            const cfg = try alloc.create(Config);
            try cfg.*.tokenizeURLAlloc(url);
            return cfg;
        }

        return error.badUrlPrefix;
    }

    // NOTE: prefix postgres(ql) is ditch.
    fn tokenizeURLAlloc(c: *Config, url: []const u8) !void {
        var token = mem.tokenizeAny(u8, url, ":/@");

        _ = token.next().?;
        c.*.user = token.next().?;
        c.*.password = token.next().?;
        c.*.host = token.next().?;
        c.*.port = try fmt.parseInt(u16, token.next().?, 10);
        c.*.database = token.next().?;
    }

    // NOTE: This may be deleted in the future
    pub fn print(self: Config) void {
        printd("host: {s}\n", .{self.host});
        printd("port: {d}\n", .{self.port});
        printd("database: {s}\n", .{self.database});
        printd("user: {s}\n", .{self.user});
        printd("password: {s}\n", .{self.password});
    }
};

test "tokenize" {
    const path = "postgres://user:pass@localhost:5432/database";
    var buf: [512]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    const alloc = fba.allocator();

    const cfg = try Config.createConfigAlloc(path, alloc);
    cfg.*.print();
}

test "bad url prefix" {
    const path = "postgre://";
    var buf: [512]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    const alloc = fba.allocator();
    const err = Config.createConfigAlloc(path, alloc);
    try expect(err == error.badUrlPrefix);
}
