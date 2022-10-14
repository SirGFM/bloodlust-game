package bloodlust.events;

import flixel.FlxObject;

enum Type {
	UNKNOWN;
	PLAYER;
	ATTACK_DISC;
}

interface IType {
	/**
	 * Retrieve the object's type (used for game logic).
	 */
	public function getType(): Type;
}

interface ProcessCollision {
	/**
	 * Event executed whenever this object touches another IType.
	 */
	public function onTouch(type: Type, other: FlxObject): Void;
}
