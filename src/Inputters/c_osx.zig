pub const IOHIDManagerRef = *anyopaque;
pub const IOHIDValueRef = *anyopaque;
pub const IOHIDElementRef = *anyopaque;
pub const CFRunLoopRef = *anyopaque;
pub const CFStringRef = *anyopaque;
pub const CFAllocatorRef = ?*anyopaque;
pub const IOReturn = i32;
pub const IOOptionBits = u32;
pub const CFIndex = isize;
pub const CFTimeInterval = f64;
pub const Boolean = u8;

pub const kCFAllocatorDefault: CFAllocatorRef = null;
pub const kIOHIDOptionsTypeNone: IOOptionBits = 0;
pub const kHIDPage_KeyboardOrKeypad: u32 = 0x07;
pub const TRUE: Boolean = 1;
pub const FALSE: Boolean = 0;
pub const NULL: ?*anyopaque = null;

pub extern "C" fn IOHIDManagerCreate(allocator: CFAllocatorRef, options: IOOptionBits) IOHIDManagerRef;
pub extern "C" fn IOHIDManagerSetDeviceMatching(manager: IOHIDManagerRef, matching: ?*anyopaque) void;
pub extern "C" fn IOHIDManagerRegisterInputValueCallback(manager: IOHIDManagerRef, callback: *const fn(?*anyopaque, IOReturn, ?*anyopaque, IOHIDValueRef) callconv(.c) void, context: ?*anyopaque) void;
pub extern "C" fn IOHIDManagerScheduleWithRunLoop(manager: IOHIDManagerRef, runLoop: CFRunLoopRef, runLoopMode: CFStringRef) void;
pub extern "C" fn IOHIDManagerOpen(manager: IOHIDManagerRef, options: IOOptionBits) IOReturn;
pub extern "C" fn IOHIDValueGetElement(value: IOHIDValueRef) IOHIDElementRef;
pub extern "C" fn IOHIDElementGetUsagePage(element: IOHIDElementRef) u32;
pub extern "C" fn IOHIDElementGetUsage(element: IOHIDElementRef) u32;
pub extern "C" fn IOHIDValueGetIntegerValue(value: IOHIDValueRef) CFIndex;
pub extern "C" fn CFRunLoopGetCurrent() CFRunLoopRef;
pub extern "C" fn CFRunLoopRunInMode(mode: CFStringRef, seconds: CFTimeInterval, returnAfterSourceHandled: Boolean) i32;
pub extern "C" fn CFRelease(arg: ?*anyopaque) void;

pub extern "C" const kCFRunLoopDefaultMode: CFStringRef;
