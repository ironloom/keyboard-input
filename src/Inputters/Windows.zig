const std = @import("std");
const Allocator = @import("std").mem.Allocator;

const Inputter = @import("../Inputter.zig");

pub const c = @cImport({
    @cInclude("windows.h");
});

var keymap_buffer: []bool = undefined;
var last_keymap_buffer: []bool = undefined;
var alloc: Allocator = std.heap.smp_allocator;
var initalised = false;
var is_key_pressed = false;

fn init(allocator: Allocator) !void {
    keymap_buffer = try allocator.alloc(bool, std.math.maxInt(u8));
    last_keymap_buffer = try allocator.alloc(bool, std.math.maxInt(u8));

    alloc = allocator;
    initalised = true;
}

fn update() void {
    if (!initalised)
        return;

    // var keyboardstate: [256]u8 = undefined;
    // _ = c.GetKeyboardState(&keyboardstate);

    // for (keyboardstate) |state| {
    //     if (state == 0) continue;

    //     is_key_pressed = true;
    //     break;
    // }

    @memcpy(last_keymap_buffer, keymap_buffer);
}

fn deinit() void {
    if (!initalised)
        return;

    alloc.free(keymap_buffer);
    alloc.free(last_keymap_buffer);
}

fn getKey(k: u8) bool {
    const key = std.ascii.toUpper(k);
    keymap_buffer[key] = c.GetKeyState(@intCast(key)) < 0;
    return keymap_buffer[key];
}

fn getKeyDown(k: u8) bool {
    const key = std.ascii.toUpper(k);
    if (last_keymap_buffer[key]) return false;
    return getKey(k);
}

fn getKeyUp(k: u8) bool {
    const key = std.ascii.toUpper(k);
    if (!last_keymap_buffer[key]) return false;
    return !getKey(k);
}

fn keyPressed() bool {
    return is_key_pressed;
}

pub const WindowsInputter: Inputter = .{
    .init = init,
    .update = update,
    .deinit = deinit,
    .getKey = getKey,
    .getKeyDown = getKeyDown,
    .getKeyUp = getKeyUp,
    .keyPressed = keyPressed,
};
