const std = @import("std");
const types = @import("types.zig");

pub const BenchmarkLoader = struct {
    allocator: std.mem.Allocator,
    name: []const u8,
    bench_type: types.BenchmarkType,

    pub fn init(allocator: std.mem.Allocator, name: []const u8, bench_type: types.BenchmarkType) BenchmarkLoader {
        return .{
            .allocator = allocator,
            .name = name,
            .bench_type = bench_type,
        };
    }

    pub fn findBenchmarks(allocator: std.mem.Allocator) !std.ArrayList(BenchmarkLoader) {
        var benchmarks = std.ArrayList(BenchmarkLoader).init(allocator);

        inline for (@typeInfo(types.BenchmarkType).Enum.fields) |field| {
            try benchmarks.append(BenchmarkLoader.init(allocator, field.name, @enumFromInt(field.value)));
        }

        return benchmarks;
    }

    pub fn load(self: *const BenchmarkLoader) !types.BenchmarkResult {
        const term_size = try getTerminalSize();
        const buffer_size = term_size.rows * term_size.cols * 20;
        const buffer = try self.allocator.alloc(u8, buffer_size);
        defer self.allocator.free(buffer);

        return types.BenchmarkResult.init(self.allocator, self.name, buffer_size, &[_]usize{});
    }
};

const TermSize = struct {
    rows: u16,
    cols: u16,
};

fn getTerminalSize() !TermSize {
    if (@import("builtin").os.tag == .windows) {
        return .{ .rows = 24, .cols = 80 };
    } else {
        var winsize: std.os.system.winsize = undefined;
        const fd = std.os.STDOUT_FILENO;
        const err = std.os.system.ioctl(fd, std.os.system.T.IOCGWINSZ, @intFromPtr(&winsize));
        if (err != 0) return error.IoctlError;
        return .{
            .rows = winsize.ws_row,
            .cols = winsize.ws_col,
        };
    }
}
