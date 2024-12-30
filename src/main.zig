const std = @import("std");
const Runner = @import("benchmark/runner.zig").Runner;
const BenchmarkType = @import("benchmark/types.zig").BenchmarkType;
const BenchmarkResult = @import("benchmark/types.zig").BenchmarkResult;
const StdoutFormat = @import("output/stdout.zig").StdoutFormat;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var runner = Runner.init(allocator);

    var results = std.ArrayList(BenchmarkResult).init(allocator);
    defer {
        for (results.items) |*result| {
            result.deinit(allocator);
        }
        results.deinit();
    }

    const benchmarks = [_]BenchmarkType{
        .cursor_motion,
        .dense_cells,
        .light_cells,
        .medium_cells,
        .scrolling,
        .unicode,
        .fullscreen_scroll,
    };

    for (benchmarks) |bench_type| {
        const result = try runner.run(bench_type);
        try results.append(result);
    }

    const stdout = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout);
    const writer = bw.writer();

    try StdoutFormat.format(results.items, writer);
    try bw.flush();
}
