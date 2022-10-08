package;

import flixel.FlxGame;
import openfl.display.Sprite;

import bloodlust.states.SetupState;

class Main extends Sprite {
	public function new() {
		super();
		addChild(new FlxGame(320, 240, SetupState, 2));
	}
}
