const std = @import("std");
const testing = std.testing;

pub const Reader = @import("io/Reader.zig");
pub const Box = @import("box/Box.zig");
pub const Ftyp = @import("box/boxes/Ftyp.zig");

pub const minimal_asset: []const u8 = @embedFile("assets/minimal.mp4")[0..];

test {
    std.testing.refAllDecls(@This());
}
