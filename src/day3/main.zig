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

fn parse_input(lines: [][]const u8) ![][]u8 {
    var banks = try allocator.alloc([]u8, lines.len);

    for (lines, 0..) |line, i| {
        banks[i] = try allocator.alloc(u8, line.len);
        for (line, 0..) |c, j| {
            banks[i][j] = c - '0';
        }
    }
    return banks;
}

fn solve_line(input: []const u8, count: usize) usize {
    var left: usize = count;
    var start_pos: usize = 0;
    var joltage: usize = 0;

    while (left > 0) : (left -= 1) {
        var end_pos = input.len;
        var selected = false;

        while (!selected) {
            const max = std.mem.max(u8, input[start_pos..end_pos]);
            const pos_of_max = std.mem.indexOfMax(u8, input[start_pos..end_pos]);
            const absolute_pos = start_pos + pos_of_max;

            if (input.len - absolute_pos < left) {
                end_pos -= 1;
            } else {
                start_pos += pos_of_max + 1;
                joltage = 10 * joltage + max;
                selected = true;
            }
        }
    }

    return joltage;
}

fn solve(input: [][]const u8) ![2]usize {
    const banks = try parse_input(input);

    var part_1: usize = 0;
    var part_2: usize = 0;

    for (banks) |bank| {
        part_1 += solve_line(bank, 2);
        part_2 += solve_line(bank, 12);
    }

    return .{ part_1, part_2 };
}
