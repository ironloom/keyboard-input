const std = @import("std");

pub fn build(builder: *std.Build) !void {
    const target = builder.standardTargetOptions(.{});
    const optimize = builder.standardOptimizeOption(.{});

    const library_module = builder.createModule(.{
        .root_source_file = builder.path("lib/root.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    if (builder.lazyDependency("system_sdk", .{})) |system_sdk| {
        configureSystemSdk(library_module, system_sdk, target);
    }

    try builder.modules.put(builder.allocator, builder.dupe("keyboard_input"), library_module);

    const library = builder.addLibrary(.{
        .linkage = .dynamic,
        .name = "keyboard_input",
        .root_module = library_module,
    });
    builder.installArtifact(library);

    const executable_module = builder.createModule(.{
        .root_source_file = builder.path("examples/hello/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    executable_module.addImport("keyboard_input", library_module);

    const executable = builder.addExecutable(.{
        .name = "keyboard_input",
        .root_module = executable_module,
    });
    builder.installArtifact(executable);

    const run_command = builder.addRunArtifact(executable);
    run_command.step.dependOn(builder.getInstallStep());
    run_command.addPassthruArgs();

    const run_step = builder.step("run", "Run the demo");
    run_step.dependOn(&run_command.step);

    const library_unit_tests = builder.addTest(.{ .root_module = library_module });
    const run_library_unit_tests = builder.addRunArtifact(library_unit_tests);

    const executable_unit_tests = builder.addTest(.{ .root_module = executable_module });
    const run_executable_unit_tests = builder.addRunArtifact(executable_unit_tests);

    const test_step = builder.step("test", "Run unit tests");
    test_step.dependOn(&run_library_unit_tests.step);
    test_step.dependOn(&run_executable_unit_tests.step);
}

fn configureSystemSdk(
    library_module: *std.Build.Module,
    system_sdk: *std.Build.Dependency,
    target: std.Build.ResolvedTarget,
) void {
    const target_operating_system = target.result.os.tag;
    if (target_operating_system == .macos) {
        library_module.addLibraryPath(system_sdk.path("macos12/usr/lib"));
        library_module.addFrameworkPath(system_sdk.path("macos12/System/Library/Frameworks"));

        library_module.linkFramework("ApplicationServices", .{});
        library_module.linkFramework("IOKit", .{});
        library_module.linkFramework("CoreFoundation", .{});
        return;
    }

    if (target_operating_system == .windows) {
        const is_x86 = target.result.cpu.arch.isX86();
        const is_gnu_or_musl = target.result.abi.isGnu() or target.result.abi.isMusl();
        if (is_x86 and is_gnu_or_musl) {
            library_module.addLibraryPath(system_sdk.path("windows/lib/x86_64-windows-gnu"));
        }
        return;
    }

    if (target_operating_system == .linux) {
        const cpu_architecture = target.result.cpu.arch;
        if (cpu_architecture.isX86()) {
            library_module.addLibraryPath(system_sdk.path("linux/lib/x86_64-linux-gnu"));
        } else if (cpu_architecture == .aarch64) {
            library_module.addLibraryPath(system_sdk.path("linux/lib/aarch64-linux-gnu"));
        }
        return;
    }
}
