const std = @import("std");
const types = @import("types.zig");
const BenchmarkResult = types.BenchmarkResult;
const BenchmarkType = types.BenchmarkType;
const Error = types.Error;

pub const Runner = struct {
    allocator: std.mem.Allocator,
    config: struct {
        warmup: usize,
        max_secs: u64,
        max_samples: ?usize,
        min_bytes: usize,
    },

    pub fn init(allocator: std.mem.Allocator, warmup: usize, max_secs: u64, max_samples: ?usize, min_bytes: usize) Runner {
        return .{
            .allocator = allocator,
            .config = .{
                .warmup = warmup,
                .max_secs = max_secs,
                .max_samples = max_samples,
                .min_bytes = min_bytes,
            },
        };
    }

    pub fn run(self: *Runner, bench_type: BenchmarkType) !BenchmarkResult {
        var samples = std.ArrayList(usize).init(self.allocator);
        defer samples.deinit();

        const stdout = std.io.getStdOut();
        var bw = std.io.bufferedWriter(stdout.writer());
        const writer = bw.writer();

        try writer.writeAll("\x1b[0m\x1b[2J\x1b[3J\x1b[1;1H");
        try writer.context.flush();

        for (0..self.config.warmup) |_| {
            try writer.writeAll("\x1b[0m\x1b[2J\x1b[3J\x1b[1;1H");
            switch (bench_type) {
                .cursor_motion => try self.runCursorMotion(writer),
                .dense_cells => try self.runDenseCells(writer),
                .light_cells => try self.runLightCells(writer),
                .medium_cells => try self.runMediumCells(writer),
                .scrolling => try self.runScrolling(writer),
                .frame_rate => try self.runFrameRate(writer),
                .latency => try self.runLatency(writer, &samples),
            }
            try writer.context.flush();
        }

        const max_samples = self.config.max_samples orelse std.math.maxInt(usize);
        const max_time_ns = self.config.max_secs * std.time.ns_per_s;
        var total_time: u64 = 0;

        while (samples.items.len < max_samples and total_time < max_time_ns) {
            try writer.writeAll("\x1b[0m\x1b[2J\x1b[3J\x1b[1;1H");
            var timer = try std.time.Timer.start();

            switch (bench_type) {
                .cursor_motion => try self.runCursorMotion(writer),
                .dense_cells => try self.runDenseCells(writer),
                .light_cells => try self.runLightCells(writer),
                .medium_cells => try self.runMediumCells(writer),
                .scrolling => try self.runScrolling(writer),
                .frame_rate => try self.runFrameRate(writer),
                .latency => try self.runLatency(writer, &samples),
            }
            try writer.context.flush();

            const elapsed = timer.read();
            try samples.append(@intCast(elapsed / std.time.ns_per_ms));
            total_time += elapsed;
        }

        try writer.writeAll("\x1b[0m\x1b[2J\x1b[3J\x1b[1;1H");
        try writer.context.flush();

        return BenchmarkResult.init(
            self.allocator,
            @tagName(bench_type),
            self.config.min_bytes,
            samples.items,
        );
    }

    fn runCursorMotion(_: *Runner, writer: anytype) !void {
        const size = try getTermSize();
        for (0..size.rows) |row| {
            for (0..size.cols) |col| {
                try writer.print("\x1b[{};{}H#", .{ row + 1, col + 1 });
            }
        }
    }

    fn runDenseCells(_: *Runner, writer: anytype) !void {
        const size = try getTermSize();
        var offset: usize = 0;

        for ("ABCDEFGHIJKLMNOPQRSTUVWXYZ") |char| {
            try writer.print("\x1b[H", .{});
            for (0..size.rows) |row| {
                for (0..size.cols) |col| {
                    const index = row + col + offset;
                    const fg = @mod(index, 156) + 100;
                    const bg = 255 - @mod(index, 156) + 100;
                    try writer.print("\x1b[38;5;{};48;5;{};1;3;4m{c}", .{ fg, bg, char });
                }
            }
            offset += 1;
        }
    }

    fn runLightCells(_: *Runner, writer: anytype) !void {
        const size = try getTermSize();

        for ("ABCDEFGHIJKLMNOPQRSTUVWXYZ") |char| {
            try writer.print("\x1b[H", .{});
            for (0..size.rows * size.cols) |_| {
                try writer.writeByte(char);
            }
        }
    }

    fn runMediumCells(_: *Runner, writer: anytype) !void {
        const size = try getTermSize();

        for ("ABCDEFGHIJKLMNOPQRSTUVWXYZ") |char| {
            for (0..size.rows) |row| {
                for (0..size.cols) |col| {
                    const color = @mod(row + col, 256);
                    try writer.print("\x1b[38;5;{}m{c}", .{ color, char });
                }
                try writer.writeByte('\n');
            }
        }
    }

    fn runScrolling(_: *Runner, writer: anytype) !void {
        for (0..100_000) |_| {
            try writer.writeAll("y\n");
        }
    }

    const FrameData = struct {
        timestamp: u64,
        frame_count: usize,
    };

    fn runFrameRate(_: *Runner, writer: anytype) !void {
        var frame_count: usize = 0;
        const target_frames = 60;
        const frame_duration = std.time.ns_per_s / target_frames;

        while (frame_count < 600) : (frame_count += 1) {
            const frame_start = try std.time.Instant.now();

            try writer.writeAll("\x1b[2J\x1b[H");
            try writer.print("Frame: {}", .{frame_count});
            try writer.context.flush();

            const elapsed = (try std.time.Instant.now()).since(frame_start);
            if (elapsed < frame_duration) {
                std.time.sleep(frame_duration - elapsed);
            }
        }
    }

    fn runLatency(_: *Runner, writer: anytype, samples: *std.ArrayList(usize)) !void {
        var prng = std.rand.DefaultPrng.init(@intCast(std.time.timestamp()));
        const random = prng.random();

        const stdin = std.io.getStdIn();
        var termios: std.os.linux.termios = undefined;
        const TCGETS = 0x5401;
        const TCSETS = 0x5402;

        const rc = std.os.linux.syscall3(.ioctl, @as(usize, @intCast(stdin.handle)), TCGETS, @intFromPtr(&termios));
        if (rc != 0) return error.IoctlError;

        const old_termios = termios;
        termios.lflag.ECHO = false;
        termios.lflag.ICANON = false;

        const set_rc = std.os.linux.syscall3(.ioctl, @as(usize, @intCast(stdin.handle)), TCSETS, @intFromPtr(&termios));
        if (set_rc != 0) return error.IoctlError;
        defer {
            _ = std.os.linux.syscall3(.ioctl, @as(usize, @intCast(stdin.handle)), TCSETS, @intFromPtr(&old_termios));
        }

        for (0..100) |_| {
            const x = random.intRangeAtMost(usize, 1, 80);
            const y = random.intRangeAtMost(usize, 1, 24);

            var timer = try std.time.Timer.start();
            try writer.print("\x1b[{};{}H#\x1b[6n", .{ y, x });
            try writer.context.flush();

            const timeout_ns = 1 * std.time.ns_per_s;
            const start = timer.read();
            var response_complete = false;

            while (!response_complete) {
                const byte = stdin.reader().readByte() catch break;
                if (byte == '\x1b') {
                    const next_byte = stdin.reader().readByte() catch break;
                    if (next_byte == '[') {
                        while (true) {
                            const resp_byte = stdin.reader().readByte() catch break;
                            if (resp_byte == 'R') {
                                response_complete = true;
                                break;
                            }
                            if (timer.read() - start > timeout_ns) break;
                        }
                    }
                }
                if (timer.read() - start > timeout_ns) break;
            }

            if (response_complete) {
                const elapsed = timer.read() - start;
                try samples.append(@intCast(elapsed / std.time.ns_per_ms));
            }

            std.time.sleep(50 * std.time.ns_per_ms);
        }
    }
};

const TermSize = struct {
    rows: usize,
    cols: usize,
};

fn getTermSize() !TermSize {
    if (@import("builtin").os.tag == .windows) {
        return .{ .rows = 24, .cols = 80 };
    }
    var winsize: std.os.linux.winsize = undefined;
    const fd = std.os.linux.STDOUT_FILENO;
    const TIOCGWINSZ = 0x5413;
    const err = std.os.linux.syscall3(.ioctl, @as(usize, @intCast(fd)), TIOCGWINSZ, @intFromPtr(&winsize));
    if (err != 0) return error.IoctlError;
    return .{
        .rows = @intCast(winsize.ws_row),
        .cols = @intCast(winsize.ws_col),
    };
}
