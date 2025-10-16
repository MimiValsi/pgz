const std = @import("std");
const net = std.net;
const mem = std.mem;
const fmt = std.fmt;

// NOTE: For now, only localhost wil be known as ip4 protocol
pub fn setStream(host: []const u8, port: u16) !net.Stream {
    if (mem.eql(u8, host, "localhost")) {
        // check other paths for the future
        // const path = "/run/postgresql/.s.PGSQL.";
        const path = "/run/postgresql/.s.PGSQL.5432";
        const conn = try net.connectUnixSocket(path);
        return conn;

    } else {
        // const p = try fmt.parseInt(u16, port, 10);
        const addr = try net.Address.resolveIp(host, port);
        const conn = try net.tcpConnectToAddress(addr);
        return conn;
    }

    return error.unknownHost;
}
