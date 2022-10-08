package bloodlust.states;

import flixel.FlxState;

import bloodlust.objs.Player;

class PlayState extends FlxState {
	override public function create() {
		super.create();

		this.add(new Player());
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
	}
}
