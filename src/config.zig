const std = @import("std");
const Uri = std.Uri;
const mem = std.mem;

pub const ParseError = error{
    BadScheme,
    MissingUser,
    MissingHost,
    MissingPath,
    MissingPort,
    InvalidUri,
};

/// For now some default data is set
/// I may get rid of them.
/// scheme = "postgres"
/// host = "127.0.0.1" | The IP is used instead of the "localhost" coz it can be tracked by wireshark
/// port = 5432 | Postgres default port
pub const Config = struct {
    scheme: ?[]const u8 = null,
    user: ?[]const u8 = null,
    password: ?[]const u8 = null,
    host: ?[]const u8 = null,
    port: ?u16 = null,
    db: ?[]const u8 = null,

    /// Set the Config fields with their respective data.
    /// This is used to set a connection
    /// It can be usefull to check the different parameters when needed
    pub fn parseURI(self: *Config, text: []const u8) ParseError!void {
        if (!mem.startsWith(u8, text, "postgres://") and
            !mem.startsWith(u8, text, "postgresql://"))
        {
            return error.BadScheme;
        }

        const uri = Uri.parse(text) catch return error.InvalidUri;

        // No need to check anything.
        // The if stmt already do the job.
        self.scheme = uri.scheme;

        const user = uri.user orelse return error.MissingUser;
        self.user = user.percent_encoded;

        // password is optional for must cases
        if (uri.password) |pw| {
            self.password = pw.percent_encoded;
        }

        const host = uri.host orelse return error.MissingHost;
        self.host = host.percent_encoded;

        self.port = uri.port orelse return error.MissingPort;

        // path is the tricky even the stupid one.
        // Dunno why they did this, but the `isEmpty()` method is cool
        // for path checking.
        if (uri.path.isEmpty()) {
            return error.MissingPath;
        }
        self.db = std.mem.trim(u8, uri.path.percent_encoded, "/");
    }
};
