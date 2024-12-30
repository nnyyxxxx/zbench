const std = @import("std");

pub const Config = struct {
    silent: bool,
    min_bytes: usize,
    warmup: usize,
    max_secs: u64,
    max_samples: ?usize,
    dat_path: ?[]const u8,

    pub fn init() Config {
        return .{
            .silent = false,
            .min_bytes = 1048576,
            .warmup = 1,
            .max_secs = 10,
            .max_samples = null,
            .dat_path = null,
        };
    }

    pub fn parse(allocator: std.mem.Allocator) !Config {
        var config = Config.init();
        const args = try std.process.argsAlloc(allocator);
        defer std.process.argsFree(allocator, args);

        var i: usize = 1;
        while (i < args.len) : (i += 1) {
            const arg = args[i];
            if (std.mem.eql(u8, arg, "--silent")) {
                config.silent = true;
            } else if (std.mem.eql(u8, arg, "--min-bytes")) {
                i += 1;
                if (i >= args.len) return error.MissingValue;
                config.min_bytes = try std.fmt.parseInt(usize, args[i], 10);
            } else if (std.mem.eql(u8, arg, "--warmup")) {
                i += 1;
                if (i >= args.len) return error.MissingValue;
                config.warmup = try std.fmt.parseInt(usize, args[i], 10);
            } else if (std.mem.eql(u8, arg, "--max-secs")) {
                i += 1;
                if (i >= args.len) return error.MissingValue;
                config.max_secs = try std.fmt.parseInt(u64, args[i], 10);
            } else if (std.mem.eql(u8, arg, "--max-samples")) {
                i += 1;
                if (i >= args.len) return error.MissingValue;
                config.max_samples = try std.fmt.parseInt(usize, args[i], 10);
            } else if (std.mem.eql(u8, arg, "--dat")) {
                i += 1;
                if (i >= args.len) return error.MissingValue;
                config.dat_path = args[i];
            }
        }

        return config;
    }
};
