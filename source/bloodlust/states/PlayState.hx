package bloodlust.states;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxState;

import bloodlust.events.Ifaces;
import bloodlust.events.Type;
import bloodlust.objs.AttackDisc;
import bloodlust.objs.Player;
import bloodlust.ui.PlaystateUi;

class PlayState extends FlxState implements AttackSpawner {

	private var plgUi: PlaystateUi;

	private var _attack: AttackDisc;
	private var _player: Player;

	override public function create() {
		super.create();

		plgUi = FlxG.plugins.get(PlaystateUi);
		plgUi.onEnterPlaystate();

		this._attack = new AttackDisc();
		this.add(this._attack);

		this._player = new Player(this);
		this.add(this._player);
	}

	public function newAttack(
		cx: Float,
		cy: Float,
		dx: Float,
		dy: Float,
		power: Int,
		cb: AttackEvents
	): Float {
		if (this._attack.alive) {
			return -1.0;
		}

		return this._attack.activate(cx, cy, dx, dy, power, this._player);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		FlxG.overlap(this, this, this.onOverlap);
	}

	/**
	 * Retrieve an object's type, if any.
	 */
	static private function getType(obj: FlxObject): Type {
		if (Std.isOfType(obj, IType)) {
			var iface: IType = cast(obj, IType);
			return iface.getType();
		}
		else {
			return UNKNOWN;
		}
	}

	/**
	 * Handle object-specific logic for an object overlapping with another.
	 * If the object doesn't implement any specific collision method,
	 * this is just a slow no-op.
	 */
	static private function handleCollision(self: FlxObject, other: FlxObject) {
		if (!Std.isOfType(self, ProcessCollision)) {
			/* Do nothing, as the object can't collide by itself. */
			return;
		}

		var col: ProcessCollision = cast(self, ProcessCollision);

		var otherType: Type = getType(other);
		col.onTouch(otherType, other);
	}

	/**
	 * Handle collision between objects.
	 */
	private function onOverlap(obj1: FlxObject, obj2: FlxObject): Void {
		handleCollision(obj1, obj2);
		handleCollision(obj2, obj1);
	}

	override public function draw() {
		super.draw();

		plgUi.manualDraw();
	}
}
