const std = @import("std");
const Allocator = @import("std").mem.Allocator;
const Inputter = @import("../Inputter.zig");

var alloc: Allocator = std.heap.smp_allocator;
var keymap_buffer: []bool = undefined;
var last_keymap_buffer: []bool = undefined;
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

    is_key_pressed = false;
    @memcpy(last_keymap_buffer, keymap_buffer);
}

fn deinit() void {
    if (!initalised)
        return;

    alloc.free(keymap_buffer);
    alloc.free(last_keymap_buffer);
}

fn getKey(k: u8) bool {
    return keymap_buffer[k];
}

fn getKeyDown(k: u8) bool {
    if (last_keymap_buffer[k]) return false;
    return getKey(k);
}

fn getKeyUp(k: u8) bool {
    if (!last_keymap_buffer[k]) return false;
    return !getKey(k);
}

fn keyPressed() bool {
    return is_key_pressed;
}

pub const LinuxInputter: Inputter = .{
    .init = init,
    .update = update,
    .deinit = deinit,
    .getKey = getKey,
    .getKeyDown = getKeyDown,
    .getKeyUp = getKeyUp,
    .keyPressed = keyPressed,
};
