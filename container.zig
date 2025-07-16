const std = @import("std");
const eql = std.mem.eql;
const linux = std.os.linux;

pub fn main() anyerror!void {
    const stack_size = 4096 * 4;
    var stack: [stack_size]u8 align(16) = undefined; // this is a buffer with the stack size calculated
    const stack_top = @intFromPtr(&stack) + stack.len; // a reference of the stack top

    const flags = linux.CLONE.NEWUTS | linux.CLONE.NEWPID | linux.CLONE.NEWNS | linux.SIG.CHLD;
    const pid_usize = linux.clone(toExecute, stack_top, flags, 0, null, 0, null);

    const INVALID_PID: usize = @bitCast(@as(isize, -1));
    if (pid_usize == INVALID_PID) {
        std.debug.print("Clone failed. Reason: Unkown \n", .{});
        return error.CloneFailed;
    }
    if (pid_usize == @intFromEnum(linux.E.INVAL)) return error.InvalidArgument;

    //pid pid
    const pid: i32 = @intCast(pid_usize);

    var status: u32 = 0;
    _ = std.os.linux.waitpid(pid, &status, 0);
}

fn runCommand(allocator: std.mem.Allocator, args: []const []const u8) !void {
    var child = std.process.Child.init(args, allocator);

    child.stdin_behavior = .Inherit;
    child.stdout_behavior = .Inherit;
    child.stderr_behavior = .Inherit;

    const result = child.spawnAndWait() catch return error.FailedToSpawn;

    if (result != .Exited) std.debug.print("Error happened.\n", .{});
}
fn toExecute(_: usize) callconv(.c) u8 {
    const allocator = std.heap.page_allocator;

    runCommand(allocator, &[_][]const u8{"hostname"}) catch return 1;

    runCommand(allocator, &[_][]const u8{ "hostname", "zig-host" }) catch return 1;

    runCommand(allocator, &[_][]const u8{"hostname"}) catch return 1;
    return 0;
}
