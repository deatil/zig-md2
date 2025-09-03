const std = @import("std");
const testing = std.testing;
const fmt = std.fmt;

/// The MD2 function is now considered cryptographically broken.
/// Namely, it is trivial to find multiple inputs producing the same hash.
pub const MD2 = struct {
    s: [48]u8 = undefined,
    // Streaming Cache
    buf: [16]u8 = undefined,
    buf_len: u8 = 0,
    total_len: u64 = 0,

    // the digest, Size
    digest: [16]u8 = undefined,

    const Self = @This();

    pub const block_length = 16;
    pub const digest_length = 16;
    pub const Options = struct {};

    const sbox = [_]u8{
        41,  46,  67,  201, 162, 216, 124, 1,   61,  54,  84,  161, 236, 240, 6,
        19,  98,  167, 5,   243, 192, 199, 115, 140, 152, 147, 43,  217, 188, 76,
        130, 202, 30,  155, 87,  60,  253, 212, 224, 22,  103, 66,  111, 24,  138,
        23,  229, 18,  190, 78,  196, 214, 218, 158, 222, 73,  160, 251, 245, 142,
        187, 47,  238, 122, 169, 104, 121, 145, 21,  178, 7,   63,  148, 194, 16,
        137, 11,  34,  95,  33,  128, 127, 93,  154, 90,  144, 50,  39,  53,  62,
        204, 231, 191, 247, 151, 3,   255, 25,  48,  179, 72,  165, 181, 209, 215,
        94,  146, 42,  172, 86,  170, 198, 79,  184, 56,  210, 150, 164, 125, 182,
        118, 252, 107, 226, 156, 116, 4,   241, 69,  157, 112, 89,  100, 113, 135,
        32,  134, 91,  207, 101, 230, 45,  168, 2,   27,  96,  37,  173, 174, 176,
        185, 246, 28,  70,  97,  105, 52,  64,  126, 15,  85,  71,  163, 35,  221,
        81,  175, 58,  195, 92,  249, 206, 186, 197, 234, 38,  44,  83,  13,  110,
        133, 40,  132, 9,   211, 223, 205, 244, 65,  129, 77,  82,  106, 220, 55,
        200, 108, 193, 171, 250, 36,  225, 123, 8,   12,  189, 177, 74,  120, 136,
        149, 139, 227, 99,  232, 109, 233, 203, 213, 254, 59,  0,   29,  57,  242,
        239, 183, 14,  102, 88,  208, 228, 166, 119, 114, 248, 235, 117, 75,  10,
        49,  68,  80,  180, 143, 237, 31,  26,  219, 153, 141, 51,  159, 17,  131,
        20,
    };

    pub fn init(options: Options) Self {
        _ = options;

        var self = Self{};

        @memset(self.s[0..], 0);
        @memset(self.buf[0..], 0);
        @memset(self.digest[0..], 0);

        self.buf_len = 0;
        self.total_len = 0;

        return self;
    }

    pub fn hash(b: []const u8, out: *[digest_length]u8, options: Options) void {
        var d = MD2.init(options);
        d.update(b);
        d.final(out);
    }

    pub fn update(d: *Self, b: []const u8) void {
        var off: usize = 0;

        // Partial buffer exists from previous update. Copy into buffer then hash.
        if (d.buf_len != 0 and d.buf_len + b.len >= 16) {
            off += 16 - d.buf_len;
            @memcpy(d.buf[d.buf_len..][0..off], b[0..off]);

            d.round(d.buf[0..]);
            d.buf_len = 0;
        }

        // Full middle blocks.
        while (off + 16 <= b.len) : (off += 16) {
            d.round(b[off..][0..16]);
        }

        // Copy any remainder for next pass.
        const b_slice = b[off..];
        @memcpy(d.buf[d.buf_len..][0..b_slice.len], b_slice);
        d.buf_len += @as(u8, @intCast(b_slice.len));

        // MD2 uses the bottom 16-bits for length padding
        d.total_len +%= b.len;
    }

    pub fn final(d: *Self, out: *[digest_length]u8) void {
        const padding = 16 - d.buf_len;

        // The buffer here will never be completely full.
        @memset(d.buf[d.buf_len..], padding);

        d.round(d.buf[0..]);
        d.round(d.digest[0..]);

        @memcpy(out[0..digest_length], d.s[0..digest_length]);
    }

    pub fn finalResult(d: *Self) [digest_length]u8 {
        var result: [digest_length]u8 = undefined;
        d.final(&result);
        return result;
    }

    fn round(d: *Self, b: *const [16]u8) void {
        var t: usize = 0;
        var i: usize = 0;
        var j: usize = 0;

        while (i < 16) : (i += 1) {
            d.s[i + 16] = b[i];
            d.s[i + 32] = (b[i] ^ d.s[i]) & 0xff;
        }

        i = 0;
        while (i < 18) : (i += 1) {
            j = 0;
            while (j < 48) : (j += 1) {
                d.s[j] = (d.s[j] ^ sbox[t]) & 0xff;
                t = d.s[j];
            }

            t = (t + i) & 0xff;
        }

        t = d.digest[15];

        i = 0;
        while (i < 16) : (i += 1) {
            d.digest[i] = (d.digest[i] ^ sbox[b[i] ^ t]) & 0xff;
            t = d.digest[i];
        }
    }
};

// Hash using the specified hasher `H` asserting `expected == H(input)`.
pub fn assertEqualHash(comptime Hasher: anytype, comptime expected_hex: *const [Hasher.digest_length * 2:0]u8, input: []const u8) !void {
    var h: [Hasher.digest_length]u8 = undefined;
    Hasher.hash(input, &h, .{});

    try assertEqual(expected_hex, &h);
}

// Assert `expected` == hex(`input`) where `input` is a bytestring
pub fn assertEqual(comptime expected_hex: [:0]const u8, input: []const u8) !void {
    var expected_bytes: [expected_hex.len / 2]u8 = undefined;
    for (&expected_bytes, 0..) |*r, i| {
        r.* = fmt.parseInt(u8, expected_hex[2 * i .. 2 * i + 2], 16) catch unreachable;
    }

    try testing.expectEqualSlices(u8, &expected_bytes, input);
}

test "single" {
    try assertEqualHash(MD2, "8350e5a3e24c153df2275c9f80692773", "");
    try assertEqualHash(MD2, "32ec01ec4a6dac72c0ab96fb34c0b5d1", "a");
    try assertEqualHash(MD2, "da853b0d3f88d99b30283a69e6ded6bb", "abc");
    try assertEqualHash(MD2, "ab4f496bfb2a530b219ff33031fe06b0", "message digest");
    try assertEqualHash(MD2, "4e8ddff3650292ab5a4108c3aa47940b", "abcdefghijklmnopqrstuvwxyz");
    try assertEqualHash(MD2, "da33def2a42df13975352846c30338cd", "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789");
    try assertEqualHash(MD2, "d5976f79d83d3a0dc9806c3c66f3efd8", "12345678901234567890123456789012345678901234567890123456789012345678901234567890");
}

test "streaming" {
    var out: [16]u8 = undefined;

    var h = MD2.init(.{});
    h.final(out[0..]);
    try assertEqual("8350e5a3e24c153df2275c9f80692773", out[0..]);

    h = MD2.init(.{});
    h.update("abc");
    h.final(out[0..]);
    try assertEqual("da853b0d3f88d99b30283a69e6ded6bb", out[0..]);

    h = MD2.init(.{});
    h.update("a");
    h.update("b");
    h.update("c");
    h.final(out[0..]);

    try assertEqual("da853b0d3f88d99b30283a69e6ded6bb", out[0..]);
}

test "finalResult" {
    var h = MD2.init(.{});
    var out = h.finalResult();
    try assertEqual("8350e5a3e24c153df2275c9f80692773", out[0..]);

    h = MD2.init(.{});
    h.update("abc");
    out = h.finalResult();
    try assertEqual("da853b0d3f88d99b30283a69e6ded6bb", out[0..]);
}

test "aligned final" {
    var block = [_]u8{0} ** MD2.block_length;
    var out: [MD2.digest_length]u8 = undefined;

    var h = MD2.init(.{});
    h.update(&block);
    h.final(out[0..]);
}
