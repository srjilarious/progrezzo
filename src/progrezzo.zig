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

    pub fn init(val: []const u8) !Symbol {
        var sym = Symbol{ 
            .bytes = [4]u8{0, 0, 0, 0},
            .len = try std.unicode.utf8ByteSequenceLength(val[0])
        };

        std.mem.copyForwards(u8, sym.bytes[0..], val[0..]);
        return sym;
    }

    pub fn draw(self: *Symbol) void {
        std.debug.print("{s}", .{self.bytes});
    }
};

// We use u21 so that unicode values can be used for styling.
pub const Style = struct {
    leftCap: Symbol,
    rightCap: Symbol,
    emptyChar: Symbol,
    doneChar: Symbol,
    fillChars: std.ArrayList(Symbol),

    pub fn defaultStyle(alloc: std.mem.Allocator) !Style{
        var fill = std.ArrayList(Symbol).init(alloc);
        try fill.append(try Symbol.init("."));
        try fill.append(try Symbol.init(","));
        try fill.append(try Symbol.init("-"));
        try fill.append(try Symbol.init("="));

        return .{ 
            .leftCap = try Symbol.init("["),
            .rightCap = try Symbol.init("]"),
            .emptyChar = try Symbol.init(" "),
            .doneChar = try Symbol.init("#"),
            .fillChars = fill,
        };
    }

    pub fn deinit(self: *Style) void {
        self.fillChars.deinit();
    }
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
        alloc: std.mem.Allocator) !Progrezzo 
    {
        return .{ 
            .style = try Style.defaultStyle(alloc), 
            .currVal = 0, 
            .maxVal = maxVal, 
            .lineLength = lineLength,
            .valueDisplay = .CurrentAndMaxValue
        };
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
        const hasPartial = self.style.fillChars.items.len > 0 and fractional > std.math.floatEps(f32);
        const partialIdx : usize = @intFromFloat(fractional * @as(f32, @floatFromInt(self.style.fillChars.items.len)));


        self.style.leftCap.draw();

        for(0..numDone) |_| {
            self.style.doneChar.draw();
        }

        var numEmpty = self.lineLength - numDone;
        if(hasPartial) {
            self.style.fillChars.items[partialIdx].draw();
            numEmpty -= 1;
        }

        for(0..numEmpty) |_| {
            self.style.emptyChar.draw();
        }
        
        self.style.rightCap.draw();
    }
};
