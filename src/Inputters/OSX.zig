const std = @import("std");
const Allocator = @import("std").mem.Allocator;

const Inputter = @import("../Inputter.zig");

pub const c = @cImport({
    @cInclude("IOKit/hid/IOHIDManager.h");
    @cInclude("CoreFoundation/CoreFoundation.h");
});

var keymap_buffer: []bool = undefined;
var last_keymap_buffer: []bool = undefined;
var IOHIDManager: c.IOHIDManagerRef = undefined;
var alloc: Allocator = std.heap.smp_allocator;
var initalised = false;
var is_key_pressed = false;

fn callback(_: ?*anyopaque, _: c.IOReturn, _: ?*anyopaque, value: c.IOHIDValueRef) callconv(.C) void {
    const element: c.IOHIDElementRef = c.IOHIDValueGetElement(value);
    const usagePage = c.IOHIDElementGetUsagePage(element);
    const usage = c.IOHIDElementGetUsage(element);

    if (usagePage != c.kHIDPage_KeyboardOrKeypad) return;

    const pressed = c.IOHIDValueGetIntegerValue(value);

    const key = std.math.cast(u8, usage) orelse return;
    if (pressed == 0) return;

    keymap_buffer[key] = true;
    is_key_pressed = true;
}

fn init(allocator: Allocator) !void {
    IOHIDManager = c.IOHIDManagerCreate(c.kCFAllocatorDefault, c.kIOHIDOptionsTypeNone);
    c.IOHIDManagerSetDeviceMatching(IOHIDManager, null);

    c.IOHIDManagerRegisterInputValueCallback(IOHIDManager, callback, c.NULL);
    c.IOHIDManagerScheduleWithRunLoop(IOHIDManager, c.CFRunLoopGetCurrent(), c.kCFRunLoopDefaultMode);

    _ = c.IOHIDManagerOpen(IOHIDManager, c.kIOHIDOptionsTypeNone);

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
    _ = c.CFRunLoopRunInMode(c.kCFRunLoopDefaultMode, 0.01, c.TRUE);
}

fn deinit() void {
    if (!initalised)
        return;

    c.CFRelease(IOHIDManager);

    alloc.free(keymap_buffer);
    alloc.free(last_keymap_buffer);
}

fn getKey(k: u8) bool {
    return keymap_buffer[convertAsciiToAppleMagicCode(k)];
}

fn getKeyDown(k: u8) bool {
    if (last_keymap_buffer[convertAsciiToAppleMagicCode(k)]) return false;
    return getKey(k);
}

fn getKeyUp(k: u8) bool {
    if (!last_keymap_buffer[convertAsciiToAppleMagicCode(k)]) return false;
    return !getKey(k);
}

fn keyPressed() bool {
    return is_key_pressed;
}

pub const OSXInputter: Inputter = .{
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
