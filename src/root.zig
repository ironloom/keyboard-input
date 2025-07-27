const std = @import("std");
const Allocator = @import("std").mem.Allocator;

const Inputter = @import("Inputter.zig");
const MacOS_Inputter = @import("./Inputters/OSX.zig").OSXInputter;
const Windows_Inputter = @import("./Inputters/Windows.zig").inputter;
const Linux_Inputter = @import("./Inputters/Linux.zig").LinuxInputter;

const inputter: ?Inputter = switch (@import("builtin").os.tag) {
    .macos => MacOS_Inputter,
    .windows => Windows_Inputter,
    .linux => Linux_Inputter,
    else => null,
};
var initalised = false;
var alloc: ?Allocator = null;

pub fn init(allocator: Allocator) !void {
    const inp = inputter orelse {
        std.log.err("keyboard-input does not support current OS (supported: MacOS, Linux, Windows)", .{});
        return;
    };

    alloc = allocator;
    try inp.init(alloc.?);

    initalised = true;
}

pub export fn initUnsafe() void {
    init(std.heap.smp_allocator) catch {
        std.log.err("keyboard-input setup failed", .{});
    };
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
///
/// **NOTE: THIS MAY NOT WORK CORRECTLY ON SOME OPERATING SYSTEMS.**
///
/// *Currently works on: Windows*
pub export fn keyPressed() bool {
    if (!initalised) return false;

    const inp = inputter orelse return false;
    return inp.keyPressed();
}
