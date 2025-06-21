package main

import "term"
import "core:fmt"
import "core:time"

main :: proc() {
	terminal: term.Terminal
	term.terminal_init(&terminal)
	defer term.terminal_fini(&terminal)

	t := term.new_term()
	term.draw(t)
	term.print(t, 0, 0, "test1")
	term.print(t, 5, 1, "test2")
	term.draw(t)

	i := 0
	for {
		c := term.input(&terminal)

		if c == 'q' {
			break
		}

		term.print(t, i, 2, c)
		i += 1

		term.draw(t)
	}
}
