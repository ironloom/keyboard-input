const std = @import("std");
const Allocator = @import("std").mem.Allocator;

const Inputter = @import("Inputter.zig");
const OSXInputter = @import("./Inputters/OSX.zig").OSXInputter;
const WindowsInputter = @import("./Inputters/Windows.zig").WindowsInputter;
const LinuxInputter = @import("./Inputters/Linux.zig").LinuxInputter;

const inputter: ?Inputter = switch (@import("builtin").os.tag) {
    .macos => OSXInputter,
    .windows => WindowsInputter,
    .linux => LinuxInputter,
    else => null,
};
var initalised = false;

pub export fn init() void {
    const inp = inputter orelse {
        std.log.err("keyboard-input does not support OS", .{});
        return;
    };

    inp.init(std.heap.smp_allocator) catch {
        std.log.err("keyboard init failed", .{});
        return;
    };
    initalised = true;
}

/// Call every frame to update the keyboard state.
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

/// Returns the current keystate, `true` if the key is pressed, `false` if not.
pub export fn getKey(key: u8) bool {
    if (!initalised) return false;

    const inp = inputter orelse return false;
    return inp.getKey(key);
}

/// Returns whether or not the key has been pressed for the first time.
pub export fn getKeyDown(key: u8) bool {
    if (!initalised) return false;

    const inp = inputter orelse return false;
    return inp.getKeyDown(key);
}

/// Returns true when the key is released.
pub export fn getKeyUp(key: u8) bool {
    if (!initalised) return false;

    const inp = inputter orelse return false;
    return inp.getKeyUp(key);
}

/// Checks is any key has been pressed.
/// **NOTE: THIS MAY NOT WORK CORRECTLY.** 
pub export fn keyPressed() bool {
    if (!initalised) return false;

    const inp = inputter orelse return false;
    return inp.keyPressed();
}
