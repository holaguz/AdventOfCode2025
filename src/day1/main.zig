const std = @import("std");
const Allocator = std.mem.Allocator;

const stdin = std.fs.File.stdin();
const stdout = std.fs.File.stdout();

pub fn readFile(allocator: Allocator, file: std.fs.File) !std.ArrayList([]const u8) {
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

pub fn solve(input: [][]const u8) ![2]usize {
    var current_position: i32 = 50;
    var part1: usize = 0;
    var part2: usize = 0;

    for (input) |l| {
        const count: i32 = blk: {
            const num = try std.fmt.parseInt(i32, l[1..], 10);
            break :blk if (l[0] == 'L') -num else num;
        };

        var next_position = current_position;

        for (0..@abs(count)) |_| {
            next_position += std.math.sign(count);
            if (0 == @mod(next_position, 100)) {
                part2 += 1;
            }
        }

        current_position = @mod(current_position + count, 100);
        if (current_position == 0) {
            part1 += 1;
        }
    }

    return .{ part1, part2 };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa.allocator();
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.skip();

    const file = if (args.next()) |filepath| blk: {
        std.log.debug("Opening file {s}", .{filepath});
        break :blk try std.fs.cwd().openFile(filepath, .{});
    } else stdin;

    var lines = try readFile(allocator, file);
    defer lines.deinit(allocator);
    std.log.debug("Parsed {} lines", .{lines.items.len});

    const part1, const part2 = try solve(lines.items);

    var stdout_writer = stdout.writer(&.{});
    try stdout_writer.interface.print("Part 1: {}\nPart 2: {}\n", .{ part1, part2 });
}
