const std = @import("std");
const print = std.debug.print;

// Create SDL and SDL_gpu bindings
const sdl = @cImport(@cInclude("SDL.h"));
const gpu = @cImport(@cInclude("SDL_gpu.h"));

var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
const allocator = &arena.allocator;

const TILE_COUNT = 100000;

const Position = packed struct {
    x: f32,
    y: f32,
};

const Rotation = packed struct {
    angle: u8,
};

const Color = packed struct {
    r: u8,
    g: u8,
    b: u8,
};

var positions = std.ArrayList(Position).init(allocator);
var rotations = std.ArrayList(Rotation).init(allocator);
var colors    = std.ArrayList(Color).init(allocator);

fn addTile() void {
    const err1 = positions.append(Position {
        .x = 0,
        .y = 0,
    });

    const err2 = rotations.append(Rotation {
        .angle = 0,
    });

    const err3 = colors.append(Color {
        .r = 255,
        .g = 255,
        .b = 255,
    });
}

fn runGPU() void {
    const gpuTarget = gpu.GPU_Init(1280, 720, gpu.GPU_DEFAULT_INIT_FLAGS);
    // TODO: Setting the camera moves its position, need to figure out the right place
    // var camera = gpu.GPU_GetDefaultCamera();
    // camera.zoom_x = 0;
    // camera.zoom_y = 0;
    // _ = gpu.GPU_SetCamera(gpuTarget, &camera);

    const image = gpu.GPU_LoadImage("../crash-the-stack/dist/assets/images/tile.png");
    gpu.GPU_SetSnapMode(image, gpu.GPU_SnapEnum.GPU_SNAP_NONE);

    print("Allocating {} tiles...\n", .{TILE_COUNT});

    var i: usize = 0;
    while (i < TILE_COUNT) {
        addTile();
        i += 1;
    }

    print("Allocation complete!\n", .{});
    
    var fps: f32 = -1.0;
    var lastFrameTime: u32 = sdl.SDL_GetTicks();
    var currentFrameTime: u32 = 0;
    var timeStep: f32 = 0;
    var lastFpsPrint = lastFrameTime;

    while (true) {
        currentFrameTime = sdl.SDL_GetTicks();
        timeStep = @intToFloat(f32, currentFrameTime - lastFrameTime) / 1000.0;

        if (fps > -1.0) {
          fps = (fps * 0.95) + (0.05 * (1.0 / timeStep));
        } else if (timeStep > 0.0) {
          fps = 1.0 / timeStep;
        }

        sdl.SDL_PumpEvents();
        const state = sdl.SDL_GetKeyboardState(null);
        if (state[sdl.SDL_SCANCODE_ESCAPE] > 0) {
          break;
        }

        gpu.GPU_Clear(gpuTarget);

        var j: usize = 0;
        while (j < TILE_COUNT) {
            const pos = positions.items[j];
            gpu.GPU_Blit(image, null, gpuTarget, pos.x, pos.y);
            j += 1;
        }

        gpu.GPU_Flip(gpuTarget);

        lastFrameTime = currentFrameTime;
        if (currentFrameTime - lastFpsPrint > 1000) {
            lastFpsPrint = currentFrameTime;
            print("fps: {d:.3}\n", .{fps});
        }
    }

    print("Exiting...\n", .{});

    gpu.GPU_Quit();
}

pub fn main() anyerror!void {
    runGPU();
}
