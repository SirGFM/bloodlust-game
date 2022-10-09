package bloodlust.states;

import flixel.FlxG;
import flixel.FlxState;

import bloodlust.ui.PlaystateUi;
import bloodlust.utils.Input;

/**
 * SetupState is the first state to be executed after Flixel has finished
 * initializing. It may be used to load Plugins and other singletons.
 */
class SetupState extends FlxState {
	override public function create() {
		super.create();

		FlxG.plugins.add(new Input());
		FlxG.plugins.add(new PlaystateUi());

		FlxG.switchState(new PlayState());
	}
}
