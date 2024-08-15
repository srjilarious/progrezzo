// zig fmt: off
const std = @import("std");
const udec = std.unicode.utf8Decode;
const uenc = std.unicode.utf8Encode;

pub const ValueDisplay = enum {
    None,
    CurrentValueOnly,
    CurrentAndMaxValue,
    Percentage
};

pub const Color = enum {
    Reset,
    Black,
    Red,
    Green,
    Yellow,
    Blue,
    Magenta,
    Cyan,
    White,
    Gray,
    BoldRed,
    BoldGreen,
    BoldYellow,
    BoldBlue,
    BoldMagenta,
    BoldCyan,
    BoldWhite
};

pub const Colors = struct {
    fg: Color,
    bg: Color,

    pub fn reset() void {
        std.debug.print("\x1b[0m", .{});
    }

    pub fn set(self: *const Colors) void {
        if(self.fg == .Reset or self.bg == .Reset) {
            reset();
        }
        
        switch(self.bg) 
        {
            .Black => std.debug.print("\x1b[40m", .{}),
            .Red => std.debug.print("\x1b[41m", .{}),
            .Green => std.debug.print("\x1b[42m", .{}),
            .Yellow => std.debug.print("\x1b[43m", .{}),
            .Blue => std.debug.print("\x1b[44m", .{}),
            .Magenta => std.debug.print("\x1b[45m", .{}),
            .Cyan => std.debug.print("\x1b[46m", .{}),
            .White => std.debug.print("\x1b[47m", .{}),
            .Gray => std.debug.print("\x1b[40;1m", .{}),
            .BoldRed => std.debug.print("\x1b[41;1m", .{}),
            .BoldGreen => std.debug.print("\x1b[42;1m", .{}),
            .BoldYellow => std.debug.print("\x1b[43;1m", .{}),
            .BoldBlue => std.debug.print("\x1b[44;1m", .{}),
            .BoldMagenta => std.debug.print("\x1b[45;1m", .{}),
            .BoldCyan => std.debug.print("\x1b[46;1m", .{}),
            .BoldWhite => std.debug.print("\x1b[47;1m", .{}),
            else => {},
        }

        switch(self.fg) 
        {
            .Black => std.debug.print("\x1b[30m", .{}),
            .Red => std.debug.print("\x1b[31m", .{}),
            .Green => std.debug.print("\x1b[32m", .{}),
            .Yellow => std.debug.print("\x1b[33m", .{}),
            .Blue => std.debug.print("\x1b[34m", .{}),
            .Magenta => std.debug.print("\x1b[35m", .{}),
            .Cyan => std.debug.print("\x1b[36m", .{}),
            .White => std.debug.print("\x1b[37m", .{}),
            .Gray => std.debug.print("\x1b[30;1m", .{}),
            .BoldRed => std.debug.print("\x1b[31;1m", .{}),
            .BoldGreen => std.debug.print("\x1b[32;1m", .{}),
            .BoldYellow => std.debug.print("\x1b[33;1m", .{}),
            .BoldBlue => std.debug.print("\x1b[34;1m", .{}),
            .BoldMagenta => std.debug.print("\x1b[35;1m", .{}),
            .BoldCyan => std.debug.print("\x1b[36;1m", .{}),
            .BoldWhite => std.debug.print("\x1b[37;1m", .{}),
            else => {},
        }
    }
};

pub const Symbol = struct {
    bytes: [4]u8,
    len: u3,
    
    pub fn init(val: []const u8) Symbol {
        var sym = Symbol{ 
            .bytes = [4]u8{0, 0, 0, 0},
            .len = std.unicode.utf8ByteSequenceLength(val[0]) catch unreachable
        };

        std.mem.copyForwards(u8, sym.bytes[0..], val[0..]);
        return sym;
    }

    pub fn draw(self: *const Symbol) void {
        std.debug.print("{s}", .{self.bytes});
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
    withColor: bool = true
};

pub const Style = struct {
    alloc: std.mem.Allocator,
    leftCap: Symbol,
    rightCap: Symbol,
    emptyChar: Symbol,
    doneChar: Symbol,
    fillChars: [] const Symbol,
    capColor: ?Colors = null,
    fillColor: ?Colors = null,
    emptyColor: ?Colors = null,
    withColor: bool,

    pub fn init(alloc: std.mem.Allocator, opts: StyleOpts) !Style {
        var fill = try alloc.alloc(Symbol, opts.fillChars.len);
        for(0..opts.fillChars.len) |idx| {
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
            .fillChars = fill,
            .withColor = opts.withColor
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
    .fillChars = &[_][]const u8{"-", "="},
    .capColor = .{ .fg = .Yellow, .bg = .Reset },
    .emptyColor = .{ .fg = .Gray, .bg = .Reset },
    .fillColor = .{ .fg = .BoldGreen, .bg = .Reset },
};

pub const SmoothStyleOpts: StyleOpts = .{
    .leftCap = "\u{2595}", // Right 1/8th block
    .rightCap = "\u{258f}", // Left 1/8th block
    .emptyChar = " ",
    .doneChar = "\u{2588}",
    .fillChars = &[_][]const u8{"\u{258f}", "\u{258d}", "\u{258b}", "\u{2589}", "\u{2588}"},
    .capColor = .{ .fg = .BoldWhite, .bg = .Reset },
    .emptyColor = .{ .fg = .Red, .bg = .Red },
    .fillColor = .{ .fg = .BoldGreen, .bg = .Red },
};

pub const Progrezzo = struct {
    style: Style,
    currVal: u64,
    maxVal: u64,
    lineLength: usize,
    valueDisplay: ValueDisplay,

    pub fn init(
        maxVal: u64, 
        lineLength: usize, 
        style: Style) Progrezzo 
    {
        return .{ 
            .style = style, 
            .currVal = 0, 
            .maxVal = maxVal, 
            .lineLength = lineLength,
            .valueDisplay = .CurrentAndMaxValue
        };
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

    fn handleColor(color: ?Colors) void {
        if(color == null) {
            Colors.reset();
        }
        else {
            color.?.set();
        }
    }

    pub fn draw(self: *Progrezzo) !void {
        const pctDone = self.percentDone();
        const progWidth = pctDone * @as(f32, @floatFromInt(self.lineLength));
        const numDone: u64 = @intFromFloat(progWidth);
        const fractional = progWidth - std.math.floor(progWidth);
        const hasPartial = self.style.fillChars.len > 0 and fractional > std.math.floatEps(f32);
        const partialIdx : usize = @intFromFloat(fractional * @as(f32, @floatFromInt(self.style.fillChars.len)));

        handleColor(self.style.capColor);
        self.style.leftCap.draw();

        handleColor(self.style.fillColor);
        for(0..numDone) |_| {
            self.style.doneChar.draw();
        }

        var numEmpty = self.lineLength - numDone;
        if(hasPartial) {
            self.style.fillChars[partialIdx].draw();
            numEmpty -= 1;
        }

        handleColor(self.style.emptyColor);
        for(0..numEmpty) |_| {
            self.style.emptyChar.draw();
        }
        
        handleColor(self.style.capColor);
        self.style.rightCap.draw();
    }
};
