const std = @import("std");
const math = std.math;

pub const DataPoint = struct {
    freq: f64,
    mag_db: f64,
    phase_deg: f64,
    magnitude: f64,
};

pub fn parseFile(
    allocator: std.mem.Allocator,
    input_path: []const u8,
    dat_path: []const u8,
) ![]DataPoint {
    const file = try std.fs.cwd().openFile(input_path, .{});
    defer file.close();

    const dat_file = try std.fs.cwd().createFile(dat_path, .{});
    defer dat_file.close();

    var dat_buf: [512]u8 = undefined;
    var dat_writer = dat_file.writer(&dat_buf);
    try dat_writer.interface.print("# Freq_Hz  Magnitude_dB  Phase_deg  Magnitude_linear\n", .{});

    var read_buffer: [256]u8 = undefined;
    var reader = file.reader(&read_buffer);

    var points: std.ArrayListUnmanaged(DataPoint) = .empty;

    var prev_raw_phase: f64 = 0.0;
    var phase_offset: f64 = 0.0;
    var first_line: bool = true;

    var line_no: usize = 0;
    while (try reader.interface.takeDelimiter('\n')) |line| {
        line_no += 1;
        if (line_no == 1) continue;

        const trimmed = std.mem.trimRight(u8, line, "\r");
        var cols = std.mem.splitScalar(u8, trimmed, '\t');
        const freq_str = cols.next() orelse continue;
        const val_str = cols.next() orelse continue;

        var parts = std.mem.splitScalar(u8, val_str, ',');
        const re_str = parts.next() orelse continue;
        const im_str = parts.next() orelse continue;

        const freq = std.fmt.parseFloat(f64, freq_str) catch continue;
        const re = std.fmt.parseFloat(f64, re_str) catch continue;
        const im = std.fmt.parseFloat(f64, im_str) catch continue;

        const magnitude = math.sqrt(re * re + im * im);
        const mag_db = 20.0 * @log10(magnitude);
        var phase_deg = math.atan2(im, re) * (180.0 / math.pi);

        if (first_line) {
            first_line = false;
        } else {
            const diff = phase_deg - prev_raw_phase;
            if (diff > 180.0) {
                phase_offset -= 360.0 * @round(diff / 360.0 + 0.5);
            } else if (diff < -180.0) {
                phase_offset += 360.0 * @round(-diff / 360.0 + 0.5);
            }
        }
        prev_raw_phase = phase_deg;
        phase_deg += phase_offset;

        try dat_writer.interface.print("{e:.6}  {d:.6}  {d:.6}  {e:.6}\n", .{
            freq, mag_db, phase_deg, magnitude,
        });

        try points.append(allocator, .{
            .freq = freq,
            .mag_db = mag_db,
            .phase_deg = phase_deg,
            .magnitude = magnitude,
        });
    }
    try dat_writer.interface.flush();

    return points.toOwnedSlice(allocator);
}
