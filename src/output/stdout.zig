const std = @import("std");
const BenchmarkResult = @import("../benchmark/types.zig").BenchmarkResult;

pub const StdoutFormat = struct {
    pub fn format(results: []const BenchmarkResult, writer: anytype) !void {
        try writer.writeAll("Results:\n");
        for (results) |result| {
            try writer.writeAll("\n");

            const size_mib = @as(f64, @floatFromInt(result.bench_size)) / 1048576.0;
            try writer.print("  {s} ({} samples @ {d:.2} MiB):\n", .{
                result.name,
                result.samples.len,
                size_mib,
            });

            try writer.print("    {d:.2}ms avg (90% < {}ms) +-{d:.2}ms\n", .{
                result.mean(),
                result.percentile(90),
                result.stddev(),
            });
        }
    }
};
