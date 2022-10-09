package bloodlust.ui;

import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.ui.FlxBar;

class PlaystateUi extends FlxGroup {

	static inline private var AIM_BAR_HEIGHT: Int = 16;
	static inline private var AIM_BAR_OFFSET: Int = 2;
	static inline private var AIM_BAR_BORDER: Int = 4;
	static inline private var BAR_COLOR_BORDER: Int = 0xffd95763;
	static inline private var BAR_COLOR_EMPTY: Int = 0xff45283c;
	static inline private var BAR_COLOR_FILL: Int = 0xffac3232;

	/** The bar displaying the dash-window,
	 * after which the dash is simply canceled. */
	private var _aimBar: FlxBar;

	override public function new() {
		super();

		this._aimBar = new FlxBar(
			AIM_BAR_OFFSET + AIM_BAR_BORDER,
			FlxG.height - AIM_BAR_HEIGHT - AIM_BAR_OFFSET - AIM_BAR_BORDER,
			LEFT_TO_RIGHT,
			FlxG.width - 2 * (AIM_BAR_OFFSET + AIM_BAR_BORDER),
			AIM_BAR_HEIGHT,
			null,
			"",
			0.0,
			1.0,
			true
		);

		this.add(this._aimBar);
	}

	/**
	 * Manually recreate assets after a state transition.
	 *
	 * HaxeFlixel seems to unload every generated sprite on state transition,
	 * thus, the bar (and any thing else on the UI) must be manually recreated.
	 * Failure to call this when entering the Playstate will cause a
	 * segmentation fault!
	 */
	public function onEnterPlaystate() {
		this._aimBar.createFilledBar(
			BAR_COLOR_EMPTY,
			BAR_COLOR_FILL,
			true,
			BAR_COLOR_BORDER
		);
		this.hideAimBar();

		this.revive();
	}

	public function showAimBar() {
		this._aimBar.value = 1.0;
		this._aimBar.revive();
	}

	public function hideAimBar() {
		this._aimBar.kill();
	}

	/**
	 * Set the percentage of the aim bar that is EMPTY.
	 *
	 * The bar starts full (when value is 0.0)
	 * and is emptied right-to-left (when value is 1.0).
	 */
	public function setAimBar(value: Float) {
		if (!this._aimBar.alive) {
			this.showAimBar();
		}
		this._aimBar.value = 1.0 - value;
	}

	/**
	 * For whatever reason, differently from Flixel,
	 * HaxelFlixel renders plugins before the actual state.
	 *
	 * Override the plugin's draw so it does nothing,
	 * allowing the plugin to be manually rendered in the correct order.
	 */
	override public function draw() {
		return;
	}

	/**
	 * Manually draw the plugin in the desired order.
	 */
	public function manualDraw() {
		super.draw();
	}
}
