const std = @import("std");
const Allocator = @import("std").mem.Allocator;
const Inputter = @import("../Inputter.zig");

const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
    @cInclude("fcntl.h");
    @cInclude("unistd.h");
    @cInclude("string.h");
    @cInclude("dirent.h");
    @cInclude("linux/input.h");
});
const event_path: []const u8 = "/dev/input";

var allocator: Allocator = std.heap.smp_allocator;
var keymap_buffer: []bool = undefined;
var last_keymap_buffer: []bool = undefined;
var initalised = false;
var is_key_pressed = false;
var input_device_file: std.fs.File = undefined;

fn findKeyboard() !?[]u8 {
    var dir = try std.fs.openDirAbsolute(event_path, .{ .iterate = true });
    defer dir.close();

    std.log.debug("dir: {s}", .{event_path});

    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        if (entry.kind == .directory) continue;

        const path = try std.fs.path.join(allocator, &.{
            event_path,
            entry.name,
        });
        defer allocator.free(path);

        std.log.debug("path: {s}", .{path});

        var file = try dir.openFile(entry.name, .{ .mode = .read_only });
        defer file.close();

        const file_descriptor = file.handle;
        var name: [256]u8 = [_]u8{0} ** 256;
        const res = c.ioctl(file_descriptor, c.EVIOCGNAME(8 * 256), &name);

        std.log.debug("ioctl result: {d}", .{res});
        std.log.debug("- name: {s}", .{name});

        if (std.mem.containsAtLeast(
            u8,
            &name,
            1,
            "keyboard",
        )) {
            return try allocator.dupe(u8, path);
        }
    }

    return null;
}

fn convertAsciiToLinuxMagicCode(ascii: u8) u8 {
    return switch (ascii) {
        // Control characters
        27 => 1, // ESC
        8 => 14, // Backspace
        9 => 15, // Tab
        13 => 28, // Enter (prioritize main ENTER over keypad ENTER (96))
        32 => 57, // Spa
        49 => 2, // '1'
        50 => 3, // '2'
        51 => 4, // '3'
        52 => 5, // '4'
        53 => 6, // '5'
        54 => 7, // '6'
        55 => 8, // '7'
        56 => 9, // '8'
        57 => 10, // '9'
        48 => 11, // '
        45 => 12, // '-'
        61 => 13, // '='
        91 => 26, // '['
        93 => 27, // ']'
        59 => 39, // ';'
        39 => 40, // '''
        96 => 41, // '`'
        92 => 43, // '\'
        44 => 51, // ','
        46 => 52, // '.' (main keyboard)
        47 => 53, // '
        97 => 30, // 'a'
        98 => 48, // 'b'
        99 => 46, // 'c'
        100 => 32, // 'd'
        101 => 18, // 'e'
        102 => 33, // 'f'
        103 => 34, // 'g'
        104 => 35, // 'h'
        105 => 23, // 'i'
        106 => 36, // 'j'
        107 => 37, // 'k'
        108 => 38, // 'l'
        109 => 50, // 'm'
        110 => 49, // 'n'
        111 => 24, // 'o'
        112 => 25, // 'p'
        113 => 16, // 'q'
        114 => 19, // 'r'
        115 => 31, // 's'
        116 => 20, // 't'
        117 => 22, // 'u'
        118 => 47, // 'v'
        119 => 17, // 'w'
        120 => 45, // 'x'
        121 => 21, // 'y'
        122 => 44, // '
        42 => 55, // '*' (keypad)
        43 => 78, // '+' (keypad)
        40 => 179, // '(' (keypad)
        41 => 180, // ')' (keypa
        else => 0, // Unmapped
    };
}

fn init(alloc: Allocator) !void {
    allocator = alloc;

    keymap_buffer = try allocator.alloc(bool, std.math.maxInt(u8));
    last_keymap_buffer = try allocator.alloc(bool, std.math.maxInt(u8));

    const path = try findKeyboard() orelse return;
    input_device_file = try std.fs.openFileAbsolute(
        path,
        .{ .mode = .read_only },
    );

    initalised = true;
}

fn update() void {
    if (!initalised)
        return;

    is_key_pressed = false;
    @memcpy(last_keymap_buffer, keymap_buffer);

    var event: c.input_event = undefined;

    const bytes_read: c.ssize_t = c.read(input_device_file.handle, &event, @sizeOf(c.input_event));
    _ = bytes_read;
    if (event.type == c.EV_KEY) keymap_buffer[event.code] = @intFromBool(event.value);
}

fn deinit() void {
    if (!initalised)
        return;

    input_device_file.close();

    allocator.free(keymap_buffer);
    allocator.free(last_keymap_buffer);
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
