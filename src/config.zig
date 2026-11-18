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
    user: []u8 = undefined,
    password: ?[]u8 = null,
    host: []u8 = undefined,
    port: u16 = undefined,
    db: []u8 = undefined,

    /// Set the Config fields with their respective data.
    /// This is used to set a connection
    /// It can be usefull to check the different parameters when needed
    pub fn init(alloc: Allocator, text: []const u8) ParseError!Config {
        if (!mem.startsWith(u8, text, "postgres://") and
            !mem.startsWith(u8, text, "postgresql://"))
        {
            return error.BadScheme;
        }

        var self: Config = .{};
        // errdefer self.deinit(alloc);

        const uri = Uri.parse(text) catch return error.InvalidUri;

        // No need to check anything.
        // The if stmt already do the job.
        self.scheme = try alloc.alloc(u8, uri.scheme.len);
        @memcpy(self.scheme, uri.scheme);

        const user = uri.user orelse return error.MissingUser;
        self.user = try alloc.alloc(u8, user.percent_encoded.len);
        @memcpy(self.user, user.percent_encoded);
        std.debug.print("self.user: {any}\n", .{self.user});

        // password is optional for must cases
        if (uri.password) |pw| {
            self.password = try alloc.alloc(u8, pw.percent_encoded.len);
            @memcpy(self.password.?, pw.percent_encoded);
        }
        // std.debug.print("self.password: {any}", .{self.password});

        const host = uri.host orelse return error.MissingHost;
        self.host = try alloc.alloc(u8, host.percent_encoded.len);
        @memcpy(self.host, host.percent_encoded);

        self.port = uri.port orelse return error.MissingPort;

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
        alloc.free(self.user);
        alloc.free(self.host);
        alloc.free(self.db);

        if (self.password != null) {
            alloc.free(self.password.?);
        }
    }
};
