package bloodlust.objs;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;

import bloodlust.utils.Input;
import bloodlust.utils.GameMath;

private enum PlayerState {
	STAND;
	WALK;
}

private typedef Point = {
	x: Float,
	y: Float,
}

class Player extends FlxSprite {

	static inline private var SPEED: Float = 175.0;
	static inline private var PLAYER_SIZE: Int = 24;

	private var plgInput: Input;

	private var _lastState: PlayerState;
	private var _state: PlayerState;

	override public function new() {
		super();

		this.makeGraphic(PLAYER_SIZE, PLAYER_SIZE, FlxColor.RED);
		this.plgInput = FlxG.plugins.get(Input);

		this._state = STAND;
		this._lastState = STAND;
	}

	private function getNewState(): PlayerState {
		if (this.plgInput.getAny([LEFT, RIGHT, UP, DOWN], PRESSED)) {
			return WALK;
		}

		return STAND;
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
		this._state = this.getNewState();

		switch (this._state) {
		case WALK:
			this.setWalkSpeed();
		case STAND:
			this.velocity.scale(0);
		default:
			{ /* do nothing */ }
		}

		super.update(elapsed);

		this._lastState = this._state;
	}
}

