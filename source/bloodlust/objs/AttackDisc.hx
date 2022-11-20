package bloodlust.objs;

import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.tile.FlxTile;
import flixel.util.FlxColor;
import flixel.util.FlxDirectionFlags;

import bloodlust.events.Ifaces;
import bloodlust.events.Type;
import bloodlust.utils.GameMath;

/**
 * List of states the attack may be at.
 */
private enum DiskState {
	FLY;
	FLOAT;
	RECOVER;
}

/**
 * The player's attack.
 */
class AttackDisc extends Circle
	implements IType
	implements ProcessCollision
	implements SeparateOnDirection
{
	static inline private var MIN_POWER: Float = 1.0;
	static inline private var MAX_POWER: Float = 9.0;
	static inline private var MIN_RADIUS: Float = 26.0;
	static inline private var MAX_RADIUS: Float = 64.0;
	static inline private var MIN_DISTANCE: Float = 300.0;
	static inline private var MAX_DISTANCE: Float = 100.0;
	static inline private var MIN_FLIGHTTIME: Float = 1.5;
	static inline private var MAX_FLIGHTTIME: Float = 3.0;
	static inline private var MIN_FLOATTIME: Float = 1.0;
	static inline private var MAX_FLOATTIME: Float = 0.5;
	static inline private var MIN_RECOVERTIME: Float = 2.0;
	static inline private var MAX_RECOVERTIME: Float = 8.0;

	private var _state: DiskState;

	private var _cooldown: Float;

	private var _power: Float;

	private var _callback: AttackEvents;

	private var _level: GrassMower;

	private var _curSpeed: FlxPoint;

	private var _lastestSeparated: FlxDirectionFlags;

	override public function new() {
		super(MIN_RADIUS);

		/* HaxeFlixel overwrites the sprites dimensions on the first draw
		 * unless the graphics were previously initialized... */
		var size: Int = Std.int(MIN_RADIUS) * 2;
		this.makeGraphic(size, size, FlxColor.BLUE);
		this._curSpeed = new FlxPoint();

		this.kill();
	}

	public function getType(): Type {
		return ATTACK_DISC;
	}

	public function detectCollisionDirection(other: FlxObject): Void {
		var oldTouching = this.touching;

		this.touching = NONE;
		FlxObject.updateTouchingFlags(this, other);
		this._lastestSeparated = this.touching;

		this.touching = oldTouching;
	}

	public function onTouch(type: Type, other: FlxObject): Void {
		switch (type) {
		case PLAYER:
			if (this._state == RECOVER) {
				this._callback.onRecover();
				this.kill();
			}
		case TILE:
			var tile = cast(other, FlxTile);

			if (Grass.isGrass(tile)) {
				Grass.mown(tile);
				this._level.grassMown(tile.index);
			}
		case WALL:
			/* Apparently, collision is somewhat buggy and
			 * may incorrectly detect up/down collision when entering an object.
			 * Sideways collision should actually hit both up and down,
			 * which would be detectable and avoidable...
			 *
			 * Since that's not an option,
			 * simply handle only a single direction at a time. */
			if ((this._lastestSeparated & LEFT) != 0) {
				this.velocity.x = Math.abs(this._curSpeed.x);
			}
			else if ((this._lastestSeparated & RIGHT) != 0) {
				this.velocity.x = -Math.abs(this._curSpeed.x);
			}
			else if ((this._lastestSeparated & UP) != 0) {
				this.velocity.y = Math.abs(this._curSpeed.y);
			}
			else if ((this._lastestSeparated & DOWN) != 0) {
				this.velocity.y = -Math.abs(this._curSpeed.y);
			}
		default:
			this._callback.didAttack();

			/* TODO: Damage other entities. */
		}
	}

	/**
	 * Get the power's percentage.
	 */
	static private function getPercentage(power: Float): Float {
		return (power - MIN_POWER) / (MAX_POWER - MIN_POWER);
	}

	/**
	 * Get the disc speed based on the current power.
	 */
	static private function getSpeed(power: Float): Float {
		var percentage: Float = getPercentage(power);

		var dist: Float = GameMath.linear(
			MIN_DISTANCE,
			MAX_DISTANCE,
			percentage
		);
		var flightTime: Float = GameMath.linear(
			MIN_FLIGHTTIME,
			MAX_FLIGHTTIME,
			percentage
		);

		return dist / flightTime;
	}

	/**
	 * Generate a new attack centered at (cx, cy)
	 * and moving in the direction (dx, dy).
	 */
	public function activate(
		cx: Float,
		cy: Float,
		dx: Float,
		dy: Float,
		power: Int,
		cb: AttackEvents,
		level: GrassMower
	): Float {
		this._power = Math.max(power, MIN_POWER);
		this._power = Math.min(this._power, MAX_POWER);

		var percentage: Float = getPercentage(this._power);

		/* Calculate the attack's dimensions. */
		var radius: Float = GameMath.linear(MIN_RADIUS, MAX_RADIUS, percentage);
		this.width = radius * 2.0;
		this.height = radius * 2.0;
		this.setRadius(radius);

		this.x = cx - this.width * 0.5;
		this.y = cy - this.height * 0.5;
		this.centerOffsets();

		var speed: Float = getSpeed(this._power);
		GameMath.setNormalizedPoint(this.velocity, dx, dy, speed);
		this.velocity.copyTo(this._curSpeed);

		this._state = FLY;
		this._cooldown = GameMath.linear(
			MIN_FLIGHTTIME,
			MAX_FLIGHTTIME,
			percentage
		);

		var floatTime: Float = GameMath.linear(
			MIN_FLOATTIME,
			MAX_FLOATTIME,
			percentage
		);

		this._callback = cb;
		this._level = level;

		this.revive();
		return this._cooldown + floatTime;
	}

	private function nextState() {
		var percentage: Float = getPercentage(this._power);

		switch (this._state) {
		case FLY:
			this.velocity.scale(0);
			this._state = FLOAT;
		case FLOAT:
			this._state = RECOVER;
		case RECOVER:
			this._callback.attackRecoverTimeout();

			this._state = RECOVER;
		}

		switch (this._state) {
		case FLY:
			{ /* Won't ever happen. */ }
		case FLOAT:
			this._cooldown = GameMath.linear(
				MIN_FLOATTIME,
				MAX_FLOATTIME,
				percentage
			);
		case RECOVER:
			this._cooldown = GameMath.linear(
				MIN_RECOVERTIME,
				MAX_RECOVERTIME,
				percentage
			);
		}
	}

	override public function update(elapsed: Float) {
		if (this._cooldown > 0) {
			this._cooldown -= elapsed;
		}
		else {
			this.nextState();
		}

		super.update(elapsed);
	}
}
