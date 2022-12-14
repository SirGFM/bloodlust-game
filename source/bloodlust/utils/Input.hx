package bloodlust.utils;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.input.FlxInput.FlxInputState;
import flixel.input.keyboard.FlxKey;

/**
 * Action define the available actions (e.g., moving left, jumping etc)
 * that may be configured on Input.
 */
enum Action {
	LEFT;
	RIGHT;
	UP;
	DOWN;
	ATTACK;
	DASH;
}

/**
 * Input abstracts input remapping and reading inputs from multiple
 * sources.
 *
 * Each input must be enumerated as an Action, and must have a list of
 * associated inputs (keys, gamepad buttons, etc).
 */
class Input extends FlxBasic {

	private var _left:Array<FlxKey> = [FlxKey.A, FlxKey.LEFT];
	private var _right:Array<FlxKey> = [FlxKey.D, FlxKey.RIGHT];
	private var _up:Array<FlxKey> = [FlxKey.W, FlxKey.UP];
	private var _down:Array<FlxKey> = [FlxKey.S, FlxKey.DOWN];
	private var _attack:Array<FlxKey> = [FlxKey.X, FlxKey.J];
	private var _dash:Array<FlxKey> = [FlxKey.C, FlxKey.K];

	private var _actionKey:Map<Action, Array<FlxKey>>;

	override public function new() {
		super();

		this._actionKey = [
			LEFT => this._left,
			RIGHT => this._right,
			UP => this._up,
			DOWN => this._down,
			ATTACK => this._attack,
			DASH => this._dash,
		];
	}

	/**
	 * Retrieve if a given action is in a given state.
	 */
	public function get(action: Action, state: FlxInputState):Bool {
		switch (state) {
		case JUST_PRESSED:
			return FlxG.keys.anyJustPressed(this._actionKey[action]);
		case JUST_RELEASED:
			return FlxG.keys.anyJustReleased(this._actionKey[action]);
		case PRESSED:
			return FlxG.keys.anyPressed(this._actionKey[action]);
		case RELEASED:
			return !FlxG.keys.anyPressed(this._actionKey[action]);
		}
	}

	/**
	 * Retrieve whether any of the given actions is in a given state.
	 */
	public function getAny(actions: Array<Action>, state: FlxInputState):Bool {
		if (state == RELEASED) {
			return !getAny(actions, PRESSED);
		}

		for (action in actions) {
			if (this.get(action, state)) {
				return true;
			}
		}

		return false;
	}
}
