const std = @import("std");
const Allocator = @import("std").mem.Allocator;

const Inputter = @import("../Inputter.zig");

const BUFFER_LEN: comptime_int = 256;
pub const c = @import("c");

extern "user32" fn GetKeyboardState(lpKeyState: [*]u8) callconv(.winapi) i32;

var keymap_frame_buffer: [BUFFER_LEN]bool = [_]bool{false} ** BUFFER_LEN;
var keymap_cache_buffer: [BUFFER_LEN]bool = [_]bool{false} ** BUFFER_LEN;

var initalised = false;

fn init(_: Allocator) !void {
    initalised = true;
}

fn update() void {
    if (!initalised)
        return;

    @memcpy(&keymap_cache_buffer, &keymap_frame_buffer);

    var keys: [256]u8 = undefined;
    _ = GetKeyboardState(&keys);

    for (0..BUFFER_LEN) |i| {
        keymap_frame_buffer[i] = (keys[i] & 0x80) != 0;
    }
}

fn deinit() void {
    initalised = false;
}

fn getKey(k: u8) bool {
    if (!initalised) return false;
    return keymap_frame_buffer[std.ascii.toUpper(k)];
}

fn getKeyDown(k: u8) bool {
    if (!initalised) return false;
    const key = std.ascii.toUpper(k);
    if (keymap_cache_buffer[key]) return false;
    return getKey(k);
}

fn getKeyUp(k: u8) bool {
    if (!initalised) return false;
    const key = std.ascii.toUpper(k);
    if (!keymap_cache_buffer[key]) return false;
    return !getKey(k);
}

fn keyPressed() bool {
    if (!initalised) return false;
    for (keymap_frame_buffer) |key| {
        if (key) return true;
    }
    return false;
}

pub const inputter: Inputter = .{
    .init = init,
    .update = update,
    .deinit = deinit,
    .getKey = getKey,
    .getKeyDown = getKeyDown,
    .getKeyUp = getKeyUp,
    .keyPressed = keyPressed,
};
