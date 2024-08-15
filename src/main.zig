const std = @import("std");
const pzo = @import("progrezzo");

fn testPbar(pb: *pzo.Progrezzo, step: usize) void {
    try pb.draw();
    std.debug.print("\n", .{});
    pb.currVal = 33;
    try pb.draw();
    std.debug.print("\n", .{});
    pb.currVal = 100;
    try pb.draw();
    std.debug.print("\n", .{});

    while (pb.currVal < pb.maxVal) {
        std.debug.print("\r", .{});
        pb.currVal += step;
        try pb.draw();
        // Sleep for 50 ms
        std.time.sleep(50_000_000);
    }
    std.debug.print("\n\n", .{});
}

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("# Progrezzo examples.\n", .{});

    try bw.flush(); // don't forget to flush!

    {
        var pb = pzo.Progrezzo.init(1024 * 30, 40, try pzo.Style.init(std.heap.page_allocator, pzo.DefaultStyleOpts));
        defer pb.deinit();
        testPbar(&pb, 256);
    }

    {
        var pb = pzo.Progrezzo.init(1024 * 30, 40, try pzo.Style.init(std.heap.page_allocator, pzo.SmoothStyleOpts));
        defer pb.deinit();
        testPbar(&pb, 128);
    }

    // A custom style
    {
        const style = try pzo.Style.init(std.heap.page_allocator, .{
            .leftCap = "\u{2523}", // Left T
            .rightCap = "\u{252b}", // Right T
            .emptyChar = "\u{2588}",
            .doneChar = "\u{2588}",
            // blocks growing from bottom
            .fillChars = &[_][]const u8{ "\u{2581}", "\u{2582}", "\u{2583}", "\u{2584}", "\u{2585}", "\u{2586}", "\u{2587}", "\u{2588}" },
            .capColor = .{ .fg = .BoldCyan, .bg = .Reset },
            .emptyColor = .{ .fg = .Blue, .bg = .Reset },
            .fillColor = .{ .fg = .BoldYellow, .bg = .Blue },
        });
        var pb = pzo.Progrezzo.init(1024 * 30, 40, style);
        defer pb.deinit();
        testPbar(&pb, 128);
    }
}
