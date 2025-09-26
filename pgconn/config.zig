const std = @import("std");
const printd = std.debug.print;
const expect = std.testing.expect;
const mem = std.mem;
const defSet = @import("./defaults.zig");
const parseInt = std.fmt.parseInt;

// TODO: This is just the beginning. May need to populate more params...
const Config = struct {
    user: []const u8, // username
    password: []const u8, // password
    host: []const u8, // localhost or unix domain socket dir
    port: u16, // port number
    database: []const u8, // database name

    // NOTE: Config struct will be initialise by the user first. Maybe a method??
    // This method init the struct param
    fn init(
        host: []const u8,
        port: u16,
        database: []const u8,
        user: []const u8,
        password: []const u8
    ) Config {
        return Config{
            .user = user,
            .password = password,
            .host = host,
            .port = port,
            .database = database,
        };
    }

    // NOTE: This one allocates memory before init!
    // This method must be used instead of init()!
    // By making this method public, init() won't be called... Nice!
    pub fn create(alloc: std.mem.Allocator,
                  user: []const u8,
                  password: []const u8,
                  host: []const u8,
                  port: u16,
                  database: []const u8,
        )!*Config {

        const cfg = try alloc.create(Config);
        cfg.* = init(host, port, database, user, password);

        return cfg;
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

pub fn parseConfig(url: []const u8, alloc: std.mem.Allocator) !?*Config {
    if (url.len != 0) {
        if (mem.startsWith(u8, url, "postgres://")  or
                (mem.startsWith(u8, url, "postgresql://"))) {

            // NOTE: User create the alloc or pre-create one??
            // 1st try: User create alloc
            // var defaultSettings = try defSet.defaultSettings(alloc);
            // defer defaultSettings.deinit();
            var urlTokenized = try tokenizeURL(url, alloc);
            defer urlTokenized.deinit();

            const port = try parseInt(u16, urlTokenized.get("port").?, 10);
            const cfg = try Config.create(alloc,
                                          urlTokenized.get("user").?, // Fetch from param?
                                          urlTokenized.get("pass").?,
                                          urlTokenized.get("host").?,
                                          port,
                                          urlTokenized.get("database").?, // Fetch from param?
                                     );

            return cfg;
        }
    }

    return null;

}

// NOTE: Make and return a stringHashMap?
// or just an array of strings??
// Again, user or here for alloc??
fn tokenizeURL(url: []const u8, alloc: std.mem.Allocator) !std.StringHashMap([]const u8) {
    var token = mem.tokenizeAny(u8, url, ":/@");
    var arr = std.StringHashMap([]const u8).init(alloc);

    var count: u8 = 0;
    while (token.next()) |_| {
        count += 1;
    }
    token.reset();

    if (count < 6) {
        return error.MissUrlParams;
    }

    try arr.put("pg", token.next().?);
    try arr.put("user", token.next().?);
    try arr.put("pass", token.next().?);
    try arr.put("host", token.next().?);
    try arr.put("port", token.next().?);
    try arr.put("database", token.next().?);

    return arr;
}

test "wrong parse config" {
    const url = "postgres://user:pass@localhost:5432";

    var buf: [1024]u8 = undefined;
    var fixedBuffer = std.heap.FixedBufferAllocator.init(&buf);
    const alloc = fixedBuffer.allocator();

    try std.testing.expectError(error.MissUrlParams, tokenizeURL(url, alloc));
}

test "parse config" {
    var buf: [1024]u8 = undefined;
    var fixedBuffer = std.heap.FixedBufferAllocator.init(&buf);
    const alloc = fixedBuffer.allocator();

    const url = "postgres://user:pass@localhost:5432/database";

    var urlTokenized = try tokenizeURL(url, alloc);
    try expect(mem.eql(u8, urlTokenized.get("pg").?, "postgres"));
    try expect(mem.eql(u8, urlTokenized.get("user").?, "user"));
    try expect(mem.eql(u8, urlTokenized.get("pass").?, "pass"));
    try expect(mem.eql(u8, urlTokenized.get("host").?, "localhost"));
    try expect(mem.eql(u8, urlTokenized.get("port").?, "5432"));
    try expect(mem.eql(u8, urlTokenized.get("database").?, "database"));
}

test "create and init config" {
    const host = "localhost";
    const port = 1234;
    const database = "pgz_db";
    const user = "pgz";
    const password = "pgz_password";

    // created an arena for the experience but allocating page_allocator is good too.
    // Maybe init with a more performante memory alloc?
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const heap = arena.allocator();

    const config = try Config.create(heap, user, password, host, port, database);

    try expect(@TypeOf(config.host) == []const u8);
    try expect(@TypeOf(config.port) == u16);
    try expect(@TypeOf(config.database) == []const u8);
    try expect(@TypeOf(config.user) == []const u8);
    try expect(@TypeOf(config.password) == []const u8);
    try expect(std.mem.eql(u8, config.host, host));
    try expect(std.mem.eql(u8, config.database, database));
    try expect(std.mem.eql(u8, config.user, user));
    try expect(std.mem.eql(u8, config.password, password));
    try expect(config.port == port);
}
