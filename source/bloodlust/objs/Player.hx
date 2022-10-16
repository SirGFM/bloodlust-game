package bloodlust.objs;

import haxe.Timer;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

import bloodlust.events.Ifaces;
import bloodlust.events.Type;
import bloodlust.ui.PlaystateUi;
import bloodlust.utils.Input;
import bloodlust.utils.GameMath;

private enum PlayerState {
	STAND;
	WALK;
	PREDASH;
	DASHING;
	DASH_ATTACK;
	ATTACK;
	HURT;
}

private typedef Point = {
	x: Float,
	y: Float,
}

class Player extends FlxSprite
	implements AttackEvents
	implements IType
{
	static inline private var SPEED: Float = 175.0;
	static inline private var PLAYER_SIZE: Int = 24;
	static inline private var DASH_DISTANCE: Float = 125.0;
	static inline private var DASH_TIME: Float = 0.3;
	static inline private var BASE_HEALTH: Float = 5.0;

	static inline private var HURT_FLASH_TIME: Float = 0.25;
	static inline private var HURT_DURATION: Float = 1.0;
	static inline private var HURT_INVINCIBILITY: Float = 1.75;

	/* How long may the player take aiming. */
	static inline private var AIM_TIME: Float = 5.0;

	/* Maximum factor by which the time is slowed down. */
	static inline private var AIM_MAX_SLOWDOWN: Float = 0.5;

	/* Percentage of the aim time
	 * during which the timeScale decreases to the maximum slowdown factor,
	 * until it starts increasing again. */
	static inline private var AIM_SLOWDOWN_PERCENTAGE: Float = 0.1;

	private function getTimeScale(percentage: Float): Float {
		var perc: Float;

		if (percentage < AIM_SLOWDOWN_PERCENTAGE) {
			perc = percentage / AIM_SLOWDOWN_PERCENTAGE;
		}
		else {
			perc = percentage - AIM_SLOWDOWN_PERCENTAGE;
			perc /= 1.0 - AIM_SLOWDOWN_PERCENTAGE;
			perc = 1.0 - perc;
		}

		return 1.0 - AIM_MAX_SLOWDOWN * perc;
	}

	private var plgInput: Input;
	private var plgUi: PlaystateUi;

	private var _aimStart: Float;

	private var _cooldown: Float;

	/** Time during which the player is invulnerable. */
	private var _invulnerability: Float;

	private var _lastState: PlayerState;
	private var _state: PlayerState;

	private var _spanwer: AttackSpawner;

	/** Whether the player should be hurt when recovering the attack.
	 * This should be set on dash attack, and cleared if any enemy is hit. */
	private var _hurtOnRecover: Bool;

	override public function new(spawner: AttackSpawner) {
		super();

		this.makeGraphic(PLAYER_SIZE, PLAYER_SIZE, FlxColor.RED);
		this.plgInput = FlxG.plugins.get(Input);
		this.plgUi = FlxG.plugins.get(PlaystateUi);

		this.plgUi.centerAimToPlayer(this.width, this.height);

		this._spanwer = spawner;

		this._state = STAND;
		this._lastState = STAND;

		this.health = BASE_HEALTH;

		this._cooldown = 0.0;
		this._invulnerability = 0.0;
	}

	private function getNewState(): PlayerState {
		switch (this._state) {
		case STAND | WALK:
			if (this.plgInput.get(DASH, JUST_PRESSED)) {
				return PREDASH;
			}
			else if (this.plgInput.getAny([LEFT, RIGHT, UP, DOWN], PRESSED)) {
				if (this.plgInput.get(ATTACK, JUST_PRESSED)) {
					return ATTACK;
				}

				return WALK;
			}

			return STAND;
		case PREDASH:
			/* Forcefully stop dash-aiming after a while.
			 * Since time slows down during the pre-dash,
			 * this cooldown must be implemented manually. */
			if (Timer.stamp() - this._aimStart > AIM_TIME) {
				return STAND;
			}
			else if (this.plgInput.get(DASH, JUST_RELEASED)) {
				return DASHING;
			}

			return PREDASH;
		case state:
			if (this._cooldown <= 0.0) {
				return STAND;
			}
			else if (
				state == DASHING &&
				this.plgInput.get(ATTACK, JUST_PRESSED)
			) {
				return DASH_ATTACK;
			}

			return state;
		}
	}

	private function changeState(): Void {
		switch (this._state) {
		case PREDASH:
			this._aimStart = Timer.stamp();
		case DASHING:
			var p: Point = getRawDirection();
			var speed: Float = DASH_DISTANCE / DASH_TIME;

			GameMath.setNormalizedPoint(this.velocity, p.x, p.y, speed);
			this._cooldown = DASH_TIME;
		case DASH_ATTACK | ATTACK:
			var p: Point = {
				x: 0.0,
				y: 0.0
			};

			if (this._state == ATTACK) {
				var tmp: FlxPoint = FlxPoint.get();

				p = getRawDirection();
				GameMath.setNormalizedPoint(tmp, p.x, p.y, 1.0);
				p.x = tmp.x;
				p.y = tmp.y;

				tmp.put();
			}

			var time: Float = this._spanwer.newAttack(
				this.x + this.width * 0.5,
				this.y + this.height * 0.5,
				p.x,
				p.y,
				Std.int(this.health),
				this
			);

			/* Damage the player if it isn't able to launch a new attack. */
			if (time < 0.0) {
				this.hurt(1.0);
			}
			else if (this._state == DASH_ATTACK) {
				this._hurtOnRecover = true;
				this._cooldown = time;
			}
		default:
			{ /* do nothing */ }
		}

		if (this._state != PREDASH) {
			FlxG.timeScale = 1.0;
			this.plgUi.hideAimBar();
			this.plgUi.hideAim();
		}
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
		var p: Point;
		var percentage: Float;

		var now: Float = Timer.stamp();
		percentage = Math.min(now - this._aimStart, AIM_TIME);
		percentage /= AIM_TIME;
		this.plgUi.setAimBar(percentage);

		FlxG.timeScale = getTimeScale(percentage);

		p = getRawDirection();
		this.plgUi.configureAim(this.x, this.y, p.x, p.y);
	}

	public function didAttack(): Void {
		if (this._state == DASH_ATTACK) {
			this.hurt(-1);
			this._hurtOnRecover = false;
		}
	}

	public function attackRecoverTimeout(): Void {
		this.hurt(1);
	}

	public function onRecover(): Void {
		if (this._hurtOnRecover) {
			this._hurtOnRecover = false;
			this.hurt(1);
		}
	}

	public function getType(): Type {
		return PLAYER;
	}

	override public function update(elapsed:Float) {
		if (this._cooldown > 0) {
			this._cooldown -= elapsed;
		}
		if (this._invulnerability > 0) {
			this._invulnerability -= elapsed;
		}

		this._state = this.getNewState();
		if (this._state != this._lastState) {
			this.changeState();
		}

		switch (this._state) {
		case WALK:
			this.setWalkSpeed();
		case PREDASH:
			this.setAim();
		case STAND | DASH_ATTACK:
			this.velocity.scale(0);
		default:
			{ /* do nothing */ }
		}

		super.update(elapsed);

		this._lastState = this._state;
	}

	override public function draw() {
		/* If the player is invulnerable, flicker it every 0.1s. */
		if (
			this._invulnerability > 0.0 &&
			(Std.int(this._invulnerability * 10) & 0x1) == 0
		) {
			return;
		}

		super.draw();
	}

	override public function hurt(damage: Float) {
		if (this._state == DASHING || this._invulnerability > 0) {
			return;
		}

		super.hurt(damage);
		FlxG.cameras.flash(FlxColor.WHITE, HURT_FLASH_TIME);
		this._state = HURT;
		this._cooldown = HURT_DURATION;
		this._invulnerability = HURT_INVINCIBILITY;
	}
}

