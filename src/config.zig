const std = @import("std");
const Uri = std.Uri;
const mem = std.mem;
const Allocator = std.mem.Allocator;

pub const ParseError = error{
    BadScheme,
    MissingUser,
    MissingHost,
    MissingPath,
    MissingPort,
    InvalidUri,
    OutOfMemory,
};

/// For now some default data is set
/// I may get rid of them.
/// scheme = "postgres"
/// host = "127.0.0.1" | The IP is used instead of the "localhost" coz it can be tracked by wireshark
/// port = 5432 | Postgres default port
pub const Config = struct {
    scheme: []u8 = undefined,
    user: ?[]u8 = null,
    password: ?[]u8 = null,
    host: ?[]u8 = null,
    port: ?u16 = null,
    db: []u8 = undefined,

    /// Set the Config fields with their respective data.
    /// This is used to set a connection
    /// It can be usefull to check the different parameters when needed
    pub fn init(alloc: Allocator, text: []const u8) ParseError!*Config {
        if (!mem.startsWith(u8, text, "postgres://") and
            !mem.startsWith(u8, text, "postgresql://"))
        {
            return error.BadScheme;
        }

        const self: *Config = try alloc.create(Config);
        errdefer self.deinit(alloc);

        const uri = Uri.parse(text) catch return error.InvalidUri;

        // No need to check anything.
        // The if stmt already do the job.
        self.scheme = try alloc.alloc(u8, uri.scheme.len);
        @memcpy(self.scheme, uri.scheme);

        const user = uri.user orelse return error.MissingUser;
        self.user.? = try alloc.alloc(u8, user.percent_encoded.len);
        @memcpy(self.user.?, user.percent_encoded);

        // password is optional for must cases
        if (uri.password) |pw| {
            self.password.? = try alloc.alloc(u8, pw.percent_encoded.len);
            @memcpy(self.password.?, pw.percent_encoded);
        }

        const host = uri.host orelse return error.MissingHost;
        self.host = try alloc.alloc(u8, host.percent_encoded.len);
        @memcpy(self.host.?, host.percent_encoded);

        self.port.? = uri.port orelse return error.MissingPort;

        // path is the tricky even the stupid one.
        // Dunno why they did this, but the `isEmpty()` method is cool
        // for path checking.
        if (uri.path.isEmpty()) {
            return error.MissingPath;
        }

        const path = std.mem.trim(u8, uri.path.percent_encoded, "/");
        self.db = try alloc.alloc(u8, path.len);
        @memcpy(self.db, path);

        return self;
    }

    pub fn deinit(self: *Config, alloc: Allocator) void {
        alloc.free(self.scheme);

        if (self.user != null) {
            alloc.free(self.user.?);
        }

        if (self.host != null) {
            alloc.free(self.host.?);
        }

        if (self.password != null) {
            alloc.free(self.password.?);
        }

        alloc.free(self.db);

        alloc.destroy(self);
    }
};
