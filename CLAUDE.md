# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
make          # Build all ROM images
make clean    # Remove all build artifacts including dependencies
make tidy     # Remove ROM images only
make run      # Build and run in MAME emulator
make debug    # Build and run with MAME debugger
```

## Prerequisites

- GNU Make
- NASM (Netwide Assembler, tested with 2.16.03+)
- Perl (for build utilities, no extra modules needed)

## Project Overview

V9KRAMTEST is a diagnostic ROM for testing RAM in Victor 9000/ACT Sirius 1 computers. It replaces the system BIOS ROM and runs RAM tests without requiring functional RAM or file storage. Output is via RS-232 serial (19200 baud, 8N1) to a VT100-compatible terminal.

The ROM uses video RAM (segment F000h) as stack space, allowing it to test every byte of conventional RAM (up to 896KB).

## Architecture

- **Target CPU:** Intel 8086 (16-bit)
- **ROM location:** FE000-FFFFF (8KB at top of 1MB address space)
- **Video RAM:** F000:0000 - used for stack and variables during testing
- **Serial I/O:** Segment E004h (uPD7201 controller)

### RAM Testing Algorithms

1. **March-U** (`inc/ram_marchu.asm`) - Sequential read/write pattern detecting memory corruption including cross-location faults
2. **Ganssle** (`inc/ram_ganssle.asm`) - Aggressive address/data bus exercise with bit patterns (FF, 00, 55, AA, 01)

## Key Files

| File | Purpose |
|------|---------|
| `v9kramtest.asm` | Main entry point and test loop |
| `inc/defines.inc` | Hardware definitions, I/O ports, memory layout |
| `inc/macros.inc` | Assembly macros including `__CHECKPOINT__` |
| `inc/010_cold_boot.inc` | PIC, serial, and CRT initialization |
| `inc/060_vram.inc` | Video RAM testing and stack setup |
| `inc/ram_common.asm` | Shared RAM testing framework |
| `inc/ram_marchu.asm` | March-U algorithm implementation |
| `inc/ram_marchu_nostack.asm` | Stackless March-U variant for VRAM testing |
| `inc/ram_ganssle.asm` | Ganssle bit pattern testing |
| `inc/serial.asm` | RS-232 communication routines |
| `inc/screen.asm` | VT100 terminal output and formatting |

## Build Output

- `v9kramtest.bin` - 8KB ROM image (for 2764 EPROM with adapter)
- `v9kramtest_FE.bin` / `v9kramtest_FF.bin` - 4KB split images (for 2732 EPROMs)
- `v9kramtest.lst` - Assembly listing with line numbers
- `v9kramtest.map` - Memory map

## MAME Testing

The `make run` target copies ROM images to `$HOME/mrom/victor9k/` and launches MAME with:
- Serial output via PTY (configurable via `SERIAL` variable)
- 896KB RAM (configurable via `RAM` variable)
