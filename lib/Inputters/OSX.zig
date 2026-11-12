const std = @import("std");
const Allocator = std.mem.Allocator;

const Inputter = @import("../Inputter.zig");

pub const c_bindings = @import("c_osx.zig");

const KEYMAP_BUFFER_LENGTH: comptime_int = std.math.maxInt(u8);

var keymap_buffer: [KEYMAP_BUFFER_LENGTH]bool = @splat(false);
var last_keymap_buffer: [KEYMAP_BUFFER_LENGTH]bool = @splat(false);
var hid_manager: c_bindings.IOHIDManagerRef = undefined;
var is_initialized = false;

fn callback(_: ?*anyopaque, _: c_bindings.IOReturn, _: ?*anyopaque, value: c_bindings.IOHIDValueRef) callconv(.c) void {
    const element: c_bindings.IOHIDElementRef = c_bindings.IOHIDValueGetElement(value);
    const usage_page = c_bindings.IOHIDElementGetUsagePage(element);
    const usage = c_bindings.IOHIDElementGetUsage(element);

    if (usage_page != c_bindings.kHIDPage_KeyboardOrKeypad) return;
    const pressed_value = c_bindings.IOHIDValueGetIntegerValue(value);

    if (usage >= KEYMAP_BUFFER_LENGTH) return;
    const key_index = @as(usize, @intCast(usage));
    keymap_buffer[key_index] = pressed_value != 0;
}

fn init(_: Allocator) !void {
    hid_manager = c_bindings.IOHIDManagerCreate(c_bindings.kCFAllocatorDefault, c_bindings.kIOHIDOptionsTypeNone);
    c_bindings.IOHIDManagerSetDeviceMatching(hid_manager, null);

    c_bindings.IOHIDManagerRegisterInputValueCallback(hid_manager, callback, c_bindings.NULL);
    c_bindings.IOHIDManagerScheduleWithRunLoop(hid_manager, c_bindings.CFRunLoopGetCurrent(), c_bindings.kCFRunLoopDefaultMode);

    _ = c_bindings.IOHIDManagerOpen(hid_manager, c_bindings.kIOHIDOptionsTypeNone);

    @memset(&keymap_buffer, false);
    @memcpy(&last_keymap_buffer, &keymap_buffer);

    is_initialized = true;
}

fn update() void {
    if (!is_initialized)
        return;

    @memcpy(&last_keymap_buffer, &keymap_buffer);
    _ = c_bindings.CFRunLoopRunInMode(c_bindings.kCFRunLoopDefaultMode, 0.0, c_bindings.TRUE);
}

fn deinit() void {
    if (!is_initialized)
        return;

    c_bindings.CFRelease(hid_manager);
    is_initialized = false;
}

fn getKey(key: u8) bool {
    return keymap_buffer[convertAsciiToAppleMagicCode(key)];
}

fn getKeyDown(key: u8) bool {
    if (last_keymap_buffer[convertAsciiToAppleMagicCode(key)]) return false;
    return getKey(key);
}

fn getKeyUp(key: u8) bool {
    if (!last_keymap_buffer[convertAsciiToAppleMagicCode(key)]) return false;
    return !getKey(key);
}

fn keyPressed() bool {
    if (!is_initialized) return false;

    for (keymap_buffer) |is_pressed| {
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

fn convertAsciiToAppleMagicCode(key: u8) u8 {
    return switch (key) {
        8 => 42,
        13 => 88,
        27 => 41,
        30 => 229,
        32 => 44,
        33 => 30,
        34 => 52,
        35 => 32,
        36 => 33,
        37 => 34,
        38 => 36,
        39 => 52,
        40 => 38,
        41 => 39,
        42 => 37,
        43 => 46,
        44 => 54,
        45 => 45,
        46 => 55,
        47 => 56,
        48 => 39,
        49 => 30,
        50 => 31,
        51 => 32,
        52 => 33,
        53 => 34,
        54 => 35,
        55 => 36,
        56 => 37,
        57 => 38,
        58 => 51,
        59 => 51,
        60 => 55,
        61 => 46,
        62 => 54,
        63 => 56,
        64 => 31,
        65 => 4,
        66 => 5,
        67 => 6,
        68 => 7,
        69 => 8,
        70 => 9,
        71 => 10,
        72 => 11,
        73 => 12,
        74 => 13,
        75 => 14,
        76 => 15,
        77 => 16,
        78 => 17,
        79 => 18,
        80 => 19,
        81 => 20,
        82 => 21,
        83 => 22,
        84 => 23,
        85 => 24,
        86 => 25,
        87 => 26,
        88 => 27,
        89 => 28,
        90 => 29,
        91 => 47,
        93 => 48,
        94 => 35,
        95 => 45,
        96 => 53,
        97 => 4,
        98 => 5,
        99 => 6,
        100 => 7,
        101 => 8,
        102 => 9,
        103 => 10,
        104 => 11,
        105 => 12,
        106 => 13,
        107 => 14,
        108 => 15,
        109 => 16,
        110 => 17,
        111 => 18,
        112 => 19,
        113 => 20,
        114 => 21,
        115 => 22,
        116 => 23,
        117 => 24,
        118 => 25,
        119 => 26,
        120 => 27,
        121 => 28,
        122 => 29,
        123 => 47,
        124 => 49,
        125 => 48,
        126 => 53,
        127 => 42,
        else => 0,
    };
}
