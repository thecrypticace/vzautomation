//
//  GridView.swift
//  VZAutomation
//
//  Created by Jordan Pittman on 8/31/24.
//

import SwiftUI

struct GridView: View {
  struct Tile {
    let width: CGFloat
    let height: CGFloat
    let with: GraphicsContext.Shading
  }

  let tiles: [Tile]

  var body: some View {
    Canvas(opaque: true, rendersAsynchronously: true) { ctx, size in
      drawBackground(in: ctx, size: size)

      for tile in tiles {
        draw(tile: tile, in: ctx, size: size)
      }
    }
  }

  private func drawBackground(
    in ctx: GraphicsContext,
    size: CGSize
  ) {
    ctx.fill(
      Path(CGRect(origin: .zero, size: size)),
      with: .color(Color(white: 0.075))
    )
  }

  private func drawNoise(
    in ctx: GraphicsContext,
    size: CGSize
  ) {
    let noiseFn = ShaderFunction(library: .default, name: "noise")
    let shader = Shader(function: noiseFn, arguments: [])

    ctx.fill(
      Path(CGRect(origin: .zero, size: size)),
      with: .shader(shader)
    )
  }


  private func draw(
    tile: Tile,
    in ctx: GraphicsContext,
    size: CGSize
  ) {
    let x = Path { path in
      for i in 0...Int(size.width/tile.width) {
        let x = tile.width * CGFloat(i)

        path.move(to: .init(x: x, y: 0))
        path.addLine(to: .init(x: x, y: size.height))
      }
    }

    let y = Path { path in
      for i in 0...Int(size.height/tile.height) {
        let y = tile.height * CGFloat(i)

        path.move(to: .init(x: 0, y: y))
        path.addLine(to: .init(x: size.width, y: y))
      }
    }

    ctx.stroke(x, with: tile.with, style: .init(lineWidth: 1, dash: [4, 4], dashPhase: 2.0))
    ctx.stroke(y, with: tile.with, style: .init(lineWidth: 1, dash: [4, 4], dashPhase: 2.0))
  }
}

#Preview("Single Tile") {
  GridView(tiles: [
    .init(width: 24 * 1, height: 24 * 1, with: .color(white: 0.125)),
  ])
}

#Preview("Multiple Tiles") {
  GridView(tiles: [
    .init(width: 24 * 1, height: 24 * 1, with: .color(white: 0.125)),
    .init(width: 24 * 3, height: 24 * 3, with: .color(white: 0.250)),
  ])
}
