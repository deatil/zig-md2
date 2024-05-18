## Zig-MD2 

zig-md2 is a MD2 hash function lib.


### Env

 - Zig >= 0.12


### Get Starting

~~~zig
const std = @import("std");
const MD2 = @import("zig-md2").MD2;

pub fn main() !void {
    var out: [16]u8 = undefined;
    
    h = MD2.init(.{});
    h.update("abc");
    h.final(out[0..]);
    
    // output: da853b0d3f88d99b30283a69e6ded6bb
    std.debug.print("output: {s}\n", .{out});
}
~~~


### LICENSE

*  The library LICENSE is `Apache2`, using the library need keep the LICENSE.


### Copyright

*  Copyright deatil(https://github.com/deatil).
