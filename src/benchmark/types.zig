const std = @import("std");

pub const Error = error{
    Empty,
    InvalidBenchmark,
    IoError,
};

pub const BenchmarkType = enum {
    cursor_motion,
    dense_cells,
    light_cells,
    medium_cells,
    scrolling,
};

pub const BenchmarkResult = struct {
    name: []const u8,
    bench_size: usize,
    samples: []usize,
    sorted_samples: []usize,

    pub fn init(allocator: std.mem.Allocator, name: []const u8, bench_size: usize, samples: []usize) !BenchmarkResult {
        const duped_samples = try allocator.dupe(usize, samples);
        const sorted = try allocator.dupe(usize, samples);
        std.sort.heap(usize, sorted, {}, std.sort.asc(usize));

        return .{
            .name = name,
            .bench_size = bench_size,
            .samples = duped_samples,
            .sorted_samples = sorted,
        };
    }

    pub fn deinit(self: *BenchmarkResult, allocator: std.mem.Allocator) void {
        allocator.free(self.samples);
        allocator.free(self.sorted_samples);
    }

    pub fn mean(self: BenchmarkResult) f64 {
        var sum: usize = 0;
        for (self.samples) |sample| {
            sum += sample;
        }
        return @as(f64, @floatFromInt(sum)) / @as(f64, @floatFromInt(self.samples.len));
    }

    pub fn median(self: BenchmarkResult) f64 {
        const len = self.sorted_samples.len;
        const mid = len / 2;
        if (len % 2 == 0) {
            return (@as(f64, @floatFromInt(self.sorted_samples[mid - 1])) +
                @as(f64, @floatFromInt(self.sorted_samples[mid]))) / 2.0;
        }
        return @as(f64, @floatFromInt(self.sorted_samples[mid]));
    }

    pub fn percentile(self: BenchmarkResult, pct: usize) usize {
        const idx = (self.samples.len * pct + 99) / 100;
        return self.sorted_samples[@min(idx, self.sorted_samples.len - 1)];
    }

    pub fn variance(self: BenchmarkResult) f64 {
        if (self.samples.len < 2) return 0;

        const mean_val = self.mean();
        var sum: f64 = 0;

        for (self.samples) |sample| {
            const diff = @as(f64, @floatFromInt(sample)) - mean_val;
            sum += diff * diff;
        }

        return sum / @as(f64, @floatFromInt(self.samples.len - 1));
    }

    pub fn stddev(self: BenchmarkResult) f64 {
        return @sqrt(self.variance());
    }
};

pub const BenchmarkError = error{
    Empty,
    InvalidSize,
    IoError,
    SystemError,
};

test "benchmark statistics" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const samples = [_]usize{ 4, 8, 8, 8, 10, 10 };
    var result = try BenchmarkResult.init(allocator, "test", 100, try allocator.dupe(usize, &samples));
    defer result.deinit(allocator);

    try testing.expectApproxEqAbs(result.variance(), 4.8, 0.0001);
    try testing.expectApproxEqAbs(result.stddev(), 2.1908902300206643, 0.0001);
    try testing.expectEqual(result.percentile(90), 10);
}
