const std = @import("std");
const Allocator = @import("std").mem.Allocator;

const Self = @This();

/// Whether or not the key is currently being pressed.
getKey: fn (key: u8) bool,
/// Whether or not the key was pressed down on this frame.
getKeyDown: fn (key: u8) bool,
/// Whether or not the key was released on this frame.
getKeyUp: fn (key: u8) bool,
/// Whether or not any key has been pressed.
keyPressed: fn () bool,

/// Sets up the Inputter
init: fn (alloc: Allocator) anyerror!void,
/// Call every frame to update keystate
update: fn () void,
deinit: fn () void
