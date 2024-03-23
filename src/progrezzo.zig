// zig fmt: off
const std = @import("std");
const udec = std.unicode.utf8Decode;

pub const ValueDisplay = enum {
    None,
    CurrentValueOnly,
    CurrentAndMaxValue,
    Percentage
};

// We use u21 so that unicode values can be used for styling.
pub const Style = struct {
    leftCap: u21,
    rightCap: u21,
    emptySpace: u21,
    doneChar: u21,
    fillChars: std.ArrayList(u21),

    pub fn defaultStyle(alloc: std.mem.Allocator) !Style{
        var fill = std.ArrayList(u21).init(alloc);
        try fill.append(try udec("."));
        try fill.append(try udec(","));
        try fill.append(try udec("-"));
        try fill.append(try udec("="));

        return .{ 
            .leftCap = try udec("["),
            .rightCap = try udec("]"),
            .emptySpace = try udec(" "),
            .doneChar = try udec("#"),
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
};
