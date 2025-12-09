const std = @import("std");
const Allocator = std.mem.Allocator;

const assert = std.debug.assert;
const stdin = std.fs.File.stdin();
const stdout = std.fs.File.stdout();

var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
const allocator = gpa.allocator();

fn readFile(file: std.fs.File) ![][]u8 {
    const input = try file.readToEndAlloc(allocator, std.math.maxInt(usize));

    var it = std.mem.splitScalar(u8, input, '\n');
    var lines = std.ArrayList([]u8).empty;

    while (it.next()) |l| {
        if (l.len > 0) {
            try lines.append(allocator, @constCast(l));
        }
    }

    return lines.toOwnedSlice(allocator);
}

pub fn main() !void {
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.skip();

    const file = if (args.next()) |filepath| blk: {
        std.log.debug("Opening file {s}", .{filepath});
        break :blk try std.fs.cwd().openFile(filepath, .{});
    } else stdin;

    const lines = try readFile(file);
    defer allocator.free(lines);
    std.log.debug("Parsed {} lines", .{lines.len});

    const part1, const part2 = try solve(lines);

    var stdout_writer = stdout.writer(&.{});
    try stdout_writer.interface.print("Part 1: {}\nPart 2: {}\n", .{ part1, part2 });
}

fn solve(input: [][]u8) ![2]usize {
    var part_1: usize = 0;
    var part_2: usize = 0;
    _ = input;

    part_1 = 0;
    part_2 = 0;
    return .{ part_1, part_2 };
}
