const std = @import("std");

const Self = @This();

size: u32,
box_type: [4]u8,
large_size: ?u64,

pub fn parse(reader: Reader) !Self {}
