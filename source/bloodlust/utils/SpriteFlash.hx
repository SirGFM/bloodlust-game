package bloodlust.utils;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxFrame;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

/**
 * Flash the associated sprite.
 *
 * A sprite that wants to use this object
 * must call 'drawFx()' after its own 'draw()',
 * calling 'startEffect()' to initiate the effect.
 *
 * This effect simply fades from white to transparent in the specified time.
 */
class SpriteFlash extends FlxSprite {

	/** The animation tile on the previous frame. */
	private var _lastFrame: FlxFrame;

	/** The duration of the effect. */
	private var _totalDuration: Float;

	/** The duration of the effect. */
	private var _curDuration: Float;

	public function new() {
		super();

		this._lastFrame = null;
		this._curDuration = 0.0;
	}

	public function startEffect(duration: Float): Void {
		this._curDuration = duration;
		this._totalDuration = duration;
	}

	override public function update(elapsed: Float) {
		super.update(elapsed);

		if (this._curDuration > 0.0) {
			this._curDuration -= elapsed;
			this.alpha = this._curDuration / this._totalDuration;
		}
	}

	public function drawFx(source: FlxSprite): Void {
		if (this._curDuration <= 0.0) {
			return;
		}

		/* Regenerate the flash sprite whenever needed. */
		if (source.frame != this._lastFrame) {
			this.makeGraphic(source.frameWidth, source.frameHeight, FlxColor.WHITE);
			FlxSpriteUtil.alphaMask(this, this.pixels, source.pixels);

			this._lastFrame = source.frame;
		}

		/* Ensure the flash effect is centered. */
		this.width = source.width;
		this.height = source.height;
		this.offset.copyFrom(source.offset);
		this.origin.copyFrom(source.origin);
		this.x = source.x;
		this.y = source.y;

		super.draw();
	}
}
