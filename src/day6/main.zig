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

const Input = struct {
    operators: [][]usize,
    operations: []u8,
};

fn parseInput(input: [][]const u8) !Input {
    const num_operators = input.len - 1;
    const num_operations: usize = blk: {
        var it = std.mem.splitScalar(u8, input[0], ' ');
        var count: usize = 0;
        while (it.next()) |token| {
            if (token.len > 0) count += 1;
        }
        break :blk count;
    };

    var operators = try allocator.alloc([]usize, num_operations);
    for (operators) |*op| op.* = try allocator.alloc(usize, num_operators);

    var operations = try allocator.alloc(u8, num_operations);

    for (input[0 .. input.len - 1], 0..) |line, row_idx| {
        var it = std.mem.splitScalar(u8, line, ' ');
        var col_idx: usize = 0;
        while (it.next()) |num_str| {
            if (num_str.len == 0) continue;
            const num = try std.fmt.parseInt(usize, num_str, 10);
            operators[col_idx][row_idx] = num;
            col_idx += 1;
        }
    }

    var operations_it = std.mem.splitScalar(u8, input[input.len - 1], ' ');
    var ix: usize = 0;
    while (operations_it.next()) |op| {
        if (op.len == 0) continue;
        operations[ix] = op[0];
        ix += 1;
    }

    return .{ .operators = operators, .operations = operations };
}

fn numDigits(x: usize) usize {
    var num = x;
    var digits: usize = 0;
    while (num != 0) {
        num /= 10;
        digits += 1;
    }

    return digits;
}

fn solve(input: [][]const u8) ![2]usize {
    const parsed = try parseInput(input);
    const operations = parsed.operations;
    const operators = parsed.operators;

    var part_1: usize = 0;
    var part_2: usize = 0;

    for (0..operations.len) |i| {
        var result: usize = if (operations[i] == '+') 0 else 1;
        const operation = operations[i];
        for (operators[i]) |operator| {
            switch (operation) {
                '+' => result += operator,
                '*' => result *= operator,
                else => unreachable,
            }
        }

        part_1 += result;
    }

    // Part 2
    for (operators, operations) |operator, operation| {
        std.log.info("\n", .{});
        const reversed = try allocator.alloc([]?usize, operator.len);
        for (operator, 0..) |op, row_idx| {
            reversed[row_idx] = try allocator.alloc(?usize, 4);
            @memset(reversed[row_idx], null);
            var num = op;
            var k: usize = 0;
            while (num != 0) : (k += 1) {
                reversed[row_idx][k] = num % 10;
                num /= 10;
            }
            std.log.info("{any} -> {any}", .{ op, reversed[row_idx] });
        }
        var final: [4]usize = [_]usize{0} ** 4;
        for (0..4) |pos| {
            for (0..reversed.len) |rev_ix| {
                const maybe_digit = reversed[rev_ix][pos];
                if (maybe_digit) |num| {
                    final[pos] *= 10;
                    final[pos] += num;
                }
            }
        }
        std.log.info("{any}", .{final});

        var result: usize = if (operation == '+') 0 else 1;
        for (final) |num| {
            if (num == 0) continue;
            switch (operation) {
                '+' => result += num,
                '*' => result *= num,
                else => unreachable,
            }

        }
            std.log.info("result={}", .{result});
            part_2 += result;
    }

    return .{ part_1, part_2 };
}

test "digits" {
    try std.testing.expectEqual(1, numDigits(1));
    try std.testing.expectEqual(2, numDigits(10));
    try std.testing.expectEqual(3, numDigits(234));
}
