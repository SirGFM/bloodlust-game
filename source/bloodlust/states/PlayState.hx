package bloodlust.states;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxState;

import bloodlust.events.Type;
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
