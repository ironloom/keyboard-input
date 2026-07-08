const std = @import("std");
const Allocator = @import("std").mem.Allocator;
const Inputter = @import("../Inputter.zig");

const c = @import("c");
const event_path: [*:0]const u8 = "/dev/input";

const BUFFER_LEN: comptime_int = 768;

var keymap_buffer: [BUFFER_LEN]bool = [_]bool{false} ** BUFFER_LEN;
var last_keymap_buffer: [BUFFER_LEN]bool = [_]bool{false} ** BUFFER_LEN;
var initalised = false;
var input_device_fd: c_int = -1;

fn findKeyboard(allocator: Allocator) !?[]u8 {
    const dir = c.opendir(event_path);
    if (dir == null) return null;
    defer _ = c.closedir(dir);

    while (true) {
        const entry = c.readdir(dir);
        if (entry == null) break;

        const d_name = std.mem.span(@as([*:0]u8, @ptrCast(&entry.*.d_name)));
        if (d_name.len == 0 or d_name[0] == '.') continue;

        const path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ event_path, d_name });
        defer allocator.free(path);

        const fd = c.open(path.ptr, c.O_RDONLY | c.O_NONBLOCK);
        if (fd < 0) continue;
        defer _ = c.close(fd);

        var evbit: [1]u32 = [_]u32{0};
        _ = c.ioctl(fd, c.EVIOCGBIT(0, @sizeOf(@TypeOf(evbit))), &evbit);

        if ((evbit[0] & (1 << c.EV_KEY)) != 0) {
            var keybit: [768 / 32]u32 = [_]u32{0} ** (768 / 32);
            _ = c.ioctl(fd, c.EVIOCGBIT(c.EV_KEY, @sizeOf(@TypeOf(keybit))), &keybit);

            const space_bit = c.KEY_SPACE;
            if ((keybit[space_bit / 32] & (@as(u32, 1) << (space_bit % 32))) != 0) {
                return try allocator.dupe(u8, path);
            }
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
        41 => 180, // ')' (keypad)
        else => 0, // Unmapped
    };
}

fn init(allocator: Allocator) !void {
    for (&keymap_buffer) |*slot| {
        slot.* = false;
    }
    @memcpy(&last_keymap_buffer, &keymap_buffer);

    const path = try findKeyboard(allocator) orelse return;
    defer allocator.free(path);
    input_device_fd = c.open(path.ptr, c.O_RDONLY | c.O_NONBLOCK);

    initalised = true;
}

fn update() void {
    if (!initalised)
        return;

    @memcpy(&last_keymap_buffer, &keymap_buffer);

    var event: c.input_event = undefined;

    while (true) {
        const bytes_read = c.read(input_device_fd, &event, @sizeOf(c.input_event));
        if (bytes_read < @sizeOf(c.input_event)) break;

        if (event.type == c.EV_KEY) {
            if (event.code < BUFFER_LEN) {
                keymap_buffer[event.code] = event.value != 0;
            }
        }
    }
}

fn deinit() void {
    if (!initalised)
        return;

    _ = c.close(input_device_fd);
    initalised = false;
}

fn getKey(k: u8) bool {
    return keymap_buffer[convertAsciiToLinuxMagicCode(k)];
}

fn getKeyDown(k: u8) bool {
    if (last_keymap_buffer[convertAsciiToLinuxMagicCode(k)]) return false;
    return getKey(k);
}

fn getKeyUp(k: u8) bool {
    if (!last_keymap_buffer[convertAsciiToLinuxMagicCode(k)]) return false;
    return !getKey(k);
}

fn keyPressed() bool {
    if (!initalised) return false;
    for (keymap_buffer) |key| {
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
