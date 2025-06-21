package term

import "core:fmt"
import "core:sys/posix"
import "core:os"
import "core:unicode/utf8"

Cell :: struct {
	char: rune,
	color: u32, // 00RRGGBB
}

Term :: struct {
	cells: [dynamic]Cell,
	width: int,
	height: int,
}

// Remember to free() the return value!
new_term :: proc() -> ^Term {
	term := new(Term)
	term^ = Term{
		cells = make([dynamic]Cell, 20*20),
		width = 20,
		height = 20,
	}

	return term
}

print :: proc{
	print_string,
	print_rune,
}

print_rune :: proc(term: ^Term, x, y: int, c: rune) {
	print_string(term, x, y, utf8.runes_to_string({c}))
}

print_string :: proc(term: ^Term, x, y: int, str: string) {
	for i := 0; i < len(str); i += 1 {
		term.cells[x + i + y*term.width].char = rune(str[i])
	}
}

draw :: proc{
	draw_top_left,
	draw_at_pos,
}

draw_top_left :: proc(term: ^Term) {
	draw_at_pos(term, 0, 0)
}

draw_at_pos :: proc(term: ^Term, x, y: int) {
	for dy := 0; dy < term.height; dy += 1 {
		move_cursor(x, y+dy)
		for dx := 0; dx < term.width; dx += 1 {
			c := term.cells[dx + dy * term.width].char
			if c == 0 {
				fmt.print(" ")
			} else {
				fmt.print(c)
			}
		}
	}
}

Terminal :: struct {
	attributes: posix.termios,
	inputBuf: [256]byte,
}

// Returns true on success, false on failure
terminal_init :: proc(t: ^Terminal) -> bool {
	hide_cursor()
	enable_alternate_screen()

	ok := true
	t.attributes, ok = enable_raw_mode()
	if !ok {
		return false
	}

	return true
}

// Returns true on success, false on failure
terminal_fini :: proc(t: ^Terminal) -> bool {
	disable_alternate_screen()
	show_cursor()

	result := posix.tcsetattr(posix.STDIN_FILENO, .TCSAFLUSH, &t.attributes)
	if result == .FAIL {
		return false
	}

	return true
}

move_cursor :: proc(x, y: int) {
	// FIXME
	fmt.print("\x1b[")
	fmt.print(y+1)
	fmt.print(";")
	fmt.print(x+1)
	fmt.print("H")
}

enable_alternate_screen :: proc() {
	fmt.print("\x1b[?1049h") // Save cursor and use Alternate Screen Buffer, clearing it first
}

disable_alternate_screen :: proc() {
	fmt.print("\x1b[?1049l") // Restore cursor and exit Alternate Screen Buffer
}

show_cursor :: proc() {
	fmt.print("\x1b[?25h")
}

hide_cursor :: proc() {
	fmt.print("\x1b[?25l")
}

// Returns true on success, false on failure
enable_raw_mode :: proc() -> (posix.termios, bool) {
	raw: posix.termios
	result := posix.tcgetattr(posix.STDIN_FILENO, &raw)
	rawCopy := raw
	if result == .FAIL {
		return rawCopy, false
	}

	raw.c_lflag -= {.ECHO, .ICANON}

	result = posix.tcsetattr(posix.STDIN_FILENO, .TCSAFLUSH, &raw)
	if result == .FAIL {
		return rawCopy, false
	}

	return rawCopy, true
}

input :: proc(t: ^Terminal) -> rune {
	n, err := os.read(os.stdin, t.inputBuf[:])
	if err != nil {
		return 0
	}

	r, num := utf8.decode_rune_in_bytes(t.inputBuf[:])
	return r
}
