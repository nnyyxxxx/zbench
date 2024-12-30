<div align="center">

# zbench

![](.github/zbench.png)

A terminal performance benchmarking tool written in Zig.

</div>

## Features

- **cursor_motion**:     Tests cursor positioning performance
- **dense_cells**:       Tests heavy terminal rendering with colors and attributes
- **light_cells**:       Tests basic character output
- **medium_cells**:      Tests moderate terminal rendering with colors
- **scrolling**:         Tests terminal scrolling performance
- **unicode**:           Tests Unicode character rendering
- **fullscreen_scroll**: Tests fullscreen scrolling performance

## Usage

### Building

```
zig build run
```

## Output Format

Results show:
- Average time per operation
- Percentile
- Standard deviation
- Sample count
- Benchmark size

## Credit

Technically a rewrite of [vtebench](https://github.com/alacritty/vtebench) in Zig.

## License

Copyright (C) 2024 [Nyx](https://github.com/nnyyxxxx)

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License version 2 as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA or see <https://www.gnu.org/licenses/old-licenses/gpl-2.0.txt>

The full license can be found in the [license](license) file.