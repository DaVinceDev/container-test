const std = @import("std");
const linux = std.os.linux;

// Argument wrapper duh
const ArgsWrapper = struct {
    args: []const []const u8,
};

// Entry point duh
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const args = std.process.argsAlloc(allocator) catch return;

    if (args.len <= 1) {
        std.debug.print("Try a valid command.\n", .{});
        return;
    }

    const command_args = args[1..];
    const wrapper = try allocator.create(ArgsWrapper);
    wrapper.args = command_args;
    try container(toExecute, @intFromPtr(wrapper));
}

fn container(func: *const fn (usize) callconv(.c) u8, argv: usize) !void {
    const stack_size = 4096 * 4;
    var stack: [stack_size]u8 align(16) = undefined;
    const stack_top = @intFromPtr(&stack) + stack.len;
    const flags = linux.CLONE.NEWUTS | linux.CLONE.NEWPID | linux.CLONE.NEWNS | linux.SIG.CHLD;
    const pid_usize = linux.clone(func, stack_top, flags, argv, null, 0, null);

    const INVALID_PID: usize = @bitCast(@as(isize, -1));
    if (pid_usize == INVALID_PID) {
        std.debug.print("Clone failed. Reason: Unkown \n", .{});
        return error.CloneFailed;
    }
    if (pid_usize == @intFromEnum(linux.E.INVAL)) return error.InvalidArgument;

    const pid: i32 = @intCast(pid_usize);

    var status: u32 = 0;
    _ = std.os.linux.waitpid(pid, &status, 0);
}

fn runCommand(allocator: std.mem.Allocator, args: []const []const u8) !void {
    var process = std.process.Child.init(args, allocator);

    process.stdin_behavior = .Inherit;
    process.stdout_behavior = .Inherit;
    process.stderr_behavior = .Inherit;

    const result = try process.spawnAndWait();

    switch (result) {
        .Exited => {},
        .Signal => |sig| std.debug.print("Process exited with signal {}.\n", .{sig}),
        else => |e| std.debug.print("Unexpected behavior. Error:{}\n", .{e}),
    }
}

fn toExecute(argv: usize) callconv(.c) u8 {
    const allocator = std.heap.page_allocator;
    const wrapper: *ArgsWrapper = @ptrFromInt(argv);
    const args = wrapper.args;

    std.debug.print("Running {s} as PID {}...\n", .{ args[0], linux.getpid() });

    try chroot();
    runCommand(allocator, args) catch |e| {
        std.debug.print("Error while trying to execute command: {}\n", .{e});
        return 1;
    };
    return 0;
}

// Mounts proc duh
fn monty() !void {
    _ = linux.unshare(linux.CLONE.NEWNS);
    const mount_flags = linux.MS.NOSUID | linux.MS.NOEXEC | linux.MS.NODEV;
    _ = linux.mount("proc", "/proc", "proc", mount_flags, 0);
}

// This changes the directory to the rootfs downloaded in the dockerfile
// To confirm its existence you can `ll /`
fn chroot() !void {
    _ = linux.chroot("/rootfs");
    _ = linux.chdir("/");
    try monty();
}
