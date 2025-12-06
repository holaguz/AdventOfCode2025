const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const day = b.option(u8, "day", "day") orelse 0;
    const day_str = std.fmt.allocPrint(b.allocator, "day{}", .{day}) catch std.process.exit(1);
    const challenge_path = std.mem.concat(b.allocator, u8, &[_][]const u8{
        "src/",
        day_str,
        "/main.zig",
    }) catch std.process.exit(1);

    const exe = b.addExecutable(.{
        .name = day_str,
        .root_module = b.createModule(.{
            .root_source_file = b.path(challenge_path),

            .target = target,
            .optimize = optimize,
        }),
    });

    b.installArtifact(exe);

    const test_step = b.step("test", "Run unit tests");

    const unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path(challenge_path),
            .target = target
        }),
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);
    test_step.dependOn(&run_unit_tests.step);

    const run_step = b.step("run", "Solve the challenge");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}
