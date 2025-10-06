//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const std = @import("std");
const Allocator = @import("std").mem.Allocator;
const kb_input = @import("keyboard_input");

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.

    try kb_input.init(std.heap.smp_allocator);
    defer kb_input.deinit();

    while (!kb_input.getKeyDown('q')) {
        kb_input.update();

        if (kb_input.getKeyDown('w')) std.log.debug("w", .{});
    }
}
