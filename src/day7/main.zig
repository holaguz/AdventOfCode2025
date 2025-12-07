const std = @import("std");
const Allocator = std.mem.Allocator;
const Deque = @import("aoc").Deque;
const CacheKey = struct { y: usize, x: usize };

const assert = std.debug.assert;
const stdin = std.fs.File.stdin();
const stdout = std.fs.File.stdout();

var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
const allocator = gpa.allocator();
var cache: std.AutoHashMap(CacheKey, usize) = .init(allocator);

fn readFile(file: std.fs.File) !std.ArrayList([]u8) {
    const input = try file.readToEndAlloc(allocator, std.math.maxInt(usize));

    var it = std.mem.splitScalar(u8, input, '\n');
    var lines = std.ArrayList([]u8).empty;

    while (it.next()) |l| {
        if (l.len > 0) {
            try lines.append(allocator, @constCast(l));
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

fn solve(input: [][]u8) ![2]usize {
    var part_1: usize = 0;
    var part_2: usize = 0;

    const max_y = input.len;
    const max_x = input[0].len;

    std.log.info("Maze size: {}, {}", .{ max_y, max_x });

    var queue = Deque([2]usize).empty;

    // Find the start position
    const start_x = std.mem.indexOfScalar(u8, input[0], 'S') orelse @panic("Invalid input");

    // Enqueue the start position
    try queue.pushBack(allocator, [_]usize{ 1, start_x });
    input[1][start_x] = '|';

    while (queue.popBack()) |pos| {
        const y, const x = pos;

        // Hit a spliter
        if (input[y][x] == '^') {
            part_1 += 1;

            // Modify the ^ to signify that this splitter has been processed
            input[y][x] = 'X';

            if (x < max_x) {
                if (input[y][x + 1] == '.') input[y][x + 1] = '|';
                try queue.pushBack(allocator, [_]usize{ y, x + 1 });
            }
            if (x > 0) {
                if (input[y][x - 1] == '.') input[y][x - 1] = '|';
                try queue.pushBack(allocator, [_]usize{ y, x - 1 });
            }
        }
        // Continue the beam downwards
        else if (input[y][x] == '|') {
            const ny = y + 1;

            // Bounds check for end of the maze
            if (ny < max_y) {
                if (input[ny][x] == '.') input[ny][x] = '|';
                try queue.pushBack(allocator, [_]usize{ ny, x });
            }
        }
    }

    // The first splitter is always at y = 2
    part_2 = try dfs(input, 2, start_x);

    return .{ part_1, part_2 };
}

fn dfs(input: [][]u8, y: usize, x: usize) !usize {
    const max_y = input.len;
    const max_x = input[0].len;

    if (y >= max_y) return 1;

    const key: CacheKey = .{ .y = y, .x = x };
    if (cache.get(key)) |hit| return hit;

    var result: usize = 0;
    if (input[y][x] == 'X') {
        if (x > 0) {
            result += try dfs(input, y, x + 1);
        }

        if (x < max_x) {
            result += try dfs(input, y, x - 1);
        }

    } else {
            result += try dfs(input, y + 1, x);
    }

    try cache.put(key, result);
    return result;
}
