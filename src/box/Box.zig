const std = @import("std");
const root = @import("../main.zig");

const Reader = root.Reader;

const Self = @This();

size: ?u32,
box_type: [4]u8,
large_size: ?u64,

pub fn parse(reader: Reader) !Self {
    // Read size
    var box_size: ?u32 = try reader.readIntBig(u32);
    // Read type
    var typ: [4]u8 = undefined;
    var len = try reader.readAll(typ[0..]);
    if (len < typ.len) return error.NotEnoughData;

    // If box_size == 1, read large_size
    var large_size: ?u64 = if (box_size == @as(u32, 1)) try reader.readIntBig(u64) else null;
    if (large_size != null or box_size == @as(u32, 0)) box_size = null;

    return Self{
        .size = box_size,
        .box_type = typ,
        .large_size = large_size,
    };
}

pub fn getSize(self: Self) ?u64 {
    if (self.size) |s| return s;
    if (self.large_size) |s| return s;

    return null;
}

pub fn data(self: Self, reader: Reader, allocator: std.mem.Allocator) ![]u8 {
    var box_size = self.getSize();
    if (box_size) |s| {
        var final_size = if (self.size != null) s - @as(u64, 8) else s - @as(u64, 16);
        var buf: []u8 = try allocator.alloc(u8, @intCast(usize, final_size));
        errdefer allocator.free(buf);

        const len = try reader.read(buf);
        if (len < buf.len) {
            return error.NotEnoughData;
        }
        return buf;
    } else {
        // Size extends to EOF
        return reader.readAllAlloc(allocator, std.math.maxInt(usize));
    }
}

fn MakeFileReader() type {
    return struct {
        file: *std.fs.File,

        pub fn init(f: *std.fs.File) @This() {
            return .{
                .file = f,
            };
        }

        pub fn read(self: *@This(), buf: []u8) anyerror!usize {
            return self.file.read(buf);
        }

        pub fn reader(self: *@This()) Reader {
            return Reader.init(@This(), self);
        }
    };
}

test "Box" {
    var file = try std.fs.openFileAbsolute("/Users/adebayo/Movies/TypeScript Tutorial for Beginners [2022] [d56mG7DezGs].mp4", .{});
    defer file.close();

    var allocator = std.testing.allocator;

    var tmp_reader = MakeFileReader().init(&file);
    var reader = tmp_reader.reader();

    while (Self.parse(reader)) |box| {
        std.debug.print("Box type: {s}, Size: {?}, Large size: {?}\n", .{ box.box_type, box.size, box.large_size });
        var buf = try box.data(reader, allocator);
        defer allocator.free(buf);
    } else |err| {
        std.debug.print("Got Error: {}\n", .{err});
    }
}
