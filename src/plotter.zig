const std = @import("std");
const cli = @import("cli.zig");
const bode = @import("plots/bode.zig");
const ampl = @import("plots/amplitude.zig");

pub fn runGnuplot(allocator: std.mem.Allocator, opts: cli.Options) !void {
    const gp_file = try std.fs.cwd().createFile(opts.gp_path, .{});
    defer gp_file.close();

    var gp_buf: [2048]u8 = undefined;
    var gp_writer = gp_file.writer(&gp_buf);

    switch (opts.plot_type) {
        .bode => try bode.writeScript(&gp_writer, opts),
        .amplitude => try ampl.writeScript(&gp_writer, opts),
    }
    try gp_writer.interface.flush();

    std.debug.print("Running gnuplot [{s}{s}, {s}] -> {s}\n", .{
        @tagName(opts.plot_type),
        if (opts.ieee) ", IEEE" else "",
        @tagName(opts.format),
        opts.output_path,
    });

    var child = std.process.Child.init(
        &[_][]const u8{ "gnuplot", opts.gp_path },
        allocator,
    );
    const term = try child.spawnAndWait();
    switch (term) {
        .Exited => |code| {
            if (code == 0) {
                std.debug.print("Done! Saved to {s}\n", .{opts.output_path});
            } else {
                std.debug.print("gnuplot exited with code {d}\n", .{code});
            }
        },
        else => std.debug.print("gnuplot terminated unexpectedly\n", .{}),
    }
}
