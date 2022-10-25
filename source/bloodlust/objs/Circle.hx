package bloodlust.objs;

import flixel.FlxSprite;

import bloodlust.events.Type;

class Circle extends FlxSprite implements CircleCollider {
	private var _radius: Float;

	override public function new(radius: Float) {
		super();
		this.setRadius(radius);
	}

	public function radius(): Float {
		return this._radius;
	}

	private function setRadius(radius: Float): Void {
		this._radius = radius;
	}
}
