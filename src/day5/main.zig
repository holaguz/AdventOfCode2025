const std = @import("std");
const Allocator = std.mem.Allocator;

const stdin = std.fs.File.stdin();
const stdout = std.fs.File.stdout();

var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
const allocator = gpa.allocator();

const Input = struct {
    ids: []usize,
    ranges: [][2]usize,
};

fn readFile(file: std.fs.File) !std.ArrayList([]const u8) {
    const input = try file.readToEndAlloc(allocator, std.math.maxInt(usize));

    var it = std.mem.splitScalar(u8, input, '\n');
    var lines = std.ArrayList([]const u8).empty;

    while (it.next()) |l| {
        if (l.len > 0) {
            try lines.append(allocator, l);
        }
    }

    return lines;
}

pub fn main() !void {
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.skip();

    const file = if (args.next()) |filepath| blk: {
        std.log.debug("Opening file {s}", .{filepath});
        break :blk try std.fs.cwd().openFile(filepath, .{});
    } else stdin;

    var lines = try readFile(file);
    defer lines.deinit(allocator);
    std.log.debug("Parsed {} lines", .{lines.items.len});

    const part1, const part2 = try solve(lines.items);

    var stdout_writer = stdout.writer(&.{});
    try stdout_writer.interface.print("Part 1: {}\nPart 2: {}\n", .{ part1, part2 });
}

fn parseInput(input: [][]const u8) !Input {
    var i: usize = 0;

    var ids = std.ArrayList(usize).empty;
    var ranges = std.ArrayList([2]usize).empty;

    while (true) : (i += 1) {
        var it = std.mem.tokenizeAny(u8, input[i], "-");

        const l = try std.fmt.parseInt(usize, it.next() orelse break, 10);
        const r = try std.fmt.parseInt(usize, it.next() orelse break, 10);

        try ranges.append(allocator, .{ l, r });
    }

    for (input[i..]) |l| {
        const num = try std.fmt.parseInt(usize, l, 10);
        try ids.append(allocator, num);
    }

    return .{
        .ids = try ids.toOwnedSlice(allocator),
        .ranges = try ranges.toOwnedSlice(allocator),
    };
}

fn mergeRanges(ranges: [][2]usize) [][2]usize {
    const sortFn = struct {
        fn f(_: void, lhs: [2]usize, rhs: [2]usize) bool {
            return lhs[0] < rhs[0];
        }
    }.f;

    std.mem.sort([2]usize, ranges, {}, sortFn);

    var write_ptr: usize = 0;

    for (ranges[1..]) |range| {
        const l, const r = range;

        if (l <= ranges[write_ptr][1] + 1) {
            ranges[write_ptr][1] = @max(ranges[write_ptr][1], r);
        } else {
            write_ptr += 1;
            ranges[write_ptr] = range;
        }
    }

    return ranges[0 .. write_ptr + 1];
}

fn solve(input: [][]const u8) ![2]usize {
    const parsed = try parseInput(input);
    const ids = parsed.ids;
    const ranges = mergeRanges(parsed.ranges);

    var part_1: usize = 0;
    var part_2: usize = 0;

    for (ids) |id| {
        for (ranges) |r| {
            if (id >= r[0] and id <= r[1]) {
                part_1 += 1;
                break;
            }
        }
    }

    for (ranges) |range| {
        part_2 += range[1] - range[0] + 1;
    }

    return .{ part_1, part_2 };
}
