package bloodlust.objs;

import haxe.Timer;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

import bloodlust.utils.Input;
import bloodlust.utils.GameMath;

private enum PlayerState {
	STAND;
	WALK;
	PREDASH;
	DASHING;
}

private typedef Point = {
	x: Float,
	y: Float,
}

class Player extends FlxSprite {

	static inline private var SPEED: Float = 175.0;
	static inline private var PLAYER_SIZE: Int = 24;
	static inline private var DASH_DISTANCE: Float = 125.0;
	static inline private var DASH_TIME: Float = 0.3;

	static inline private var AIM_SPRITE_SIZE: Int = 64;
	static inline private var AIM_SPRITE_START: Float = AIM_SPRITE_SIZE * 2 / 8;
	static inline private var AIM_SPRITE_END: Float = AIM_SPRITE_SIZE * 3 / 8;

	static inline private var AIM_BAR_HEIGHT: Int = 16;
	static inline private var AIM_BAR_OFFSET: Int = 2;
	static inline private var AIM_BAR_BORDER: Int = 4;
	static inline private var BAR_COLOR_BORDER: Int = 0xffd95763;
	static inline private var BAR_COLOR_EMPTY: Int = 0xff45283c;
	static inline private var BAR_COLOR_FILL: Int = 0xffac3232;

	/* How long may the player take aiming. */
	static inline private var AIM_TIME: Float = 5.0;

	/* Maximum factor by which the time is slowed down. */
	static inline private var AIM_MAX_SLOWDOWN: Float = 0.5;

	/* Percentage of the aim time
	 * during which the timeScale decreases to the maximum slowdown factor,
	 * until it starts increasing again. */
	static inline private var AIM_SLOWDOWN_PERCENTAGE: Float = 0.1;

	private function getTimeScale(): Float {
		var perc: Float;

		if (this._aimPercentage < AIM_SLOWDOWN_PERCENTAGE) {
			perc = this._aimPercentage / AIM_SLOWDOWN_PERCENTAGE;
		}
		else {
			perc = this._aimPercentage - AIM_SLOWDOWN_PERCENTAGE;
			perc /= 1.0 - AIM_SLOWDOWN_PERCENTAGE;
			perc = 1.0 - perc;
		}

		return 1.0 - AIM_MAX_SLOWDOWN * perc;
	}

	private var plgInput: Input;

	private var _aimBar: FlxBar;
	private var _aim: FlxSprite;
	private var _aimStart: Float;
	private var _aimPercentage: Float;

	private var _dashDuration: Float;

	private var _lastState: PlayerState;
	private var _state: PlayerState;

	override public function new() {
		super();

		this.makeGraphic(PLAYER_SIZE, PLAYER_SIZE, FlxColor.RED);
		this.plgInput = FlxG.plugins.get(Input);

		this._aim = new FlxSprite();
		this._aim.makeGraphic(AIM_SPRITE_SIZE, AIM_SPRITE_SIZE, 0, true);
		this._aim.width = this.width;
		this._aim.height = this.height;
		this._aim.centerOffsets();

		this._aimBar = new FlxBar(
			AIM_BAR_OFFSET + AIM_BAR_BORDER,
			FlxG.height - AIM_BAR_HEIGHT - AIM_BAR_OFFSET - AIM_BAR_BORDER,
			LEFT_TO_RIGHT,
			FlxG.width - 2 * (AIM_BAR_OFFSET + AIM_BAR_BORDER),
			AIM_BAR_HEIGHT,
			null,
			"",
			0.0,
			1.0,
			true
		);
		this._aimBar.createFilledBar(
			BAR_COLOR_EMPTY,
			BAR_COLOR_FILL,
			true,
			BAR_COLOR_BORDER
		);

		this._state = STAND;
		this._lastState = STAND;
	}

	private function getNewState(): PlayerState {
		switch (this._state) {
		case DASHING:
			if (this._dashDuration <= 0.0) {
				return STAND;
			}

			return DASHING;
		case PREDASH:
			/* Forcefully stop dash-aiming after a while. */
			if (Timer.stamp() - this._aimStart > AIM_TIME) {
				return STAND;
			}
		default:
			{ /* Do nothing */ }
		}

		if (
			(
				this._state != PREDASH &&
				this._state != DASHING &&
				this.plgInput.get(DASH, JUST_PRESSED)
			) ||
			(this._state == PREDASH && this.plgInput.get(DASH, PRESSED))
		) {
			return PREDASH;
		}
		else if (
			this._state == PREDASH &&
			this.plgInput.get(DASH, JUST_RELEASED)
		) {
			return DASHING;
		}
		else if (this.plgInput.getAny([LEFT, RIGHT, UP, DOWN], PRESSED)) {
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

	private function setAim() {
		var src: FlxPoint;
		var dst: FlxPoint;
		var p: Point;

		var now: Float = Timer.stamp();
		if (this._lastState != PREDASH) {
			this._aimStart = now;
		}
		this._aimPercentage = Math.min(now - this._aimStart, AIM_TIME);
		this._aimPercentage /= AIM_TIME;
		FlxG.timeScale = getTimeScale();

		p = getRawDirection();
		src = FlxPoint.get();
		dst = FlxPoint.get();
		GameMath.setNormalizedPoint(src, p.x, p.y, AIM_SPRITE_START);
		GameMath.setNormalizedPoint(dst, p.x, p.y, AIM_SPRITE_END);

		p.x = this._aim.frameWidth * 0.5;
		p.y = this._aim.frameHeight * 0.5;

		FlxSpriteUtil.fill(this._aim, 0);

		FlxSpriteUtil.drawLine(
			this._aim,
			Math.fround(p.x + src.x),
			Math.fround(p.y + src.y),
			Math.fround(p.x + dst.x),
			Math.fround(p.y + dst.y),
			{
				thickness: 3,
				color: FlxColor.BLACK
			}
		);
		FlxSpriteUtil.drawLine(
			this._aim,
			Math.fround(p.x + src.x),
			Math.fround(p.y + src.y),
			Math.fround(p.x + dst.x),
			Math.fround(p.y + dst.y),
			{
				thickness: 2,
				color: FlxColor.WHITE
			}
		);
		this._aim.x = this.x;
		this._aim.y = this.y;

		src.put();
		dst.put();
	}

	private function setDash(elapsed:Float) {
		if (this._lastState == DASHING) {
			this._dashDuration -= elapsed;
			return;
		}

		var p: Point = getRawDirection();
		var speed: Float = DASH_DISTANCE / DASH_TIME;

		GameMath.setNormalizedPoint(this.velocity, p.x, p.y, speed);
		this._dashDuration = DASH_TIME;
	}


	override public function update(elapsed:Float) {
		this._state = this.getNewState();
		if (this._state != PREDASH) {
			FlxG.timeScale = 1.0;
		}

		switch (this._state) {
		case WALK:
			this.setWalkSpeed();
		case PREDASH:
			this.setAim();
		case DASHING:
			this.setDash(elapsed);
		case STAND:
			this.velocity.scale(0);
		default:
			{ /* do nothing */ }
		}

		super.update(elapsed);

		this._lastState = this._state;
	}

	override public function draw() {
		if (this._state == PREDASH) {
			this._aim.draw();

			this._aimBar.value = 1.0 - this._aimPercentage;
			this._aimBar.draw();
		}

		super.draw();
	}
}

