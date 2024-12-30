const std = @import("std");
const Config = @import("config.zig").Config;
const Runner = @import("benchmark/runner.zig").Runner;
const BenchmarkType = @import("benchmark/types.zig").BenchmarkType;
const BenchmarkResult = @import("benchmark/types.zig").BenchmarkResult;
const StdoutFormat = @import("output/stdout.zig").StdoutFormat;
const DatFormat = @import("output/dat.zig").DatFormat;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const config = try Config.parse(allocator);

    var runner = Runner.init(
        allocator,
        config.warmup,
        config.max_secs,
        config.max_samples,
        config.min_bytes,
    );

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
        .frame_rate,
        .latency,
    };

    for (benchmarks) |bench_type| {
        const result = try runner.run(bench_type);
        try results.append(result);
    }

    const stdout = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout);
    const writer = bw.writer();

    if (!config.silent) {
        try StdoutFormat.format(results.items, writer);
    }

    if (config.dat_path) |path| {
        try DatFormat.init(path).write(results.items);
    }

    try bw.flush();
}
