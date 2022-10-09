package bloodlust.objs;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;

import bloodlust.utils.Input;
import bloodlust.utils.GameMath;

private typedef Point = {
	x: Float,
	y: Float,
}

class Player extends FlxSprite {

	static inline private var SPEED: Float = 175.0;
	static inline private var PLAYER_SIZE: Int = 24;

	private var plgInput: Input;

	override public function new() {
		super();

		this.makeGraphic(PLAYER_SIZE, PLAYER_SIZE, FlxColor.RED);
		this.plgInput = FlxG.plugins.get(Input);
	}

	private function getRawDirection(): Point {
		var p: Point = {
			x: 0.0,
			y: 0.0
		};

		if (this.plgInput.get(UP, PRESSED)) {
			p.y = -1.0;
		}
		else if (this.plgInput.get(DOWN, PRESSED)) {
			p.y = 1.0;
		}

		if (this.plgInput.get(LEFT, PRESSED)) {
			p.x = -1.0;
		}
		else if (this.plgInput.get(RIGHT, PRESSED)) {
			p.x = 1.0;
		}

		return p;
	}

	private function setWalkSpeed() {
		var p: Point = getRawDirection();

		GameMath.setNormalizedPoint(this.velocity, p.x, p.y, SPEED);
	}

	override public function update(elapsed:Float) {
		this.setWalkSpeed();

		super.update(elapsed);
	}
}

