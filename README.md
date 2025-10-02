<div align="center">
    <img src="resources/keyboard_input_large.png" width="750"/>
    <h1>Keyboard Input</h1>
    <p>The Keyboard Input handling library you were looking for.</p>
</div>
 
> [!WARNING]
> This library currently only supports ASCII characters.

> [!IMPORTANT]
> This library targets zig version 0.15.1, and will get updated to future versions.

## Installing the Library

1. Fetch the dependency:

```sh
zig fetch --save git+https://github.com/ironloom/keyboard-input.git
```

2. Add the following to your `build.zig`

```zig
const kb_input_dep = b.dependency("keyboard_input", .{
    .optimize = optimize,
    .target = target,
});
const kb_input_mod = kb_input_dep.module("keyboard_input");

build_step.addImport("kb_input", kb_input_mod); // Replace with actual build step
```

3. Import the module:

```zig
const kb_input = @import("kb_input");
```

## Simple Example

Using the library is easy, here is a quick example:

```zig
const kb_input = @import("kb_input");

pub fn main() !void {
    kb_input.init();
    defer kb_input.deinit();

    while (!kb_input.getKeyDown('q')) { // Press Q to quit the app
        kb_input.update();
    }
}
```
