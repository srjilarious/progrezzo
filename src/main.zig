const std = @import("std");
const pzo = @import("progrezzo");

fn testPbar(pb: *pzo.Progrezzo, step: usize) !void {
    // try pb.draw();
    // std.debug.print("\n", .{});
    // pb.currVal = 33;
    // try pb.draw();
    // std.debug.print("\n", .{});
    // pb.currVal = 100;
    // try pb.draw();
    // std.debug.print("\n", .{});

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
    var printer = try pzo.Printer.stdout(std.heap.page_allocator);
    defer printer.deinit();

    {
        var pb = pzo.Progrezzo.init(1024 * 30, 40, try pzo.Style.init(std.heap.page_allocator, pzo.DefaultStyleOpts), printer);
        defer pb.deinit();
        try testPbar(&pb, 256);
    }

    {
        var pb = pzo.Progrezzo.init(1024 * 30, 40, try pzo.Style.init(std.heap.page_allocator, pzo.SmoothStyleOpts), printer);
        defer pb.deinit();
        try testPbar(&pb, 128);
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
            .capColor = .{ .fg = .BrightCyan, .bg = .Reset },
            .emptyColor = .{ .fg = .Blue, .bg = .Reset },
            .fillColor = .{ .fg = .BrightYellow, .bg = .Blue },
        });
        var pb = pzo.Progrezzo.init(1024 * 30, 40, style, printer);
        defer pb.deinit();
        try testPbar(&pb, 128);
    }
}
