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
var lastlen: u64 = 0;

fn callback(_: ?*anyopaque, _: c.IOReturn, _: ?*anyopaque, value: c.IOHIDValueRef) callconv(.C) void {
    const element: c.IOHIDElementRef = c.IOHIDValueGetElement(value);
    const usagePage = c.IOHIDElementGetUsagePage(element);
    const usage = c.IOHIDElementGetUsage(element);

    if (usagePage != c.kHIDPage_KeyboardOrKeypad) return;

    const pressed = c.IOHIDValueGetIntegerValue(value);

    const key = std.math.cast(u8, usage);
    if (key == null) return;

    if (pressed != 0) {
        keymap_buffer[key.?] = true;
        return;
    }
    keymap_buffer[key.?] = false;
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
    return keymap_buffer[k];
}

fn getKeyDown(k: u8) bool {
    if (last_keymap_buffer[k]) return false;
    std.log.debug("asd", .{});
    return getKey(k);
}

fn getKeyUp(k: u8) bool {
    if (!last_keymap_buffer[k]) return false;
    return !getKey(k);
}

pub const OSXInputter: Inputter = .{
    .init = init,
    .update = update,
    .deinit = deinit,
    .getKey = getKey,
    .getKeyDown = getKeyDown,
    .getKeyUp = getKeyUp,
    .keyPressed = struct {
        pub fn callback() bool {
            return true;
        }
    }.callback,
};
