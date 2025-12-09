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

const Point = struct {
    coord: [3]usize,
    gid: ?usize,

    pub fn dist(self: *const Point, other: *const Point) f64 {
        var sum_squared: usize = 0;
        inline for (0..3) |i| {
            const delta = if (self.coord[i] > other.coord[i]) self.coord[i] - other.coord[i] else other.coord[i] - self.coord[i];
            sum_squared += delta * delta;
        }

        const sum_squared_f64: f64 = @floatFromInt(sum_squared);
        return @sqrt(sum_squared_f64);
    }

    pub fn sortGid(_: void, a: Point, b: Point) bool {
        if (a.gid == null) return false;
        if (b.gid == null) return true;
        return a.gid.? > b.gid.?;
    }
};

fn parseInput(input: [][]u8) ![]Point {
    const points = try allocator.alloc(Point, input.len);
    for (input, points) |line, *p| {
        p.gid = null;

        var it = std.mem.splitScalar(u8, line, ',');
        inline for (0..p.coord.len) |i| {
            p.coord[i] = try std.fmt.parseInt(usize, it.next().?, 10);
        }
    }

    return points;
}

fn solve(input: [][]u8) ![2]usize {
    var part_1: usize = 1;
    var part_2: usize = 0;
    const points = try parseInput(input);
    const num_edges = (points.len * (points.len - 1)) / 2;
    const Edge = struct {
        a: usize,
        b: usize,
        d: f64,
        pub fn sortDesc(_: void, a: @This(), b: @This()) bool {
            return a.d < b.d;
        }
    };
    const edges = try allocator.alloc(Edge, num_edges);
    var ix: usize = 0;
    for (0..points.len) |i| {
        for (i + 1..points.len) |j| {
            const d = points[i].dist(&points[j]);
            edges[ix] = .{ .a = i, .b = j, .d = d };
            ix += 1;
        }
    }
    std.mem.sort(Edge, edges, {}, Edge.sortDesc);

    var next_gid: usize = 0;
    const ub: usize = if (input.len <= 20) 10 else 1000;
    for (0..ub) |i| {
        const e = edges[i];
        const a = &points[e.a];
        const b = &points[e.b];
        if (a.gid == null and b.gid == null) {
            a.gid = next_gid;
            b.gid = next_gid;
            next_gid += 1;
        } else if (a.gid == null) {
            a.gid = b.gid;
        } else if (b.gid == null) {
            b.gid = a.gid;
        } else {
            const old_gid = a.gid.?;
            const new_gid = b.gid.?;
            for (points) |*p| {
                if (p.gid == old_gid) p.gid = new_gid;
            }
        }
    }

    var gid_count = std.AutoArrayHashMap(usize, usize).init(allocator);
    defer gid_count.deinit();
    for (points) |p| {
        if (p.gid) |gid| {
            const gop = try gid_count.getOrPut(gid);
            if (gop.found_existing) gop.value_ptr.* += 1 else gop.value_ptr.* = 1;
        }
    }

    std.mem.sort(usize, gid_count.values(), {}, std.sort.desc(usize));
    part_1 = 1;
    for (gid_count.values()[0..3]) |v| {
        part_1 *= v;
    }


    // Part 2
    for (ub..edges.len) |i| {
        const e = edges[i];
        const a = &points[e.a];
        const b = &points[e.b];
        if (a.gid != null and a.gid == b.gid) continue;
        if (a.gid == null and b.gid == null) {
            a.gid = next_gid;
            b.gid = next_gid;
            next_gid += 1;
        } else if (a.gid == null) {
            a.gid = b.gid;
        } else if (b.gid == null) {
            b.gid = a.gid;
        } else {
            const old_gid = a.gid.?;
            const new_gid = b.gid.?;
            for (points) |*p| {
                if (p.gid == old_gid) p.gid = new_gid;
            }
        }

        const first_gid = points[0].gid orelse continue;
        var all_same = true;
        for (points[1..]) |p| {
            if (p.gid != first_gid) {
                all_same = false;
                break;
            }
        }
        if (all_same) {
            part_2 = a.coord[0] * b.coord[0];
            break;
        }
    }

    return .{ part_1, part_2 };
}
