# Subleq

Single instruction computer based on the [subleq][1] instruction.


# Dependencies

The circuit diagrams are written in and for [Logisim][2].

The javascript emulator is written for [node.js][3].


# ISA

There is only one instruction: `subleq`. I/O is handled by traps.

## `subleq A B C`:

    mem[B] = mem[B] - mem[A]
    PC = PC + C if mem[B] <= 0

Bitfields:

 - 0-7: `A`
 - 8-15: `B`
 - 16-23: `C`


# Traps

Traps are triggered by jumping to reserved addresses:

 - `0xFF`: Triggers the `HALT` light and sets the `ST` pin. Pauses
   computation until the `RST` pin is pulsed, regardless of `EN`
   status.
 - `0xFE`: *(unimplemented)* Triggers printing the value at this
   address to the terminal. Pauses computation until the character
   is printed.
 - `0xFD`: *(unimplemented)* Triggers switching to the memory chip
   identified by the value at this address. Resets the instruction
   pointer to 0.

Other addresses may become reserved as needed. In general, assume everything
between `0xF0` and `0xFF` is reserved.


# Compiler

For convenience, a simple compiler is provided. In addition to `subleq`, it
also supports labels, data blocks, symbolic references, and some convenience
instructions. Comments are line-based and prefixed with `#`.

## Labels

Labels are word characters that start at the beginning of the line and
terminate with a `:`. For example:

    main:
    subroutine:

## Data blocks

Data blocks are lines that start with a `.` followed by a word. They accept as
an argument the value to store at that address. For example:

    .foo    0xFE
    .bar    0x03

## Symbolic references

When an instruction could take an argument, instead of giving a hexadecimal
value, you can give the name of a label or data block. For example:

    jmp main                # Unconditional absolute jump to "main"
    subleq foo bar main     # subtract the value at "foo" from the value at
                            # "bar" and jump to "main" if the value at
                            # "bar" <= 0

## Instructions

Arguments wrapped in `[]` are optional - they will be populated with the sane
default value. Usually this becomes the 3rd argument to `subleq`, which
defaults to `0x1` - the next instruction.

By convention, `Z` is an empty memory address. By default, the compiler will
use the address immediately after the loaded code.

### `add A B [C]`

Add the value of `A` to `B`. Optionally jump to `C` if the new value of `B` is
less than or equal to `0`. Equivalent to:

    subleq A Z
    subleq Z B
    subleq Z Z C

### `mov A B [C]`

Copy the value of `A` into `B`. Optionally jump to `C` if the new value of `B` is
less than or equal to `0`. Equivalent to:

    subleq B B
    subleq A Z
    subleq Z B
    subleq Z Z C

### `jmpr A`

Jump to address `A` relative to the current location. Equivalent to:

    subleq Z Z A

### `jmp A`

Jump to absolute address `A`. Equivalent to:

    subleq Z Z (A - $line + 1)

### `halt`

Jump to the `halt` trap. Equivalent to:

    subleq Z Z 0xFF


[1]: https://en.wikipedia.org/wiki/Subleq#Subtract_and_branch_if_less_than_or_equal_to_zero
[2]: http://ozark.hendrix.edu/~burch/logisim/
[3]: http://nodejs.org/
