const std = @import("std");
const Runner = @import("benchmark/runner.zig").Runner;
const BenchmarkType = @import("benchmark/types.zig").BenchmarkType;
const BenchmarkResult = @import("benchmark/types.zig").BenchmarkResult;
const StdoutFormat = @import("output/stdout.zig").StdoutFormat;

fn printEpilepsyWarning(writer: anytype) !void {
    try writer.writeAll("\n");
    try writer.writeAll("⚠️  WARNING - PHOTOSENSITIVITY/EPILEPSY SEIZURE WARNING ⚠️\n");
    try writer.writeAll("\n");
    try writer.writeAll("This benchmark contains flashing lights and rapidly changing colors\n");
    try writer.writeAll("that may trigger seizures in people with photosensitive epilepsy.\n");
    try writer.writeAll("\n");
    try writer.writeAll("Do you want to continue? [y/N]: ");
}

fn getUserConfirmation(reader: anytype) !bool {
    var buf: [2]u8 = undefined;
    if (try reader.readUntilDelimiterOrEof(&buf, '\n')) |user_input| {
        return user_input.len == 1 and (user_input[0] == 'y' or user_input[0] == 'Y');
    }
    return false;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const stdout_file = std.io.getStdOut();
    const stdin_file = std.io.getStdIn();

    var bw = std.io.bufferedWriter(stdout_file.writer());
    const stdout = bw.writer();
    const stdin = stdin_file.reader();

    try printEpilepsyWarning(stdout);
    try bw.flush();

    if (!try getUserConfirmation(stdin)) {
        try stdout.writeAll("\nBenchmark cancelled.\n");
        try bw.flush();
        return;
    }

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

    try StdoutFormat.format(results.items, stdout);
    try bw.flush();
}
