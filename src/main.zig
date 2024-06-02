const std = @import("std");
const pzo = @import("progrezzo");

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("# Progrezzo examples.\n", .{});

    try bw.flush(); // don't forget to flush!

    var pb = pzo.Progrezzo.init(100, 20, try pzo.Style.init(std.heap.page_allocator, pzo.SmoothStyleOpts));
    try pb.draw();
    std.debug.print("\n", .{});
    pb.currVal = 33;
    try pb.draw();
    std.debug.print("\n", .{});
    pb.currVal = 100;
    try pb.draw();
    std.debug.print("\n", .{});

    for (0..101) |val| {
        std.debug.print("\r", .{});
        pb.currVal = val;
        try pb.draw();
        // Sleep for 100 ms
        std.time.sleep(20_000_000);
    }
}
