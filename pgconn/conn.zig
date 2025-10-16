const std = @import("std");
const cfg = @import("./config.zig");
const defaults = @import("./defaults.zig");
const stream = @import("./stream.zig");
const mem = std.mem;
const net = std.net;
const printd = std.debug.print;
const expect = std.testing.expect;

const Pgconn = struct {
    stream: net.Stream,
    config: *cfg.Config,

    pub fn connect(url: []const u8, alloc: std.mem.Allocator) !*Pgconn {
        const pgconn = try alloc.create(Pgconn);

        pgconn.*.config = try cfg.Config.initAlloc(url, alloc);
        pgconn.*.stream = try stream.setStream(pgconn.*.config.host, pgconn.*.config.port);

        return pgconn;
    }
};

// uri: postgres://user:pass@localhost:port/database
test "config" {
    const url = "postgres://user:pass@localhost:5432/database";

    var buf: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    const alloc = fba.allocator();

    const pgc = try Pgconn.connect(url, alloc);
    pgc.*.config.print();
}

// startup message doesn't have initial message-type byte.
// buf: |____|____|__...__|
//      0    4    8       N
//      ^    ^    ^
//      |    |    \ Message...
//      |    |
//      |    \ Next 4 bytes, contains the protocol version (196608)
//      |
//      \ First 4 bytes, contains the length of the message plus it self.
//          total length: message length + 4 first bytes + 4 bytes from protocol?

test "connection" {
    const path = "postgres://user:pass@127.0.0.1:5432/database";
    // const path = "/run/postgresql/.s.PGSQL.5432"; // It works!
    // const path = "127.0.0.1"; // It works!
    // const path = "::1"; // This works!
    var fba_buf: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&fba_buf);
    const alloc = fba.allocator();

    const pgconn = try Pgconn.connect(path, alloc);
    defer pgconn.stream.close();

    var buf: [128]u8 = undefined;
    var startUpMessage = std.ArrayList(u8).initBuffer(&buf);

    const user = "user\x00postgres\x00\x00";
    const db = "database\x00pgzdb\x00\x00";

    const data_len = @as(i32, @intCast(user.len)); // <- Get data length.

    var length_bytes: [4]u8 = undefined;
    std.mem.writeInt(i32, &length_bytes, data_len + 8, .big);
    startUpMessage.appendSliceAssumeCapacity(&length_bytes);

    var proto_version: [4]u8 = undefined;
    std.mem.writeInt(i32, &proto_version, 196608, .big);
    startUpMessage.appendSliceAssumeCapacity(&proto_version);

    startUpMessage.appendSliceAssumeCapacity(user); // <- append user
    startUpMessage.appendSliceAssumeCapacity(db); // <- append database

    var writer = pgconn.stream.writer(&.{});
    var writer_ptr = &writer.interface;

    try writer_ptr.writeAll(startUpMessage.items[0..4]); // <- 1st sent: message length
    try writer_ptr.writeAll(startUpMessage.items[4..8]); // <- 2nd sent: proto version
    try writer_ptr.writeAll(startUpMessage.items[8..]); // <- 3rd sent: the message

    printArrayListItems(startUpMessage);

    try writer_ptr.flush();

    var r_buf: [10000]u8 = undefined;
    var reader: std.net.Stream.Reader = pgconn.stream.reader(&r_buf);
    const r_in: *std.Io.Reader = reader.interface(); // This is meant to return *Io.Reader

    var len: u32 = 1;
    while (true) {
        const byte = try r_in.take(len);
        if (len == 1) {
            switch (byte[0]) {
                'S' => {
                    parameters();
                    len = 4;
                },
                'R' => {
                    authentication();
                    len = 4;
                },
                // 'K' => {
                //     backendKeyData();
                //     len = 4;
                // },
                // 'C' => {
                //     commandComplete();
                //     len = 4;
                // },
                // 'G' => {
                //     copyInResponse();
                // },
                // 'H' => {
                //     copyOutResponse();
                // },
                // 'W' => {
                //     copyBothResponse();
                // },
                // 'D' => {
                //     dataRow();
                // },
                // 'I' => {
                //     emptyQueryResponse();
                // },
                // 'E' => {
                //     errorMsg();
                //     len = 4;
                // },
                // 'V' => {
                //     functionCallResponse();
                // },
                // 'v' => {
                //     negociateProtoVersion();
                // },
                // 's' => {
                //     portalSuspended();
                // },
                // 'n' => {
                //     noData();
                // },
                // 'Z' => {
                //     readyForQuery();
                // },
                // 'T' => {
                //     rowDescription();
                // },
                // 'A' => {
                //     notifResponse();
                // },
                // 't' => {
                //     paramDescription();
                // },
                // 'S' => {
                //     paramStatus();
                // },
                // '1' => {
                //     parseComplete();
                // },
                // '2' => {
                //     bindComplete();
                //     len = 4;
                // },
                // '3' => {
                //     closeComplete();
                //     len = 4;
                // },
                else => printd("Unknown identifier!\n", .{}),
            }
        }

        // if (len == 4) {
        //     std.mem.writeInt(i32, byte, value, .big);
        // }
        printd("{s} ", .{byte});
        break;
    }

    printd("\n", .{});
}

fn errorMsg() void {
    printd("error msg\n", .{});
}
fn authentication() void {
    printd("authentication\n", .{});
}

fn parameters() void {
    printd("parameters\n", .{});
}
fn backendKeyData() void {
    printd("backend key data\n", .{});
}

fn printArrayListItems(items: std.ArrayList(u8)) void {
    for (items.items) |item| {
        printd("{x} ", .{item});
    }
    printd("\n\n", .{});
}
