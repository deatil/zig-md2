## Zig-MD2 

zig-md2 is a MD2 hash function for Zig.


### Env

 - Zig >= 0.14.0-dev.3451+d8d2aa9af


### Adding zig-md2 as a dependency

Add the dependency to your project:

```sh
zig fetch --save=zig-md2 git+https://github.com/deatil/zig-md2#main
```

or use local path to add dependency at `build.zig.zon` file

```zig
.{
    .dependencies = .{
        .@"zig-md2" = .{
            .path = "./lib/zig-md2",
        },
        ...
    },
    ...
}
```

And the following to your `build.zig` file:

```zig
    const zig_md2_dep = b.dependency("zig-md2", .{});
    exe.root_module.addImport("zig-md2", zig_md2_dep.module("zig-md2"));
```

The `zig-md2` structure can be imported in your application with:

```zig
const zig_md2 = @import("zig-md2");
```


### Get Starting

~~~zig
const std = @import("std");
const MD2 = @import("zig-md2").MD2;

pub fn main() !void {
    var out: [16]u8 = undefined;
    
    var h = MD2.init(.{});
    h.update("abc");
    h.final(out[0..]);
    
    // output: da853b0d3f88d99b30283a69e6ded6bb
    std.debug.print("output: {x}\n", .{out});
}
~~~


### LICENSE

*  The library LICENSE is `Apache2`, using the library need keep the LICENSE.


### Copyright

*  Copyright deatil(https://github.com/deatil).
