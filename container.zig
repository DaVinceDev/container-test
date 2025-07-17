const std = @import("std");
const eql = std.mem.eql;
const linux = std.os.linux;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const args = std.process.argsAlloc(allocator) catch return 1;

    if (args.len <= 1) {
        std.debug.print("Try a valid command.\n", .{});
        return 1;
    }

    const command_args = args[1..];
    if (eql(u8, "run", command_args[0])) {
        const rawCommand = std.mem.concat(allocator, []const u8, &[_][]const u8{ "/proc/self/exe", "child" });
        defer allocator.free(rawCommand);

        const buf = try allocator.alloc(u8, rawCommand.len);
        std.mem.copyForwards(u8, buf.ptr, rawCommand);
        container(toExecute, buf);
    }

    if (eql(u8, "child", command_args[0]))
        child(allocator, command_args[1..]);
}

fn container(func: *const fn (usize) callconv(.c) u8, argv: usize) !void {
    const stack_size = 4096 * 4;
    var stack: [stack_size]u8 align(16) = undefined; // this is a buffer with the stack size calculated
    const stack_top = @intFromPtr(&stack) + stack.len; // a reference of the stack top

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

fn child(allocator: std.mem.Allocator, args: []const u8) !void {
    std.debug.print("Running ", .{});
    runCommand(allocator, &[_][]const u8{args});
}

fn runCommand(allocator: std.mem.Allocator, args: []const []const u8) !void {
    var process = std.process.Child.init(args, allocator);

    process.stdin_behavior = .Inherit;
    process.stdout_behavior = .Inherit;
    process.stderr_behavior = .Inherit;

    const result = process.spawnAndWait() catch return error.FailedToSpawn;

    if (result != .Exited) std.debug.print("Error happened.\n", .{});
}

fn toExecute(argv: usize) callconv(.c) u8 {
    const allocator = std.heap.page_allocator;
    const arg_ptr: [*]const u8 = @ptrCast(argv);
    runCommand(allocator, arg_ptr);
}
