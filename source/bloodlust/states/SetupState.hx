package bloodlust.states;

import flixel.FlxG;
import flixel.FlxState;

/**
 * SetupState is the first state to be executed after Flixel has finished
 * initializing. It may be used to load Plugins and other singletons.
 */
class SetupState extends FlxState {
	override public function create() {
		super.create();

		FlxG.switchState(new PlayState());
	}
}
