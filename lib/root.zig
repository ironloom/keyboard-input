const std = @import("std");
const builtin = @import("builtin");
const Allocator = std.mem.Allocator;

const Inputter = @import("Inputter.zig");

const windows_inputter = @import("./Inputters/Windows.zig").inputter;
const macos_inputter = @import("./Inputters/OSX.zig").inputter;
const linux_inputter = @import("./Inputters/Linux.zig").inputter;

const inputter: ?Inputter = switch (builtin.os.tag) {
    .macos => macos_inputter,
    .windows => windows_inputter,
    .linux => linux_inputter,
    else => null,
};
var is_initialized = false;
var stored_allocator: ?Allocator = null;

pub fn init(allocator: Allocator) !void {
    const active_inputter = inputter orelse {
        std.log.err(
            "keyboard-input does not support current OS (supported: MacOS, Linux, Windows)",
            .{},
        );
        return;
    };

    stored_allocator = allocator;
    try active_inputter.init(stored_allocator.?);

    is_initialized = true;
}

/// This calls `init()` with the `std.heap.smp_allocator`. Handles setup error by aborting the process.
pub export fn initSafe() void {
    init(std.heap.smp_allocator) catch {
        std.log.err("keyboard-input setup failed", .{});
    };
}

fn flushWindowsConsoleInput() void {
    const kernel32 = struct {
        extern "kernel32" fn GetStdHandle(standard_handle: i32) callconv(.winapi) ?*anyopaque;
        extern "kernel32" fn FlushConsoleInputBuffer(console_input_handle: ?*anyopaque) callconv(.winapi) i32;
    };
    _ = kernel32.FlushConsoleInputBuffer(kernel32.GetStdHandle(-10));
}

fn flushPosixInput() void {
    const posix = struct {
        extern "c" fn tcflush(file_descriptor: i32, action: i32) i32;
    };
    const flush_input_action: i32 = if (comptime builtin.os.tag == .macos) 1 else 0;
    _ = posix.tcflush(std.posix.STDIN_FILENO, flush_input_action);
}

fn eatStdin() void {
    if (comptime builtin.os.tag == .windows) {
        flushWindowsConsoleInput();
        return;
    }
    flushPosixInput();
}

/// Call every frame to update the keyboard state.
pub export fn update() void {
    if (!is_initialized) return;

    eatStdin();

    const active_inputter = inputter orelse return;
    active_inputter.update();
}

pub export fn deinit() void {
    if (!is_initialized) return;

    eatStdin();

    const active_inputter = inputter orelse return;
    active_inputter.deinit();
}

/// Returns the current keystate, `true` if the key is pressed, `false` if not.
pub export fn getKey(key: u8) bool {
    if (!is_initialized) return false;

    const active_inputter = inputter orelse return false;
    return active_inputter.getKey(key);
}

/// Returns whether or not the key has been pressed for the first time.
pub export fn getKeyDown(key: u8) bool {
    if (!is_initialized) return false;

    const active_inputter = inputter orelse return false;
    return active_inputter.getKeyDown(key);
}

/// Returns true when the key is released.
pub export fn getKeyUp(key: u8) bool {
    if (!is_initialized) return false;

    const active_inputter = inputter orelse return false;
    return active_inputter.getKeyUp(key);
}

/// Checks is any key has been pressed.
///
/// **NOTE: THIS MAY NOT WORK CORRECTLY ON SOME OPERATING SYSTEMS.**
///
/// *Currently works on: Windows, MacOS*
pub export fn keyPressed() bool {
    if (!is_initialized) return false;

    const active_inputter = inputter orelse return false;
    return active_inputter.keyPressed();
}
