package bloodlust.objs;

import flixel.FlxObject;
import flixel.tile.FlxTile;

import bloodlust.events.Type;
import bloodlust.utils.Constants;

/**
 * The grass tile, which should be destroyed in every stage.
 * This is just a wrapper for a tile so the grass may have circle collision.
 */
class Grass extends FlxObject implements CircleCollider {
	override public function new(x: Float, y: Float) {
		super(x, y, Constants.TILE_SIZE, Constants.TILE_SIZE);
	}

	public function radius(): Float {
		return Constants.TILE_SIZE / 2;
	}

	/** Whether the given tile represents a grass tile. */
	static public function isGrass(tile: FlxTile): Bool {
		return tile.index == 1;
	}

	/** Mown the given grass tile. */
	static public function mown(tile: FlxTile): Void {
		tile.tilemap.setTileByIndex(tile.mapIndex, 0);
	}
}
