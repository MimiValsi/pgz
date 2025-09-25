const std = @import("std");
const printd = std.debug.print;
const expect = std.testing.expect;

// TODO: This is just the beginning. May need to populate more params...
const Config = struct {
    host: []const u8, // localhost or unix domain socket dir
    port: u16, // port number
    database: []const u8, // database name
    user: []const u8, // username
    password: []const u8, // password

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
            .host = host,
            .port = port,
            .database = database,
            .user = user,
            .password = password,
        };
    }

    // NOTE: This one allocates memory before init!
    // This method must be used instead of init()!
    // By making this method public, init() won't be called... Nice!
    pub fn create(alloc: std.mem.Allocator,
                  host: []const u8,
                  port: u16,
                  database: []const u8,
                  user: []const u8,
                  password: []const u8
        )!*Config {

        const cfg = try alloc.create(Config);
        cfg.* = init(host, port, database, user, password);

        return cfg;
    }

    pub fn print(self: Config) void {
        printd("host: {s}\n", .{self.host});
        printd("port: {d}\n", .{self.port});
        printd("database: {s}\n", .{self.database});
        printd("user: {s}\n", .{self.user});
        printd("password: {s}\n", .{self.password});
    }
};

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

    const config = try Config.create(heap, host, port, database, user, password);

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
