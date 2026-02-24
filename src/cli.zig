const std = @import("std");

pub const PlotType = enum {
    bode,
    amplitude,
};

pub const OutputFormat = enum {
    png,
    pdf,
};

pub const Options = struct {
    input_path: []const u8,
    output_path: []const u8 = "bode_plot.png",
    dat_path: []const u8 = "plot_data.dat",
    gp_path: []const u8 = "plot.gp",
    plot_type: PlotType = .bode,
    format: OutputFormat = .png,
    ieee: bool = false,
    title: []const u8 = "",
    width: u32 = 0,
    height: u32 = 0,
};

pub fn printHelp() void {
    std.debug.print(
        \\Usage: LtSpicePlotter [options] <input_file>
        \\
        \\Options:
        \\  --plot <type>       Plot type: bode (default), amplitude
        \\  --format <fmt>      Output format: png (default), pdf
        \\  --ieee              IEEE-compliant style (monochrome, Times New Roman)
        \\  --title <text>      Override plot title
        \\  --output <file>     Output filename (default: bode_plot.png / bode_plot.pdf)
        \\  --size <WxH>        Output size, e.g. --size 1200x800
        \\  --help              Show this help
        \\
        \\Examples:
        \\  LtSpicePlotter SpiceData/Filter_UA.txt
        \\  LtSpicePlotter --format pdf --ieee SpiceData/Filter_UA.txt
        \\  LtSpicePlotter --plot amplitude --title "My Filter" SpiceData/Filter_UA.txt
        \\  LtSpicePlotter --format pdf --output fig1.pdf --size 1000x750 SpiceData/Filter_UA.txt
        \\
    , .{});
}

pub fn parse(allocator: std.mem.Allocator) !Options {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var opts = Options{ .input_path = "" };
    var found_input = false;
    var i: usize = 1;

    while (i < args.len) : (i += 1) {
        const arg = args[i];

        if (std.mem.eql(u8, arg, "--help")) {
            printHelp();
            std.process.exit(0);
        } else if (std.mem.eql(u8, arg, "--ieee")) {
            opts.ieee = true;
        } else if (std.mem.eql(u8, arg, "--plot")) {
            i += 1;
            if (i >= args.len) {
                std.debug.print("error: --plot requires a value (bode, amplitude)\n", .{});
                std.process.exit(1);
            }
            const val = args[i];
            if (std.mem.eql(u8, val, "bode")) {
                opts.plot_type = .bode;
            } else if (std.mem.eql(u8, val, "amplitude")) {
                opts.plot_type = .amplitude;
            } else {
                std.debug.print("error: unknown plot type '{s}'\n", .{val});
                std.process.exit(1);
            }
        } else if (std.mem.eql(u8, arg, "--format")) {
            i += 1;
            if (i >= args.len) {
                std.debug.print("error: --format requires a value (png, pdf)\n", .{});
                std.process.exit(1);
            }
            const val = args[i];
            if (std.mem.eql(u8, val, "png")) {
                opts.format = .png;
            } else if (std.mem.eql(u8, val, "pdf")) {
                opts.format = .pdf;
            } else {
                std.debug.print("error: unknown format '{s}'\n", .{val});
                std.process.exit(1);
            }
        } else if (std.mem.eql(u8, arg, "--title")) {
            i += 1;
            if (i >= args.len) {
                std.debug.print("error: --title requires a value\n", .{});
                std.process.exit(1);
            }
            opts.title = try allocator.dupe(u8, args[i]);
        } else if (std.mem.eql(u8, arg, "--output")) {
            i += 1;
            if (i >= args.len) {
                std.debug.print("error: --output requires a filename\n", .{});
                std.process.exit(1);
            }
            opts.output_path = try allocator.dupe(u8, args[i]);
        } else if (std.mem.eql(u8, arg, "--size")) {
            i += 1;
            if (i >= args.len) {
                std.debug.print("error: --size requires WxH (e.g. 1200x800)\n", .{});
                std.process.exit(1);
            }
            const val = args[i];
            var parts = std.mem.splitScalar(u8, val, 'x');
            const w_str = parts.next() orelse "0";
            const h_str = parts.next() orelse "0";
            opts.width = std.fmt.parseInt(u32, w_str, 10) catch 0;
            opts.height = std.fmt.parseInt(u32, h_str, 10) catch 0;
        } else {
            opts.input_path = try allocator.dupe(u8, arg);
            found_input = true;
        }
    }

    if (!found_input) {
        printHelp();
        std.process.exit(1);
    }

    // Auto-set output extension if user didn't provide --output
    if (std.mem.eql(u8, opts.output_path, "bode_plot.png") and opts.format == .pdf) {
        opts.output_path = "bode_plot.pdf";
    }

    return opts;
}
