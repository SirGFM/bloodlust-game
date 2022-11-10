package bloodlust.events;

/**
 * Callbacks related to attacking, so projectiles may report back to the player what happened.
 */
interface AttackEvents {
	/**
	 * Callback called whenever an attack hits something.
	 */
	public function didAttack(): Void;

	/**
	 * Callback called whenever an attack wasn't recovered in time.
	 */
	public function attackRecoverTimeout(): Void;

	/**
	 * Callback called as soon as an attack is recovered.
	 */
	public function onRecover(): Void;
}

/**
 * Handles spawning attacks.
 */
interface AttackSpawner {
	/**
	 * Generate a new attack centered at (cx, cy)
	 * and moving in the direction (dx, dy),
	 * which must be between -1.0 and 1.0.
	 * power dictates how big the attack is,
	 * but it's also inversely proportional to the attack's:
	 *   - distance,
	 *   - speed,
	 *   - re-grab radius.
	 *
	 * newAttack returns for how long the attack will be active,
	 * or a negative number if the attack can't be spawned.
	 */
	public function newAttack(
		cx: Float,
		cy: Float,
		dx: Float,
		dy: Float,
		power: Int,
		cb: AttackEvents
	): Float;
}
