const std = @import("std");
const BenchmarkResult = @import("../benchmark/types.zig").BenchmarkResult;

pub const Format = struct {
    formatFn: *const fn (*const Format, []const BenchmarkResult, std.fs.File.Writer) anyerror!void,

    pub fn format(self: *const Format, results: []const BenchmarkResult, writer: std.fs.File.Writer) !void {
        try self.formatFn(self, results, writer);
    }
};
