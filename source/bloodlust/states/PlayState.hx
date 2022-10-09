package bloodlust.states;

import flixel.FlxG;
import flixel.FlxState;

import bloodlust.objs.Player;
import bloodlust.ui.PlaystateUi;

class PlayState extends FlxState {

	private var plgUi: PlaystateUi;

	override public function create() {
		super.create();

		plgUi = FlxG.plugins.get(PlaystateUi);
		plgUi.onEnterPlaystate();

		this.add(new Player());
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
	}

	override public function draw() {
		super.draw();

		plgUi.manualDraw();
	}
}
