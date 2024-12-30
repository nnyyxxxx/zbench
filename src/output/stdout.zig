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

            if (std.mem.eql(u8, result.name, "frame_rate")) {
                const fps = 1000.0 / result.mean();
                try writer.print("    {d:.2} FPS avg (90% > {d:.2} FPS) +-{d:.2}ms\n", .{
                    fps,
                    1000.0 / @as(f64, @floatFromInt(result.percentile(90))),
                    result.stddev(),
                });
            } else if (std.mem.eql(u8, result.name, "latency")) {
                try writer.print("    {d:.2}ms avg latency (90% < {}ms) +-{d:.2}ms\n", .{
                    result.mean(),
                    result.percentile(90),
                    result.stddev(),
                });
            } else {
                try writer.print("    {d:.2}ms avg (90% < {}ms) +-{d:.2}ms\n", .{
                    result.mean(),
                    result.percentile(90),
                    result.stddev(),
                });
            }
        }
    }
};
