const std = @import("std");
const cli = @import("../cli.zig");

pub fn writeScript(
    writer: anytype,
    opts: cli.Options,
) !void {
    const title = if (opts.title.len > 0) opts.title else "Amplitude Response";

    const terminal: []const u8 = switch (opts.format) {
        .png => "pngcairo",
        .pdf => "pdfcairo",
    };

    // pdfcairo uses inches, pngcairo uses pixels
    var size_buf: [32]u8 = undefined;
    const size_str: []const u8 = if (opts.format == .pdf) blk: {
        const w_in: f32 = if (opts.width > 0) @as(f32, @floatFromInt(opts.width)) / 100.0 else if (opts.ieee) 7.0 else 8.0;
        const h_in: f32 = if (opts.height > 0) @as(f32, @floatFromInt(opts.height)) / 100.0 else if (opts.ieee) 4.0 else 5.0;
        break :blk try std.fmt.bufPrint(&size_buf, "{d:.2},{d:.2}", .{ w_in, h_in });
    } else blk: {
        const w_px: u32 = if (opts.width > 0) opts.width else if (opts.ieee) 1000 else 1200;
        const h_px: u32 = if (opts.height > 0) opts.height else if (opts.ieee) 500 else 500;
        break :blk try std.fmt.bufPrint(&size_buf, "{d},{d}", .{ w_px, h_px });
    };

    if (opts.ieee) {
        try writer.interface.print(
            \\set terminal {s} size {s} enhanced monochrome font 'Times New Roman,12'
            \\set output '{s}'
            \\
            \\set style line 1 lt 1 lw 1.5 lc rgb "black"
            \\set style line 3 lt 1 lw 0.5 lc rgb "gray" dt 3
            \\
            \\set title "{s}" font 'Times New Roman,13'
            \\set xlabel "Frequency (Hz)" font 'Times New Roman,11'
            \\set ylabel "Amplitude (V)" font 'Times New Roman,11'
            \\set logscale x
            \\set grid ls 3
            \\set key top right box lt -1 font 'Times New Roman,10'
            \\set border lw 1.2
            \\set tics font 'Times New Roman,10'
            \\plot 'plot_data.dat' using 1:4 with lines ls 1 title "Amplitude"
            \\
        , .{ terminal, size_str, opts.output_path, title });
    } else {
        try writer.interface.print(
            \\set terminal {s} size {s} enhanced font 'Arial,12'
            \\set output '{s}'
            \\
            \\set title "{s}"
            \\set xlabel "Frequency [Hz]"
            \\set ylabel "Amplitude [V]"
            \\set logscale x
            \\set grid
            \\set key top right
            \\plot 'plot_data.dat' using 1:4 with lines lw 2 lc rgb "blue" title "Amplitude"
            \\
        , .{ terminal, size_str, opts.output_path, title });
    }
}
