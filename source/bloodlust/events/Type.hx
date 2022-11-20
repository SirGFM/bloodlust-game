package bloodlust.events;

import flixel.FlxObject;

/**
 * Enumeration of types in the game (mainly for collision detection).
 */
enum Type {
	UNKNOWN;
	PLAYER;
	ATTACK_DISC;
	TILE;
	WALL;
}

/**
 * Report the object's in-game type.
 */
interface IType {
	/**
	 * Retrieve the object's type (used for game logic).
	 */
	public function getType(): Type;
}

/**
 * Events for handling collision.
 */
interface ProcessCollision {
	/**
	 * Event executed whenever this object touches another IType.
	 */
	public function onTouch(type: Type, other: FlxObject): Void;
}

/**
 * Define the object as being a circle, for collision detection.
 */
interface CircleCollider {
	/**
	 * Retrieve the object's radius, for collision detection.
	 */
	public function radius(): Float;
}

/**
 * Detect the exact direction of a collision before separating the object.
 */
interface SeparateOnDirection {
	/**
	 * Detect the exact direction of a collision before separating the object.
	 * This is guaranteed to be called before separating the object.
	 */
	public function detectCollisionDirection(other: FlxObject): Void;
}
