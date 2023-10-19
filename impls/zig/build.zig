const LibExeObjStep = @import("std").build.LibExeObjStep;
const Builder = @import("std").build.Builder;
const builtin = @import("builtin");

const warn = @import("std").debug.warn;

pub fn build(b: *Builder) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const exes = [_]*LibExeObjStep{
        b.addExecutable(.{ .name = "step0_repl", .root_source_file = .{ .path = "step0_repl.zig" }, .optimize = optimize, .target = target }),
        b.addExecutable(.{ .name = "step1_read_print", .root_source_file = .{ .path = "step1_read_print.zig" }, .optimize = optimize, .target = target }),
        // b.addExecutable(.{ .name = "step2_eval", .root_source_file = .{ .path = "step2_eval.zig" }, .optimize = optimize }),
        // b.addExecutable(.{ .name = "step3_env", .root_source_file = .{ .path = "step3_env.zig" }, .optimize = optimize }),
        // b.addExecutable(.{ .name = "step4_if_fn_do", .root_source_file = .{ .path = "step4_if_fn_do.zig" }, .optimize = optimize }),
        // b.addExecutable(.{ .name = "step5_tco", .root_source_file = .{ .path = "step5_tco.zig" }, .optimize = optimize }),
        // b.addExecutable(.{ .name = "step6_file", .root_source_file = .{ .path = "step6_file.zig" }, .optimize = optimize }),
        // b.addExecutable(.{ .name = "step7_quote", .root_source_file = .{ .path = "step7_quote.zig" }, .optimize = optimize }),
        // b.addExecutable(.{ .name = "step8_macros", .root_source_file = .{ .path = "step8_macros.zig" }, .optimize = optimize }),
        // b.addExecutable(.{ .name = "step9_try", .root_source_file = .{ .path = "step9_try.zig" }, .optimize = optimize }),
        // b.addExecutable(.{ .name = "stepA_mal", .root_source_file = .{ .path = "stepA_mal.zig" }, .optimize = optimize }),
    };

    for (exes) |exe| {
        b.installArtifact(exe);
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        const run_step = b.step(exe.name, exe.name);
        run_step.dependOn(&run_cmd.step);
    }
}
