const std = @import("std");
const progrezzo = @import("progrezzo");

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("# Progrezzo examples.\n", .{});

    try bw.flush(); // don't forget to flush!

    const pb = try progrezzo.Progrezzo.init(100, 60, std.heap.page_allocator);
    _ = pb;
}
