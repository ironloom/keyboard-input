const std = @import("std");
const Allocator = std.mem.Allocator;

const Inputter = @import("../Inputter.zig");

const KEYMAP_BUFFER_LENGTH: comptime_int = 256;

extern "user32" fn GetAsyncKeyState(virtual_key: i32) callconv(.winapi) i16;

var keymap_frame_buffer: [KEYMAP_BUFFER_LENGTH]bool = @splat(false);
var keymap_cache_buffer: [KEYMAP_BUFFER_LENGTH]bool = @splat(false);

var is_initialized = false;

fn init(_: Allocator) !void {
    is_initialized = true;
}

fn update() void {
    if (!is_initialized)
        return;

    @memcpy(&keymap_cache_buffer, &keymap_frame_buffer);

    for (0..KEYMAP_BUFFER_LENGTH) |key_index| {
        keymap_frame_buffer[key_index] = GetAsyncKeyState(@intCast(key_index)) < 0;
    }
}

fn deinit() void {
    is_initialized = false;
}

fn getKey(key: u8) bool {
    if (!is_initialized) return false;
    const uppercase_key = std.ascii.toUpper(key);
    return keymap_frame_buffer[uppercase_key];
}

fn getKeyDown(key: u8) bool {
    if (!is_initialized) return false;
    const uppercase_key = std.ascii.toUpper(key);
    if (keymap_cache_buffer[uppercase_key]) return false;
    return getKey(key);
}

fn getKeyUp(key: u8) bool {
    if (!is_initialized) return false;
    const uppercase_key = std.ascii.toUpper(key);
    if (!keymap_cache_buffer[uppercase_key]) return false;
    return !getKey(key);
}

fn keyPressed() bool {
    if (!is_initialized) return false;
    for (keymap_frame_buffer) |is_pressed| {
        if (is_pressed) return true;
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
