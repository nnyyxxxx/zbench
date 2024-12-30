const std = @import("std");
const BenchmarkResult = @import("../benchmark/types.zig").BenchmarkResult;

pub const DatFormat = struct {
    path: []const u8,

    pub fn init(path: []const u8) DatFormat {
        return .{ .path = path };
    }

    pub fn write(self: DatFormat, results: []const BenchmarkResult) !void {
        const file = try std.fs.cwd().createFile(self.path, .{});
        defer file.close();

        const writer = file.writer();

        for (results) |result| {
            try writer.print("{s} ", .{result.name});
        }
        try writer.writeByte('\n');

        const max_samples = blk: {
            var max: usize = 0;
            for (results) |result| {
                max = @max(max, result.samples.len);
            }
            break :blk max;
        };

        for (0..max_samples) |i| {
            for (results) |result| {
                if (i < result.samples.len) {
                    try writer.print("{} ", .{result.samples[i]});
                } else {
                    try writer.writeAll("_ ");
                }
            }
            try writer.writeByte('\n');
        }
    }
};
