package anima_fsm

import ".."

FSM :: struct($Ident: typeid) {
	current: Maybe(Ident),
	states:  map[Ident]^anima.Animation,
}

create :: proc($Ident: typeid) -> ^FSM(Ident) {
	fsm := new(FSM(Ident))
	fsm.current = nil
	return fsm
}

destroy :: proc(self: ^FSM($Ident)) {
	for _, anim in self.states {
		anima.destroy_animation(anim)
	}
	delete(self.states)
	free(self)
}

add :: proc(self: ^FSM($Ident), ident: Ident, animation: ^anima.Animation) {
	assert(
		!(ident in self.states),
		"There is already an animation registered for this identifier!",
	)
	self.states[ident] = animation
}

play :: proc(self: ^FSM($Ident), ident: Ident) {
	if ident == self.current {
		return
	}

	if self.current != nil {
		current := self.current.(Ident)
		self.states[current].playing = false
	}

	assert(ident in self.states, "Unknown animation")

	self.current = ident
	self.states[ident].playing = true
	self.states[ident].index = 0
}

resume :: proc(self: ^FSM($Ident)) {
	assert(self.current != nil, "No animation selected")

	ident := self.current.(Ident)
	assert(ident in self.states, "Unknown animation")

	self.states[ident].playing = true
}

stop :: proc(self: ^FSM($Ident)) {
	assert(self.current != nil, "No animation selected")

	ident := self.current.(Ident)
	assert(ident in self.states, "Unknown animation")

	self.states[ident].playing = false
}

update :: proc(self: ^FSM($Ident), dt: f32) {
	assert(self.current != nil, "No animation selected")

	ident := self.current.(Ident)
	assert(ident in self.states, "Unknown animation")

	anima.update(self.states[ident], dt)
}

current_animation :: proc(self: ^FSM($Ident)) -> ^anima.Animation {
	assert(self.current != nil, "No animation selected")

	ident := self.current.(Ident)
	assert(ident in self.states, "Unknown animation")

	return self.states[ident]
}
