package bloodlust.events;

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
