package bloodlust.utils;

import flixel.math.FlxPoint;

class GameMath {

	/**
	 * Normalize the given (x,y) point, scale it by the magnitude
	 * and assign the result to target.
	 *
	 * Note that this guarantees that the Point magnitude will either be
	 * the requested value or zero! The Point 
	 */
	static public function setNormalizedPoint(
		target: FlxPoint,
		x: Float,
		y: Float,
		magnitude: Float
	) {
		if (x == 0 && y == 0) {
			target.scale(0.0);
			return;
		}

		var divisor: Float = Math.sqrt(x*x + y*y);

		target.x = x / divisor;
		target.y = y / divisor;
		target.scale(magnitude);
	}
}
