const std = @import("std");
const root = @import("../../main.zig");

const Self = @This();

const Box = root.Box;

header: Box,
major_brand: [4]u8,
minor_version: u32,
compatible_brands: std.ArrayList([4]u8),

pub fn init(allocator: std.mem.Allocator, box: Box) !Self {
    var data = try box.data(allocator);
    defer allocator.free(data);

    var stream = std.io.fixedBufferStream(data);

    var reader = stream.reader();

    var self: Self = undefined;
    self.header = box;

    // Read major_brand
    _ = try reader.read(self.major_brand[0..]);

    // Read minor version
    self.minor_version = try reader.readIntBig(u32);

    // Read compatible brands
    var brands = std.ArrayList([4]u8).init(allocator);
    errdefer brands.deinit();

    var buf: [4]u8 = undefined;

    while (reader.read(buf[0..])) |len| {
        if (len == 0) break;
        if (len < buf.len) {
            return error.NotEnoughData;
        }
        try brands.append(buf);
    } else |err| {
        std.debug.assert(err == error.EndOfFile);
    }

    self.compatible_brands = brands;

    return self;
}

pub fn deinit(self: Self) void {
    self.compatible_brands.deinit();
}

test "Ftyp" {
    var allocator = std.testing.allocator;

    var tmp_reader = Box.MakeTestReader().init(root.minimal_asset);
    var reader = tmp_reader.reader();

    while (Box.parse(reader)) |box| {
        std.debug.print("Box type: {s}, Size: {?}, Large size: {?}\n", .{ box.box_type, box.size, box.large_size });
        if (std.mem.eql(u8, &box.box_type, "ftyp")) {
            var ftyp = try Self.init(allocator, box);
            defer ftyp.deinit();

            std.debug.print(
                "Major brand: {s}, Minor version: {}, Compatible brands: {s}\n",
                .{ ftyp.major_brand, ftyp.minor_version, ftyp.compatible_brands.items },
            );
            break;
        } else {
            var buf = try box.data(allocator);
            defer allocator.free(buf);
        }
    } else |err| {
        std.debug.print("Got Error: {}\n", .{err});
    }
}
