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
                .unicode => try self.runUnicode(writer),
                .fullscreen_scroll => try self.runFullscreenScroll(writer),
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
                .unicode => try self.runUnicode(writer),
                .fullscreen_scroll => try self.runFullscreenScroll(writer),
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

    fn runUnicode(_: *Runner, writer: anytype) !void {
        const size = try getTermSize();
        const symbols = [_][]const u8{
            "你好",     "世界",     "안녕",     "こんにちは", "สวัสดี",
            "🌍",       "🌎",       "🌏",       "⭐",             "🚀",
            "♔",        "♕",        "♖",        "♗",             "♘",
            "∀",        "∃",        "∈",        "∉",             "∋",
            "𓀀",       "𓀁",       "𓀂",       "𓀃",            "𓀄",
            "☀",        "☁",        "☂",        "☃",             "☄",
            "⚀",        "⚁",        "⚂",        "⚃",             "⚄",
            "⛅",        "⛆",        "⛇",        "⛈",             "⛉",
            "❄",        "❅",        "❆",        "❇",             "❈",
            "⚔",        "⚕",        "⚖",        "⚗",             "⚘",
            "◰",        "◱",        "◲",        "◳",             "◴",
            "✠",        "✡",        "✢",        "✣",             "✤",
            "⛩",        "⛪",        "⛫",        "⛬",             "⛭",
            "😀",       "😁",       "😂",       "😃",            "😄",
            "😅",       "😆",       "😇",       "😈",            "😉",
            "🙈",       "🙉",       "🙊",       "🙋",            "🙌",
            "😎",       "😏",       "😐",       "😑",            "😒",
            "🙁",       "🙂",       "🙃",       "🙄",            "🙅",
            "😺",       "😸",       "😹",       "😻",            "😼",
            "ĀāĂăĄ", "ąĆćĈĉ", "ĊċČčĎ", "ďĐđĒē",      "ĔĕĖė",
            "ĘęĚěĜ", "ĝĞğĠġ", "ĢģĤĥĦ", "ħĨĩĪī",      "ĬĭĮį",
            "ƀƁƂƃƄ", "ƅƆƇƈƉ", "ƊƋƌƍƎ", "ƏƐƑƒƓ",      "ƔƕƖƗ",
            "ʰʱʲʳʴ", "ʵʶʷʸʹ", "ʺʻʼʽʾ", "ʿˀˁ˂˃",      "˄˅ˆˇˈ",
            "한글",     "테스트",  "하나둘",  "삼사오",       "육칠팔",
            "가나다",  "라마바",  "사아자",  "차카타",       "파하",
            "햇빛",     "달빛",     "별빛",     "구름",          "바람",
            "하늘",     "바다",     "땅과",     "산과",          "들판",
        };

        for (symbols) |symbol| {
            for (0..size.rows) |row| {
                for (0..size.cols) |_| {
                    try writer.writeAll(symbol);
                }
                if (row < size.rows - 1) try writer.writeByte('\n');
            }
            try writer.writeAll("\x1b[H");
        }
    }

    fn runFullscreenScroll(self: *Runner, writer: anytype) !void {
        const size = try getTermSize();
        const line = try self.allocator.alloc(u8, size.cols);
        defer self.allocator.free(line);
        @memset(line, 'A');

        const iterations = size.rows * 100;
        var i: usize = 0;
        while (i < iterations) : (i += 1) {
            try writer.writeAll(line);
            try writer.writeByte('\n');
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
