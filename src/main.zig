const std = @import("std");
const math = std.math;

// Available sizes: 300x240, 150x120
const screen_width = 75;
const screen_height = 60;

const theta_spacing = 0.07;
const phi_spacing = 0.02;

const R1 = 1.0;
const R2 = 2.0;
const K2 = 5.0;

const K1 = screen_width * K2 * 3 / (8 * (R1 + R2));

const symbols = [_]u8{ '.', ',', '-', '~', ':', ';', '=', '!', '*', '#', '$', '@' };

fn render(a: f32, b: f32) void {
    const sin_a = math.sin(a);
    const sin_b = math.sin(b);
    const cos_a = math.cos(a);
    const cos_b = math.cos(b);

    var output: [screen_width][screen_height]u8 = [_][screen_height]u8{[_]u8{' '} ** screen_height} ** screen_width;
    var zbuffer: [screen_width][screen_height]f32 = [_][screen_height]f32{[_]f32{0} ** screen_height} ** screen_width;

    var theta: f32 = 0;
    while (theta < 2 * math.pi) : (theta += theta_spacing) {
        const sin_theta = math.sin(theta);
        const cos_theta = math.cos(theta);

        var phi: f32 = 0;
        while (phi < 2 * math.pi) : (phi += phi_spacing) {
            const sin_phi = math.sin(phi);
            const cos_phi = math.cos(phi);

            const circle_x = R2 + R1 * cos_theta;
            const circle_y = R1 * sin_theta;

            const x = circle_x * (cos_b * cos_phi + sin_a * sin_b * sin_phi) - circle_y * cos_a * sin_b;
            const y = circle_x * (sin_b * cos_phi - sin_a * cos_b * sin_phi) + circle_y * cos_a * cos_b;
            const z = K2 + cos_a * circle_x * sin_phi + circle_y * sin_a;
            const ooz = 1 / z;

            const xo = @as(i32, @intFromFloat(screen_width / 2 + K1 * ooz * x));
            const yo = @as(i32, @intFromFloat(screen_height / 2 - K1 * ooz * y));

            const L = cos_phi * cos_theta * sin_b - cos_a * cos_theta * sin_phi - sin_a * sin_theta + cos_b * (cos_a * sin_theta - cos_theta * sin_a * sin_phi);

            if (L > 0) {
                if (xo >= 0 and yo >= 0 and xo < screen_width and yo < screen_height) {
                    const xp = @as(usize, @intCast(xo));
                    const yp = @as(usize, @intCast(yo));

                    if (ooz > zbuffer[xp][yp]) {
                        zbuffer[xp][yp] = ooz;
                        const luminance_index = @as(usize, @intFromFloat(L * 8));
                        output[xp][yp] = symbols[luminance_index];
                    }
                }
            }
        }
    }

    std.debug.print("\x1b[H", .{});

    var j: usize = 0;
    while (j < screen_height) : (j += 1) {
        var i: usize = 0;
        while (i < screen_width) : (i += 1) {
            std.debug.print("{c}", .{output[i][j]});
        }
        std.debug.print("\n", .{});
    }
}

pub fn main() !void {
    var a: f32 = 1;
    var b: f32 = 1;
    while (true) {
        a += 0.07;
        b += 0.03;
        render(a, b);
    }
}
