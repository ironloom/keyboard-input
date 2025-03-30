const std = @import("std");
const Allocator = @import("std").mem.Allocator;

const Inputter = @import("Inputter.zig");
const OSXInputter = @import("./Inputters/OSX.zig").OSXInputter;
const WindowsInputter = @import("./Inputters/Windows.zig").WindowsInputter;

const inputter: ?Inputter = switch (@import("builtin").os.tag) {
    .macos => OSXInputter,
    .windows => WindowsInputter,
    else => null,
};
var initalised = false;

pub export fn init() void {
    const inp = inputter orelse {
        std.log.err("Keyboard does not support OS", .{});
        return;
    };

    inp.init(std.heap.smp_allocator) catch {
        std.log.err("Keyboard init failed", .{});
        return;
    };
    initalised = true;
}

pub export fn update() void {
    if (!initalised) return;

    const inp = inputter orelse return;
    inp.update();
}

pub export fn deinit() void {
    if (!initalised) return;

    const inp = inputter orelse return;
    inp.deinit();
}

pub export fn getKey(key: u8) bool {
    if (!initalised) return false;

    const inp = inputter orelse return false;
    return inp.getKey(key);
}

pub export fn getKeyDown(key: u8) bool {
    if (!initalised) return false;

    const inp = inputter orelse return false;
    return inp.getKeyDown(key);
}

pub export fn getKeyUp(key: u8) bool {
    if (!initalised) return false;

    const inp = inputter orelse return false;
    return inp.getKeyUp(key);
}

pub export fn keyPressed() bool {
    if (!initalised) return false;

    const inp = inputter orelse return false;
    return inp.keyPressed();
}
