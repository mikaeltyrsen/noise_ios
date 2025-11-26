import SwiftUI
import MetalKit

struct ProceduralNoiseView: View {
    var animationSpeed: Float = 0.25

    var body: some View {
        NoiseShaderView(animationSpeed: animationSpeed)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}

private struct NoiseShaderView: UIViewRepresentable {
    var animationSpeed: Float

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
        mtkView.preferredFramesPerSecond = 30
        mtkView.framebufferOnly = true
        mtkView.colorPixelFormat = .bgra8Unorm

        if let device = mtkView.device, let renderer = NoiseRenderer(device: device, animationSpeed: animationSpeed) {
            context.coordinator.renderer = renderer
            mtkView.delegate = renderer
        }

        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.renderer?.animationSpeed = animationSpeed
    }

    final class Coordinator {
        var renderer: NoiseRenderer?
    }
}

private final class NoiseRenderer: NSObject, MTKViewDelegate {
    var animationSpeed: Float

    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private var startTime: CFTimeInterval = CACurrentMediaTime()

    private let vertices: [SIMD2<Float>] = [
        [-1, -1], [1, -1],
        [-1, 1], [1, 1]
    ]

    init?(device: MTLDevice, animationSpeed: Float) {
        self.animationSpeed = animationSpeed

        guard let commandQueue = device.makeCommandQueue() else {
            return nil
        }

        do {
            let library = try device.makeLibrary(source: Self.shaderSource, options: nil)
            let vertexFunction = library.makeFunction(name: "vertex_passthrough")
            let fragmentFunction = library.makeFunction(name: "fragment_noise")

            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = vertexFunction
            descriptor.fragmentFunction = fragmentFunction
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

            self.pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            return nil
        }

        self.commandQueue = commandQueue

        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard
            let drawable = view.currentDrawable,
            let passDescriptor = view.currentRenderPassDescriptor,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)
        else { return }

        let elapsed = Float(CACurrentMediaTime() - startTime) * animationSpeed
        var resolution = SIMD2<Float>(Float(view.drawableSize.width), Float(view.drawableSize.height))
        var time = elapsed

        encoder.setRenderPipelineState(pipelineState)
        encoder.setCullMode(.none)
        encoder.setVertexBytes(vertices, length: MemoryLayout<SIMD2<Float>>.stride * vertices.count, index: 0)
        encoder.setFragmentBytes(&time, length: MemoryLayout<Float>.stride, index: 0)
        encoder.setFragmentBytes(&resolution, length: MemoryLayout<SIMD2<Float>>.stride, index: 1)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: vertices.count)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

private extension NoiseRenderer {
    static let shaderSource = """
    #include <metal_stdlib>
    using namespace metal;

    struct VertexOut {
        float4 position [[position]];
    };

    vertex VertexOut vertex_passthrough(
        uint vertexID [[vertex_id]],
        const device float2 *vertices [[buffer(0)]]) {
        VertexOut out;
        out.position = float4(vertices[vertexID], 0.0, 1.0);
        return out;
    }

    float random3(float3 p) {
        return fract(sin(dot(p, float3(127.1, 311.7, 74.7))) * 43758.5453123);
    }

    fragment float4 fragment_noise(
        VertexOut in [[stage_in]],
        constant float &time [[buffer(0)]],
        constant float2 &resolution [[buffer(1)]]) {
        float2 uv = (in.position.xy * 0.5 + 0.5) * resolution;

        // Introduce a frame-based seed so the grain changes every redraw,
        // mimicking classic television static.
        float frame = floor(time * 90.0);
        float grain = random3(float3(floor(uv), frame));

        // Push the distribution toward stark black and white noise.
        float blackAndWhite = step(0.5, grain);
        return float4(float3(blackAndWhite), 1.0);
    }
    """
}
