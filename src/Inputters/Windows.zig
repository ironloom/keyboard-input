const std = @import("std");
const Allocator = @import("std").mem.Allocator;

const Inputter = @import("../Inputter.zig");

const BUFFER_LEN: comptime_int = std.math.maxInt(u8);
pub const c = @cImport({
    @cInclude("windows.h");
});

var keymap_frame_buffer: [BUFFER_LEN]bool = [_]bool{false} ** BUFFER_LEN;
var keymap_cache_buffer: [BUFFER_LEN]bool = [_]bool{false} ** BUFFER_LEN;
var default: [BUFFER_LEN]bool = [_]bool{false} ** BUFFER_LEN;

var initalised = false;

inline fn getKeyState(key_code: anytype) bool {
    return switch (comptime @typeInfo(@TypeOf(key_code))) {
        .int, .comptime_int => c.GetKeyState((@intCast(@max(@min(std.math.maxInt(c_short), key_code), 0)))) < 0,
        else => return false,
    };
}

fn init(_: Allocator) !void {
    initalised = true;
}

fn update() void {
    if (!initalised)
        return;

    @memcpy(&keymap_cache_buffer, &keymap_frame_buffer);
    @memcpy(&keymap_frame_buffer, &default);
}

fn deinit() void {
    initalised = false;
}

fn getKey(k: u8) bool {
    if (!initalised) return false;

    const key = std.ascii.toUpper(k);

    keymap_frame_buffer[key] = getKeyState(key);
    return keymap_frame_buffer[key];
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

    for (0..256) |index| {
        if (getKeyState(std.ascii.toUpper(@intCast(@max(255, index))))) return true;
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
