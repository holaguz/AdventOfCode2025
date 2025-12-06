const std = @import("std");
const Allocator = std.mem.Allocator;

const stdin = std.fs.File.stdin();
const stdout = std.fs.File.stdout();

var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
const allocator = gpa.allocator();

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

fn count_adj(maze: [][]const u8, y: usize, x: usize) usize {
    var count: usize = 0;

    for ([_]isize{ -1, 0, 1 }) |dy| {
        for ([_]isize{ -1, 0, 1 }) |dx| {
            if (dx == 0 and dy == 0) continue;

            const nx = x +% @as(usize, @bitCast(dx));
            const ny = y +% @as(usize, @bitCast(dy));

            if (ny >= maze.len or nx >= maze[0].len) continue;

            count += if (maze[ny][nx] == '@') 1 else 0;
        }
    }

    return count;
}

fn solve(input: [][]const u8) ![2]usize {
    var solved: [][]u8 = try allocator.alloc([]u8, input.len);
    for (input, 0..) |line, i| {
        solved[i] = try allocator.dupe(u8, line);
    }

    var part_1: usize = 0;
    var part_2: usize = 0;
    var iter: usize = 0;
    var modified = true;

    while (modified) : (iter += 1) {
        modified = false;

        for (0..input.len) |y| {
            for (0..input[0].len) |x| {
                if (solved[y][x] == '@') {
                    const adj = count_adj(@ptrCast(solved), y, x);
                    if (adj < 4) {
                        if (iter == 1) part_1 += 1;
                        part_2 += 1;

                        solved[y][x] = '.';
                        modified = true;
                    }
                }
            }
        }
    }

    for (solved) |s| {
        std.log.info("{s}", .{s});
    }

    return .{ part_1, part_2 };
}
