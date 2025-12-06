const std = @import("std");
const builtin = @import("builtin");
const Allocator = std.mem.Allocator;

const stdin = std.fs.File.stdin();
const stdout = std.fs.File.stdout();

fn readFile(allocator: Allocator, file: std.fs.File) !std.ArrayList([]const u8) {
    const input = try file.readToEndAlloc(allocator, std.math.maxInt(usize));

    var it = std.mem.splitScalar(u8, input, ',');
    var lines = std.ArrayList([]const u8).empty;

    while (it.next()) |l| {
        if (l.len > 0) {
            try lines.append(allocator, l);
        }
    }

    return lines;
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

    const part1, const part2 = try solve(allocator, lines.items);

    var stdout_writer = stdout.writer(&.{});
    try stdout_writer.interface.print("Part 1: {}\nPart 2: {}\n", .{ part1, part2 });
}

fn parse_ranges(allocator: Allocator, pairs: [][]const u8) ![][2][]const u8 {
    var result = try std.ArrayList([2][]const u8).initCapacity(allocator, pairs.len);

    for (pairs) |pair| {
        var it = std.mem.tokenizeAny(u8, pair, "-");

        const first = it.next().?;
        const second = it.next().?;

        const pp: [2][]const u8 = [2][]const u8{ first, second };

        try result.append(allocator, pp);
    }

    return try result.toOwnedSlice(allocator);
}

fn num_digits(x: u128) usize {
    var exp: usize = 0;
    var num = x;

    while (num != 0) {
        num = @divTrunc(num, 10);
        exp += 1;
    }

    return exp;
}

fn dupe(lhs: u128, rhs: u128) u128 {
    const nd = num_digits(rhs);
    const exp = std.math.pow(u128, 10, nd);

    return lhs * exp + rhs;
}

fn solve(allocator: Allocator, input: [][]const u8) ![2]u128 {
    const ranges = try parse_ranges(allocator, input);
    var part_1: u128 = 0;
    var part_2: u128 = 0;
    part_2 = 0;

    for (ranges) |r| {
        const min = try std.fmt.parseInt(usize, r[0], 10);
        const max = try std.fmt.parseInt(usize, r[1], 10);

        {
            // Part 1
            // Determine the number of digits
            const nd = num_digits(min);

            // If the number has an even number of digits we can take the upper half, if it has an odd number,
            // we take (num_digits-1)/2.
            // const half_nd = if (nd % 2 != 0) @divFloor(nd - 1, 2) else @divFloor(nd, 2);
            // const half_nd = @divFloor(nd, 2);

            // Get the upper half of the start number
            const start = blk: {
                var x = min;

                for (0..@divFloor(nd + 1, 2)) |_| {
                    x /= 10;
                }

                break :blk x;
            };

            var seed = start;

            while (true) {
                const current = dupe(seed, seed);

                if (current > max) {
                    break;
                }

                if (current >= min) {
                    part_1 += current;
                }
                seed += 1;
            }
        }

        {
            // Part 2.
            for (min..max + 1) |n| {
                const nd = num_digits(n);

                for (1..nd / 2 + 1) |pattern_len| {
                    // Check if the number can be split into chunks of pattern_len length
                    if (nd % pattern_len != 0) continue;

                    // Extract the pattern from `n`
                    const pow_lhs = std.math.pow(u64, 10, nd - pattern_len);
                    const pattern = n / pow_lhs;

                    // Divisor to extract the pattern from the number
                    const pattern_exp = std.math.pow(u64, 10, pattern_len);

                    var valid = true;
                    var remaining = n;


                    for (0..nd / pattern_len) |_| {
                        // Extract pattern_len digits
                        const quot = remaining / pattern_exp;
                        const rem = remaining % pattern_exp;

                        if (rem != pattern) {
                            valid = false;
                            break;
                        }

                        remaining = quot;
                    }

                    if (valid) {
                        std.log.debug("Pattern matched: {} == {} ** {}", .{ n, pattern, nd / pattern_len });
                        if(builtin.mode == .Debug) {
                            assert_valid(n, min, max, pattern, nd / pattern_len);
                        }
                        part_2 += n;
                        break;
                    }
                }
            }
        }
    }

    return .{ part_1, part_2 };
}

fn assert_valid(x: u128, min: u128, max: u128, pattern: u128, pattern_times: usize) void {
    if (x < min or x > max) {
        @panic("Not in range");
    }

    const reconstruct = blk: {
        var y: u128 = 0;
        for (0..pattern_times) |_| {
            y *= std.math.pow(u128, 10, num_digits(pattern));
            y += pattern;
        }
        break :blk y;
    };

    if (reconstruct != x) {
        @panic("Invalid");
    }
}

test "get_exponent" {
    try std.testing.expectEqual(0, num_digits(0));
    try std.testing.expectEqual(1, num_digits(1));
    try std.testing.expectEqual(1, num_digits(9));
    try std.testing.expectEqual(2, num_digits(10));
}
