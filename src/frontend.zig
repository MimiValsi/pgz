const std = @import("std");
const Io = std.Io;
const Stream = Io.net.Stream;
const Alloc = std.mem.Allocator;

pub const Frontend = struct {
    // for now both buffers will be set to 512 bytes
    // INFO: Postgres start with 8192. May do the same in the future
    w_buf: [512]u8 = undefined,
    r_buf: [512]u8 = undefined,

    writer: *Io.Writer,
    reader: *Io.Reader,

    pub fn init(io: Io, stream: Stream) !Frontend {
        var self: Frontend = .{
            .writer = undefined,
            .reader = undefined,
        };

        var writer_interface = stream.writer(io, &self.w_buf);
        var reader_interface = stream.reader(io, &self.r_buf);

        return .{
            .writer = &writer_interface.interface,
            .reader = &reader_interface.interface,
        };
    }
};
