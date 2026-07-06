const std = @import("std");
const Allocator = std.mem.Allocator;

const Inputter = @import("Inputter.zig");

const Windows_Inputter = @import("./Inputters/Windows.zig").inputter;
const MacOS_Inputter = @import("./Inputters/OSX.zig").inputter;
const Linux_Inputter = @import("./Inputters/Linux.zig").inputter;

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
        std.log.err(
            "keyboard-input does not support current OS (supported: MacOS, Linux, Windows)",
            .{},
        );
        return;
    };

    alloc = allocator;
    try inp.init(alloc.?);

    initalised = true;
}

/// This calls `init()` with the `std.heap.smp_allocator`. Handles setup error by aborting the process.
pub export fn initSafe() void {
    init(std.heap.smp_allocator) catch {
        std.log.err("keyboard-input setup failed", .{});
    };
}

fn eatStdin() void {
    const builtin = @import("builtin");
    if (comptime builtin.os.tag == .windows) {
        const kernel32 = struct {
            extern "kernel32" fn GetStdHandle(nStdHandle: i32) callconv(.winapi) ?*anyopaque;
            extern "kernel32" fn FlushConsoleInputBuffer(hConsoleInput: ?*anyopaque) callconv(.winapi) i32;
        };
        _ = kernel32.FlushConsoleInputBuffer(kernel32.GetStdHandle(-10));
        return;
    }

    const posix = struct {
        extern "c" fn tcflush(fd: i32, action: i32) i32;
    };
    const TCIFLUSH: i32 = if (comptime builtin.os.tag == .macos) 1 else 0;
    _ = posix.tcflush(std.posix.STDIN_FILENO, TCIFLUSH);
}

/// Call every frame to update the keyboard state.
pub export fn update() void {
    if (!initalised) return;

    eatStdin();

    const inp = inputter orelse return;
    inp.update();
}

pub export fn deinit() void {
    if (!initalised) return;

    eatStdin();

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
/// *Currently works on: Windows, MacOS*
pub export fn keyPressed() bool {
    if (!initalised) return false;

    const inp = inputter orelse return false;
    return inp.keyPressed();
}
