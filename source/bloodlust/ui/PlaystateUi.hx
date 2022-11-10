package bloodlust.ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

import bloodlust.utils.GameMath;

/**
 * UI, active while in the playstate.
 *
 * A global, easy to access object for displaying various UI elements.
 * It's guaranteed to be rendered on top of every other state element.
 */
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

	static inline private var AIM_SPRITE_SIZE: Int = 64;
	static inline private var AIM_SPRITE_START: Float = AIM_SPRITE_SIZE * 2 / 8;
	static inline private var AIM_SPRITE_END: Float = AIM_SPRITE_SIZE * 3 / 8;

	/** The aim that stays over the player,
	 * indicating where they are dashing toward. */
	private var _aim: FlxSprite;

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

		this._aim = new FlxSprite();
		this.add(this._aim);
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

		this._aim.makeGraphic(AIM_SPRITE_SIZE, AIM_SPRITE_SIZE, 0, true);

		this.revive();
		this.hideAimBar();
		this.hideAim();
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
	 * Configure the aim's dimensions, so it's properly centered to the player.
	 */
	public function centerAimToPlayer(width: Float, height: Float) {
		this._aim.width = width;
		this._aim.height = height;
		this._aim.centerOffsets();
	}

	public function showAim() {
		this._aim.revive();
	}

	public function hideAim() {
		this._aim.kill();
	}

	/**
	 * Draw the aim at the player's (x, y) position,
	 * pointing in the (dx, dy) direction.
	 *
	 * dx and dy must be a number between -1.0 and 1.0.
	 */
	public function configureAim(x: Float, y: Float, dx: Float, dy: Float) {
		var src: FlxPoint;
		var dst: FlxPoint;

		if (!this._aim.alive) {
			this.showAim();
		}

		src = FlxPoint.get();
		dst = FlxPoint.get();
		GameMath.setNormalizedPoint(src, dx, dy, AIM_SPRITE_START);
		GameMath.setNormalizedPoint(dst, dx, dy, AIM_SPRITE_END);

		dx = this._aim.frameWidth * 0.5;
		dy = this._aim.frameHeight * 0.5;

		FlxSpriteUtil.fill(this._aim, 0);

		/* Draw a small black outline around the aim. */
		FlxSpriteUtil.drawLine(
			this._aim,
			Math.fround(dx + src.x),
			Math.fround(dy + src.y),
			Math.fround(dx + dst.x),
			Math.fround(dy + dst.y),
			{
				thickness: 3,
				color: FlxColor.BLACK
			}
		);
		FlxSpriteUtil.drawLine(
			this._aim,
			Math.fround(dx + src.x),
			Math.fround(dy + src.y),
			Math.fround(dx + dst.x),
			Math.fround(dy + dst.y),
			{
				thickness: 2,
				color: FlxColor.WHITE
			}
		);
		this._aim.x = x;
		this._aim.y = y;

		src.put();
		dst.put();
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
