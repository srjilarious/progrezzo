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
};

pub const Style = struct {
    alloc: std.mem.Allocator,
    leftCap: Symbol,
    rightCap: Symbol,
    emptyChar: Symbol,
    doneChar: Symbol,
    fillChars: [] const Symbol,

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
            .fillChars = fill,
        };
    }

    pub fn deinit(self: *Style) void {
        self.alloc.free(self.fillChars);
    }
};

pub const DefaultStyleOpts: StyleOpts = .{
    .leftCap = "[",
    .rightCap = "]",
    .emptyChar = " ",
    .doneChar = "#",
    .fillChars = &[_][]const u8{".", ",", "-", "="}
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
        return @as(f32, @floatFromInt(self.currVal)) / 
                @as(f32, @floatFromInt(self.maxVal));
    }

    pub fn draw(self: *Progrezzo) !void {
        const pctDone = self.percentDone();
        const progWidth = pctDone * @as(f32, @floatFromInt(self.lineLength));
        const numDone: u64 = @intFromFloat(progWidth);
        const fractional = progWidth - std.math.floor(progWidth);
        const hasPartial = self.style.fillChars.len > 0 and fractional > std.math.floatEps(f32);
        const partialIdx : usize = @intFromFloat(fractional * @as(f32, @floatFromInt(self.style.fillChars.len)));


        self.style.leftCap.draw();

        for(0..numDone) |_| {
            self.style.doneChar.draw();
        }

        var numEmpty = self.lineLength - numDone;
        if(hasPartial) {
            self.style.fillChars[partialIdx].draw();
            numEmpty -= 1;
        }

        for(0..numEmpty) |_| {
            self.style.emptyChar.draw();
        }
        
        self.style.rightCap.draw();
    }
};
