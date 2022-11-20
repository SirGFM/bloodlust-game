package bloodlust.states;

import haxe.io.Eof;
import sys.io.File;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.tile.FlxTilemap;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

import bloodlust.events.Ifaces;
import bloodlust.events.Type;
import bloodlust.objs.AttackDisc;
import bloodlust.objs.Player;
import bloodlust.ui.PlaystateUi;
import bloodlust.utils.Constants;

/**
 * The main game state.
 *
 * This state is responsible for loading the correct stage,
 * manage whether or not the player is alive, etc.
 */
class PlayState extends FlxState implements AttackSpawner {

	private var plgUi: PlaystateUi;

	private var _attack: AttackDisc;
	private var _player: Player;

	/** Temporary sprite atlas for the grass tilemap. */
	private var _tmpAtlas: FlxSprite;

	/** The grass tilemap; handles collision separately from everything else,
	 * so it may more easily collide with the attack. */
	private var _grass: FlxTilemap;

	/** Width of the current stage. */
	private var _width: Int;

	/** Height of the current stage. */
	private var _height: Int;

	override public function create() {
		super.create();

		plgUi = FlxG.plugins.get(PlaystateUi);
		plgUi.onEnterPlaystate();

		this._attack = new AttackDisc();
		this._player = new Player(this);

		/* Parse the data from the current level. */
		var data = new Array<Int>();

		/* TODO: Change which level is being loaded. */
		var fp = File.read(AssetPaths.level_0__txt, true);
		var y: Int = 0;
		var x: Int = 0;
		this._width = 0;

		var readLevel: Bool = true;
		while (!fp.eof() && readLevel) {
			x = 0;

			var readline: Bool = true;
			while (!fp.eof() && readline) {
				var posX: Int = Constants.TILE_SIZE * x;
				var posY: Int = Constants.TILE_SIZE * y;
				var b: Int;

				/* There doesn't seem to be any way to check
				 * if the file has ended other than
				 * trying to read it and catching the exception... */
				try {
					b = fp.readByte();
				} catch (_: Eof) {
					readline = false;
					readLevel = false;
					break;
				}

				switch (b) {
				case "\n".code:
					readline = false;
					break;
				case "w".code:
					data.push(1);
				case "p".code:
					data.push(0);
					/* TODO: Adjust the player's initial position. */
					this._player.x = posX + 8;
					this._player.y = posY + 8;
				case ".".code:
					data.push(0);
				case "-".code:
					readLevel = false;
					break;
				}
				x++;
			}

			if (this._width == 0) {
				this._width = x;
			}
			else if (this._width != x && !(fp.eof() && x == 0)) {
				throw new haxe.Exception('Inconsistent line length at line $y: want ${this._width}, got $x');
			}

			if (readLevel) {
				y++;
			}
		}

		/* Create a temporary atlas for the tilemap. */
		this._tmpAtlas = new FlxSprite();
		this._tmpAtlas.makeGraphic(
			Constants.TILE_SIZE * 2, /* width */
			Constants.TILE_SIZE /* height */
		);
		FlxSpriteUtil.drawRect(
			this._tmpAtlas,
			0, /* x */
			0, /* y */
			Constants.TILE_SIZE * 2, /* width */
			Constants.TILE_SIZE, /* height */
			FlxColor.BROWN
		);
		FlxSpriteUtil.drawCircle(
			this._tmpAtlas,
			Constants.TILE_SIZE * 1.5, /* x */
			Constants.TILE_SIZE * 0.5, /* y */
			Constants.TILE_SIZE * 0.5, /* radius */
			FlxColor.GREEN
		);

		/* Load the grass from the parsed data. */
		this._grass = new FlxTilemap();
		this._grass.loadMapFromArray(
			data,
			this._width,
			y,
			this._tmpAtlas.graphic,
			Constants.TILE_SIZE,
			Constants.TILE_SIZE,
			null,
			0,
			0
		);
		this._grass.setTileProperties(1, ANY, onOverlap, 1);
		this.add(this._grass);
		this._grass.solid = false;

		this.add(this._attack);
		this.add(this._player);

		/* Configure the level's dimensions. */
		this._width *= Constants.TILE_SIZE;
		this._height = y * Constants.TILE_SIZE;
	}

	public function newAttack(
		cx: Float,
		cy: Float,
		dx: Float,
		dy: Float,
		power: Int,
		cb: AttackEvents
	): Float {
		if (this._attack.alive) {
			return -1.0;
		}

		return this._attack.activate(cx, cy, dx, dy, power, this._player);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		FlxG.overlap(this, this, onOverlap, checkCircle);
	}

	/**
	 * Retrieve an object's type, if any.
	 */
	static private function getType(obj: FlxObject): Type {
		if (Std.isOfType(obj, IType)) {
			var iface: IType = cast(obj, IType);
			return iface.getType();
		}
		else {
			return UNKNOWN;
		}
	}

	/**
	 * Handle object-specific logic for an object overlapping with another.
	 * If the object doesn't implement any specific collision method,
	 * this is just a slow no-op.
	 */
	static private function handleCollision(self: FlxObject, other: FlxObject) {
		if (!Std.isOfType(self, ProcessCollision)) {
			/* Do nothing, as the object can't collide by itself. */
			return;
		}

		var col: ProcessCollision = cast(self, ProcessCollision);

		var otherType: Type = getType(other);
		col.onTouch(otherType, other);
	}

	/**
	 * Handle collision between objects.
	 */
	static private function onOverlap(obj1: FlxObject, obj2: FlxObject): Void {
		handleCollision(obj1, obj2);
		handleCollision(obj2, obj1);
	}

	/**
	 * If the objects are circles, check that the circles are overlapping.
	 * Otherwise, simply separate the hitboxes.
	 */
	static private function checkCircle(obj1: FlxObject, obj2: FlxObject): Bool {
		if (
			!Std.isOfType(obj1, CircleCollider) ||
			!Std.isOfType(obj2, CircleCollider)
		) {
			/* Separate the objects, whatever they are. */
			return FlxObject.separate(obj1, obj2);
		}

		var col1: CircleCollider = cast(obj1, CircleCollider);
		var col2: CircleCollider = cast(obj2, CircleCollider);

		var dx = (obj1.x + obj1.width / 2) - (obj2.x + obj2.width / 2);
		var dy = (obj1.y + obj1.height / 2) - (obj2.y + obj2.height / 2);
		var dist = col1.radius() + col2.radius();

		return (dx * dx + dy * dy) < (dist * dist);
	}

	override public function draw() {
		super.draw();

		plgUi.manualDraw();
	}
}
