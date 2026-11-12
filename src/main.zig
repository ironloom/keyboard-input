//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const std = @import("std");
const keyboard_input = @import("keyboard_input");

pub fn main() !void {
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    try keyboard_input.init(std.heap.smp_allocator);
    defer keyboard_input.deinit();

    while (!keyboard_input.getKeyDown('q')) {
        keyboard_input.update();

        if (keyboard_input.getKey('w')) {
            std.log.debug("w", .{});
        }
    }
}
