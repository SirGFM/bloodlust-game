package bloodlust.objs;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;

import bloodlust.utils.Input;
import bloodlust.utils.GameMath;

class Player extends FlxSprite {
	static inline private var SPEED: Float = 175.0;

	private var plgInput: Input;

	override public function new() {
		super();

		this.makeGraphic(24, 24, FlxColor.RED);
		this.plgInput = FlxG.plugins.get(Input);
	}

	private function setWalkSpeed() {
		var x:Float;
		var y:Float;

		if (this.plgInput.get(UP, PRESSED)) {
			y = -1;
		}
		else if (this.plgInput.get(DOWN, PRESSED)) {
			y = 1;
		}
		else {
			y = 0;
		}

		if (this.plgInput.get(LEFT, PRESSED)) {
			x = -1;
		}
		else if (this.plgInput.get(RIGHT, PRESSED)) {
			x = 1;
		}
		else {
			x = 0;
		}

		GameMath.setNormalizedPoint(this.velocity, x, y, SPEED);
	}

	override public function update(elapsed:Float) {
		this.setWalkSpeed();

		super.update(elapsed);
	}
}

