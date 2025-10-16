const std = @import("std");
const stream = @import("./stream.zig");
const mem = std.mem;
const printd = std.debug.print;
const expect = std.testing.expect;
const fmt = std.fmt;

// Let for now...
const connType = enum { UNIX, IPv4, IPv6 };

// TODO: This is just the beginning. May need to populate more params...
pub const Config = struct {
    user: []const u8, // username
    password: []const u8, // password
    host: []const u8, // IPv4, IPv6, localhost
    port: u16, // port number
    database: []const u8, // database name

    /// Config creating goes throw here.
    /// alloc is used to create config struct and to tokenize url.
    pub fn initAlloc(url: []const u8, alloc: mem.Allocator) !*Config {
        if (mem.startsWith(u8, url, "postgres://") or
            (mem.startsWith(u8, url, "postgresql://")))
        {
            const c = try alloc.create(Config);

            var token = mem.tokenizeAny(u8, url, ":/@");

            _ = token.next().?;

            c.* = Config{
                .user = token.next().?,
                .password = token.next().?,
                .host = token.next().?,
                // .port = token.next().?,
                .port = try fmt.parseInt(u16, token.next().?, 10),
                .database = token.next().?,
            };

            return c;

        }

        return error.badUrlPrefix;
    }

    // NOTE: This may be deleted in the future
    pub fn print(self: Config) void {
        printd("user: {s}\n", .{self.user});
        printd("password: {s}\n", .{self.password});
        printd("host: {s}\n", .{self.host});
        printd("port: {d}\n", .{self.port});
        printd("database: {s}\n", .{self.database});
    }
};


test "tokenize" {
    const path = "postgres://user:pass@localhost:5432/database";
    var buf: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    const alloc = fba.allocator();
    const cfg = try Config.initAlloc(path, alloc);

    try expect(mem.eql(u8, cfg.user, "user"));
    try expect(mem.eql(u8, cfg.password, "pass"));
    try expect(mem.eql(u8, cfg.host, "localhost"));
    // try expect(mem.eql(u8, cfg.port, "5432"));
    try expect(cfg.port == 5432);
    try expect(mem.eql(u8, cfg.database, "database"));
}

test "bad url prefix" {
    const path = "postgre://user:pass@localhost:5432/database";
    var buf: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    const alloc = fba.allocator();

    const err = Config.initAlloc(path, alloc);

    try expect(err == error.badUrlPrefix);
}
