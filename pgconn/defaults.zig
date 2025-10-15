const std = @import("std");
const printd = std.debug.print;
const expect = std.testing.expect;
const mem = std.mem;

pub fn defaultSettings(alloc: std.mem.Allocator) !std.StringHashMap([]const u8) {
    var setting = std.StringHashMap([]const u8).init(alloc);

    try setting.put("host", defaultHost("host"));
    try setting.put("port", "5432");

    return setting;
}

test "default settings" {
    var buf: [1024]u8 = undefined;
    var alloc = std.heap.FixedBufferAllocator.init(&buf);
    const page = alloc.allocator();
    var ds = try defaultSettings(page);
    defer ds.deinit();

    try expect(std.mem.eql(u8, ds.get("host").?, "host"));
    try expect(std.mem.eql(u8, ds.get("port").?, "5432"));
}

// This may be populated with others options
pub fn defaultHost(path: []const u8) []const u8 {
    if (mem.eql(u8, path, "/run/postgresql/.s.PGSQL.5432")) {
        return "unix";
    }
    return path;
}
