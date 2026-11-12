pub const DIR = opaque {};
pub const dirent = extern struct {
    d_ino: u64,
    d_off: i64,
    d_reclen: u16,
    d_type: u8,
    d_name: [256]u8,
};
pub const timeval = extern struct {
    tv_sec: isize,
    tv_usec: isize,
};
pub const input_event = extern struct {
    time: timeval,
    type: u16,
    code: u16,
    value: i32,
};

pub const O_RDONLY: c_int = 0;
pub const O_NONBLOCK: c_int = 0o4000;
pub const EV_KEY: u16 = 0x01;
pub const KEY_SPACE: usize = 57;

pub fn EVIOCGBIT(event_type: u32, length_bytes: u32) c_ulong {
    return (@as(c_ulong, 2) << 30) | (@as(c_ulong, length_bytes) << 16) | (@as(c_ulong, 'E') << 8) | @as(c_ulong, 0x20 + event_type);
}

pub extern "c" fn opendir(name: [*:0]const u8) ?*DIR;
pub extern "c" fn closedir(directory: *DIR) c_int;
pub extern "c" fn readdir(directory: *DIR) ?*dirent;
pub extern "c" fn open(path: [*:0]const u8, flags: c_int, ...) c_int;
pub extern "c" fn close(file_descriptor: c_int) c_int;
pub extern "c" fn read(file_descriptor: c_int, buffer: *anyopaque, count_bytes: usize) isize;
pub extern "c" fn ioctl(file_descriptor: c_int, request: c_ulong, ...) c_int;
