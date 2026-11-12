const std = @import("std");
const Allocator = std.mem.Allocator;
const Inputter = @import("../Inputter.zig");

const c_bindings = @import("c_linux.zig");
const event_path: [*:0]const u8 = "/dev/input";

const KEYMAP_BUFFER_LENGTH: comptime_int = 768;
const KEYBIT_WORD_COUNT: comptime_int = KEYMAP_BUFFER_LENGTH / 32;
const DEVICE_PATH_BUFFER_LENGTH: comptime_int = 280;

var keymap_buffer: [KEYMAP_BUFFER_LENGTH]bool = @splat(false);
var last_keymap_buffer: [KEYMAP_BUFFER_LENGTH]bool = @splat(false);
var is_initialized: bool = false;
var input_device_descriptor: c_int = -1;

fn isKeyboardDevice(file_descriptor: c_int) bool {
    var event_bits: [1]u32 = @splat(0);
    _ = c_bindings.ioctl(file_descriptor, c_bindings.EVIOCGBIT(0, @sizeOf(@TypeOf(event_bits))), &event_bits);

    const has_key_events = (event_bits[0] & (@as(u32, 1) << @as(u5, @intCast(c_bindings.EV_KEY)))) != 0;
    if (!has_key_events) return false;

    var key_bits: [KEYBIT_WORD_COUNT]u32 = @splat(0);
    _ = c_bindings.ioctl(file_descriptor, c_bindings.EVIOCGBIT(c_bindings.EV_KEY, @sizeOf(@TypeOf(key_bits))), &key_bits);

    const space_bit = c_bindings.KEY_SPACE;
    const space_word_index = space_bit / 32;
    const space_bit_offset: u5 = @intCast(space_bit % 32);
    const space_mask = @as(u32, 1) << space_bit_offset;

    return (key_bits[space_word_index] & space_mask) != 0;
}

fn buildDevicePath(entry_name: []const u8, path_buffer: *[DEVICE_PATH_BUFFER_LENGTH]u8) ?[*:0]const u8 {
    const prefix = "/dev/input/";
    const total_length = prefix.len + entry_name.len;
    if (total_length >= path_buffer.len) return null;

    @memcpy(path_buffer[0..prefix.len], prefix);
    @memcpy(path_buffer[prefix.len..total_length], entry_name);
    path_buffer[total_length] = 0;
    return @ptrCast(path_buffer[0..total_length :0]);
}

fn findKeyboardDeviceDescriptor() ?c_int {
    const directory = c_bindings.opendir(event_path) orelse return null;
    defer _ = c_bindings.closedir(directory);

    var path_buffer: [DEVICE_PATH_BUFFER_LENGTH]u8 = undefined;

    while (c_bindings.readdir(directory)) |entry| {
        const entry_name = std.mem.span(@as([*:0]const u8, @ptrCast(&entry.d_name)));
        if (entry_name.len == 0 or entry_name[0] == '.') continue;

        const device_path = buildDevicePath(entry_name, &path_buffer) orelse continue;
        const file_descriptor = c_bindings.open(device_path, c_bindings.O_RDONLY | c_bindings.O_NONBLOCK);
        if (file_descriptor < 0) continue;

        if (isKeyboardDevice(file_descriptor)) {
            return file_descriptor;
        }

        _ = c_bindings.close(file_descriptor);
    }

    return null;
}

fn convertAsciiToLinuxMagicCode(ascii: u8) u8 {
    return switch (ascii) {
        27 => 1,
        8 => 14,
        9 => 15,
        13 => 28,
        32 => 57,
        49 => 2,
        50 => 3,
        51 => 4,
        52 => 5,
        53 => 6,
        54 => 7,
        55 => 8,
        56 => 9,
        57 => 10,
        48 => 11,
        45 => 12,
        61 => 13,
        91 => 26,
        93 => 27,
        59 => 39,
        39 => 40,
        96 => 41,
        92 => 43,
        44 => 51,
        46 => 52,
        47 => 53,
        97 => 30,
        98 => 48,
        99 => 46,
        100 => 32,
        101 => 18,
        102 => 33,
        103 => 34,
        104 => 35,
        105 => 23,
        106 => 36,
        107 => 37,
        108 => 38,
        109 => 50,
        110 => 49,
        111 => 24,
        112 => 25,
        113 => 16,
        114 => 19,
        115 => 31,
        116 => 20,
        117 => 22,
        118 => 47,
        119 => 17,
        120 => 45,
        121 => 21,
        122 => 44,
        42 => 55,
        43 => 78,
        40 => 179,
        41 => 180,
        else => 0,
    };
}

fn init(_: Allocator) !void {
    @memset(&keymap_buffer, false);
    @memcpy(&last_keymap_buffer, &keymap_buffer);

    input_device_descriptor = findKeyboardDeviceDescriptor() orelse return;

    is_initialized = true;
}

fn update() void {
    if (!is_initialized) return;

    @memcpy(&last_keymap_buffer, &keymap_buffer);

    var event: c_bindings.input_event = undefined;

    while (true) {
        const bytes_read = c_bindings.read(input_device_descriptor, &event, @sizeOf(c_bindings.input_event));
        if (bytes_read < @sizeOf(c_bindings.input_event)) break;
        if (event.type != c_bindings.EV_KEY) continue;
        if (event.code >= KEYMAP_BUFFER_LENGTH) continue;

        keymap_buffer[event.code] = (event.value != 0);
    }
}

fn deinit() void {
    if (!is_initialized) return;

    _ = c_bindings.close(input_device_descriptor);
    is_initialized = false;
}

fn getKey(key: u8) bool {
    return keymap_buffer[convertAsciiToLinuxMagicCode(key)];
}

fn getKeyDown(key: u8) bool {
    if (last_keymap_buffer[convertAsciiToLinuxMagicCode(key)]) return false;
    return getKey(key);
}

fn getKeyUp(key: u8) bool {
    if (!last_keymap_buffer[convertAsciiToLinuxMagicCode(key)]) return false;
    return !getKey(key);
}

fn keyPressed() bool {
    if (!is_initialized) return false;
    for (keymap_buffer) |is_key_pressed| {
        if (is_key_pressed) return true;
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
