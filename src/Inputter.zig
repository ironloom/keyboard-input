const std = @import("std");
const Allocator = @import("std").mem.Allocator;

const Self = @This();

getKey: fn (key: u8) bool,
getKeyDown: fn (key: u8) bool,
getKeyUp: fn (key: u8) bool,
keyPressed: fn () bool,

init: fn (alloc: Allocator) anyerror!void,
update: fn () void,
deinit: fn () void
