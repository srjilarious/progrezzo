const std = @import("std");
const udec = std.unicode.utf8Decode;
const uenc = std.unicode.utf8Encode;

const printer = @import("./printer.zig");

pub const Printer = printer.Printer;
pub const Colors = printer.Style;

pub const ValueDisplay = enum { None, CurrentValueOnly, CurrentAndMaxValue, Percentage };

pub const Symbol = struct {
    bytes: [4]u8,
    len: u3,

    pub fn init(val: []const u8) Symbol {
        var sym = Symbol{ .bytes = [4]u8{ 0, 0, 0, 0 }, .len = std.unicode.utf8ByteSequenceLength(val[0]) catch unreachable };

        std.mem.copyForwards(u8, sym.bytes[0..], val[0..]);
        return sym;
    }

    pub fn draw(self: *const Symbol, print: Printer) !void {
        try print.print("{s}", .{self.bytes});
    }
};

pub const StyleOpts = struct {
    leftCap: []const u8,
    rightCap: []const u8,
    emptyChar: []const u8,
    doneChar: []const u8,
    fillChars: []const []const u8,
    capColor: ?Colors = null,
    fillColor: ?Colors = null,
    emptyColor: ?Colors = null,
    percentColor: ?Colors = null,
    // Used for brackets around percent, value from total separator
    separatorColor: ?Colors = null,
    valueColor: ?Colors = null,
    totalColor: ?Colors = null,
    unitColor: ?Colors = null,
    withColor: bool = true,
    withPercentage: bool = true,
    withValue: bool = false,
    withTotal: bool = false,
    valueDivisor: u64 = 1,
    valueUnit: ?[]const u8 = null,
};

pub const Style = struct {
    alloc: std.mem.Allocator,
    leftCap: Symbol,
    rightCap: Symbol,
    emptyChar: Symbol,
    doneChar: Symbol,
    fillChars: []const Symbol,
    capColor: ?Colors = null,
    fillColor: ?Colors = null,
    emptyColor: ?Colors = null,
    percentColor: ?Colors = null,
    // Used for brackets around percent, value from total separator
    separatorColor: ?Colors = null,
    valueColor: ?Colors = null,
    totalColor: ?Colors = null,
    unitColor: ?Colors = null,
    withColor: bool,
    withPercentage: bool,
    withValue: bool,
    withTotal: bool,
    valueDivisor: u64 = 1,
    valueUnit: ?[]const u8 = null,

    pub fn init(alloc: std.mem.Allocator, opts: StyleOpts) !Style {
        var fill = try alloc.alloc(Symbol, opts.fillChars.len);
        for (0..opts.fillChars.len) |idx| {
            fill[idx] = Symbol.init(opts.fillChars[idx]);
        }

        return .{
            .alloc = alloc,
            .leftCap = Symbol.init(opts.leftCap),
            .rightCap = Symbol.init(opts.rightCap),
            .emptyChar = Symbol.init(opts.emptyChar),
            .doneChar = Symbol.init(opts.doneChar),
            .capColor = opts.capColor,
            .fillColor = opts.fillColor,
            .emptyColor = opts.emptyColor,
            .percentColor = opts.percentColor,
            .separatorColor = opts.separatorColor,
            .valueColor = opts.valueColor,
            .totalColor = opts.totalColor,
            .unitColor = opts.unitColor,
            .fillChars = fill,
            .withColor = opts.withColor,
            .withPercentage = opts.withPercentage,
            .withValue = opts.withValue,
            .withTotal = opts.withTotal,
            .valueDivisor = opts.valueDivisor,
            .valueUnit = opts.valueUnit,
        };
    }

    pub fn deinit(self: *Style) void {
        self.alloc.free(self.fillChars);
    }
};

pub const DefaultStyleOpts: StyleOpts = .{
    .leftCap = "[",
    .rightCap = "]",
    .emptyChar = "-",
    .doneChar = "#",
    .fillChars = &[_][]const u8{ "-", "=" },
    .capColor = .{ .fg = .Yellow, .bg = .Reset },
    .emptyColor = .{ .fg = .Gray, .bg = .Reset },
    .fillColor = .{ .fg = .BrightGreen, .bg = .Reset },
    .percentColor = .{ .fg = .BrightWhite, .bg = .Reset, .mod = .{ .bold = true } },
    .valueColor = .{ .fg = .BrightWhite, .bg = .Reset },
    .totalColor = .{ .fg = .BrightWhite, .bg = .Reset },
};

pub const SmoothStyleOpts: StyleOpts = .{
    .leftCap = "\u{2595}", // Right 1/8th block
    .rightCap = "\u{258f}", // Left 1/8th block
    .emptyChar = " ",
    .doneChar = "\u{2588}",
    .fillChars = &[_][]const u8{ "\u{258f}", "\u{258d}", "\u{258b}", "\u{2589}", "\u{2588}" },
    .capColor = .{ .fg = .BrightWhite, .bg = .Reset },
    .emptyColor = .{ .fg = .Red, .bg = .Red },
    .fillColor = .{ .fg = .BrightGreen, .bg = .Red },
    .percentColor = .{ .fg = .BrightWhite, .bg = .Reset, .mod = .{ .bold = true } },
    .valueColor = .{ .fg = .BrightWhite, .bg = .Reset },
    .totalColor = .{ .fg = .BrightWhite, .bg = .Reset },
};

//pub const ProgrezzoModel = struct {}
pub const Progrezzo = struct {
    style: Style,
    currVal: u64,
    maxVal: u64,
    lineLength: usize,
    valueDisplay: ValueDisplay,
    printer: Printer,

    pub fn init(maxVal: u64, lineLength: usize, style: Style, print: Printer) Progrezzo {
        return .{ .style = style, .printer = print, .currVal = 0, .maxVal = maxVal, .lineLength = lineLength, .valueDisplay = .CurrentAndMaxValue };
    }

    pub fn defaultBar(maxVal: u64, lineLength: usize, alloc: std.mem.Allocator) !Progrezzo {
        return init(maxVal, lineLength, try Style.init(alloc, DefaultStyleOpts));
    }

    pub fn deinit(self: *Progrezzo) void {
        self.style.deinit();
    }

    fn percentDone(self: *Progrezzo) f32 {
        const val = @min(self.currVal, self.maxVal);
        return @as(f32, @floatFromInt(val)) /
            @as(f32, @floatFromInt(self.maxVal));
    }

    fn handleColor(self: *Progrezzo, color: ?Colors) !void {
        if (color == null) {
            try Colors.reset(self.printer);
        } else {
            try color.?.set(self.printer);
        }
    }

    pub fn draw(self: *Progrezzo) !void {
        const pctDone = self.percentDone();
        const progWidth = pctDone * @as(f32, @floatFromInt(self.lineLength));
        const numDone: u64 = @intFromFloat(progWidth);
        const fractional = progWidth - std.math.floor(progWidth);
        const hasPartial = self.style.fillChars.len > 0 and fractional > std.math.floatEps(f32);
        const partialIdx: usize = @intFromFloat(fractional * @as(f32, @floatFromInt(self.style.fillChars.len)));

        try self.handleColor(self.style.capColor);
        try self.style.leftCap.draw(self.printer);

        try self.handleColor(self.style.fillColor);
        for (0..numDone) |_| {
            try self.style.doneChar.draw(self.printer);
        }

        var numEmpty = self.lineLength - numDone;
        if (hasPartial) {
            try self.style.fillChars[partialIdx].draw(self.printer);
            numEmpty -= 1;
        }

        try self.handleColor(self.style.emptyColor);
        for (0..numEmpty) |_| {
            try self.style.emptyChar.draw(self.printer);
        }

        try self.handleColor(self.style.capColor);
        try self.style.rightCap.draw(self.printer);

        if (self.style.withValue or self.style.withTotal) {
            try self.handleColor(self.style.separatorColor);
            try self.printer.print(" [", .{});
        }

        if (self.style.withValue) {
            try self.handleColor(self.style.valueColor);
            try self.printer.print("{d}", .{self.currVal / self.style.valueDivisor});
            if (self.style.valueUnit != null) {
                try self.handleColor(self.style.unitColor);
                try self.printer.print("{s}", .{self.style.valueUnit.?});
            }
        }

        if (self.style.withTotal) {
            if (self.style.withValue) {
                try self.handleColor(self.style.separatorColor);
                try self.printer.print(" / ", .{});
            }

            try self.handleColor(self.style.totalColor);
            try self.printer.print("{d}", .{self.maxVal / self.style.valueDivisor});
            if (self.style.valueUnit != null) {
                try self.handleColor(self.style.unitColor);
                try self.printer.print("{s}", .{self.style.valueUnit.?});
            }
        }

        if (self.style.withValue or self.style.withTotal) {
            try self.handleColor(self.style.separatorColor);
            try self.printer.print("]", .{});
        }

        if (self.style.withPercentage) {
            try self.handleColor(self.style.percentColor);
            try self.printer.print(" {d:.2} %", .{pctDone * 100.0});
        }
        try self.printer.flush();
    }
};
