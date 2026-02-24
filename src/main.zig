const std = @import("std");
const cli = @import("cli.zig");
const parser = @import("parser.zig");
const plotter = @import("plotter.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const opts = try cli.parse(allocator);

    std.debug.print("Parsing '{s}'...\n", .{opts.input_path});
    const points = try parser.parseFile(allocator, opts.input_path, opts.dat_path);
    std.debug.print("Parsed {d} data points.\n", .{points.len});

    try plotter.runGnuplot(allocator, opts);
}
