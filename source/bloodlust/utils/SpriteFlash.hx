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

	/** Color of the flashing effect. */
	private var _flashColor: FlxColor;

	/** The baseline alpha factor of the effect. */
	private var _baseAlpha: Float;

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

	public function startEffect(
		duration: Float,
		color: FlxColor = FlxColor.WHITE
	): Void {
		this._curDuration = duration;
		this._totalDuration = duration;

		/* Color isn't an unsigned value...
		 * So trying to extract the 8 higher bits
		 * could lead to negative numbers in some platforms. */
		this._baseAlpha = (0xff & (color >> 24)) / 255.0;
		this._flashColor = (color | 0xFF000000);
	}

	override public function update(elapsed: Float) {
		super.update(elapsed);

		if (this._curDuration > 0.0) {
			this._curDuration -= elapsed;

			var dt: Float = this._curDuration / this._totalDuration;
			this.alpha = this._baseAlpha * dt;
		}
	}

	public function drawFx(source: FlxSprite): Void {
		if (this._curDuration <= 0.0) {
			return;
		}

		/* Regenerate the flash sprite whenever needed. */
		if (source.frame != this._lastFrame) {
			this.makeGraphic(source.frameWidth, source.frameHeight, this._flashColor);
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
