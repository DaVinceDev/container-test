const std = @import("std");
const eql = std.mem.eql;
const linux = std.os.linux;

// linux.clone(
// func: *const fn(arg:usize)callconv(.c)u8, -> This function is the execution of your code inside the container
// stack: usize, -> This is the stack that will be used to "create" space for the container
// flags: u32, -> These are the flags used to "define the behaviors" of your container
// arg: usize, -> This is the argument passed to your function
// ptid: ?*i32, -> Don't really know what it is but is nullable
// tp: usize, -> Also dont know but is better to set it to 0
// ctid: ?*i32 -> If its nullable and idk how to used it then null is the way to go
// )
pub fn main() anyerror!void {
    // STACK CALCULATION
    const stack_size = 4096 * 4;
    var stack: [stack_size]u8 align(16) = undefined;
    const stack_top = @intFromPtr(&stack) + stack.len;
    //

    // SETTING FLAGS
    const flags = linux.CLONE.NEWUTS | linux.CLONE.NEWPID | linux.CLONE.NEWNS | linux.SIG.CHLD;

    // CALLING CLONE AND GETTING ITS PID
    const pid_usize = linux.clone(toExecute, stack_top, flags, 0, null, 0, null);

    // CHECKS FOR VALID PID
    const INVALID_PID: usize = @bitCast(@as(isize, -1));
    if (pid_usize == INVALID_PID) {
        std.debug.print("Clone failed. Reason: Unkown \n", .{});
        return error.CloneFailed;
    }
    if (pid_usize == @intFromEnum(linux.E.INVAL)) return error.InvalidArgument;
    //

    // CASTING PID TO i32 type to allow the next operation
    const pid: i32 = @intCast(pid_usize);

    // THIS WAITS FOR THE FUNCTION TO EXECUTE
    var status: u32 = 0;
    _ = std.os.linux.waitpid(pid, &status, 0);
}

/// Executes command
fn runCommand(allocator: std.mem.Allocator, args: []const []const u8) !void {
    var child = std.process.Child.init(args, allocator);

    child.stdin_behavior = .Inherit;
    child.stdout_behavior = .Inherit;
    child.stderr_behavior = .Inherit;

    const result = child.spawnAndWait() catch return error.FailedToSpawn;

    if (result != .Exited) std.debug.print("Error happened.\n", .{});
}

// THIS IS THE FUNTION TO BE EXECUTED THE RETURN TYPE NEEDS TO BE callconv(.c) u8
// NOTICE HOW WE RETURN NUMBERS AND NOT VOID! IT'S LIKE IN C `duh`
fn toExecute(_: usize) callconv(.c) u8 {
    const allocator = std.heap.page_allocator;

    runCommand(allocator, &[_][]const u8{"hostname"}) catch return 1;

    runCommand(allocator, &[_][]const u8{ "hostname", "zig-host" }) catch return 1;

    runCommand(allocator, &[_][]const u8{"hostname"}) catch return 1;
    return 0;
}
