/**
* FlxMath
* -- Part of the Flixel Power Tools set
* 
* v1.7 Added mouseInFlxRect
* v1.6 Added wrapAngle, angleLimit and more documentation
* v1.5 Added pointInCoordinates, pointInFlxRect and pointInRectangle
* v1.4 Updated for the Flixel 2.5 Plugin system
* 
* @version 1.7 - June 28th 2011
* @link http://www.photonstorm.com
* @author Richard Davey / Photon Storm
*/

package org.flixel.plugin.photonstorm;

import flash.geom.Rectangle;
import org.flixel.FlxG;
import org.flixel.util.FlxMisc;
import org.flixel.util.FlxRect;

/**
 * Adds a set of fast Math functions and extends a few commonly used ones
 */
class FlxPTMath
{	
	private static var cosTable:Array<Float> = new Array<Float>();
	private static var sinTable:Array<Float> = new Array<Float>();
	
	private static var coefficient1:Float = Math.PI / 4;
	private static var RADTODEG:Float = 180 / Math.PI;
	private static var DEGTORAD:Float = Math.PI / 180;
	
	/**
	 * A faster (but much less accurate) version of Math.atan2(). For close range / loose comparisons this works very well, 
	 * but avoid for long-distance or high accuracy simulations.
	 * Based on: http://blog.gamingyourway.com/PermaLink,guid,78341247-3344-4a7a-acb2-c742742edbb1.aspx
	 * <p>
	 * Computes and returns the angle of the point y/x in radians, when measured counterclockwise from a circle's x axis 
	 * (where 0,0 represents the center of the circle). The return value is between positive pi and negative pi. 
	 * Note that the first parameter to atan2 is always the y coordinate.
	 * </p>
	 * @param y The y coordinate of the point
	 * @param x The x coordinate of the point
	 * @return The angle of the point x/y in radians
	 */
	public static function atan2(y:Float, x:Float):Float
	{
		var absY:Float = y;
		var coefficient2:Float = 3 * coefficient1;
		var r:Float;
		var angle:Float;
		
		if (absY < 0)
		{
			absY = -absY;
		}

		if (x >= 0)
		{
			r = (x - absY) / (x + absY);
			angle = coefficient1 - coefficient1 * r;
		}
		else
		{
			r = (x + absY) / (absY - x);
			angle = coefficient2 - coefficient1 * r;
		}

		return y < 0 ? -angle : angle;
	}
	
	/**
	 * Generate a sine and cosine table simultaneously and extremely quickly. Based on research by Franky of scene.at
	 * <p>
	 * The parameters allow you to specify the length, amplitude and frequency of the wave. Once you have called this function
	 * you should get the results via getSinTable() and getCosTable(). This generator is fast enough to be used in real-time.
	 * </p>
	 * @param length 		The length of the wave
	 * @param sinAmplitude 	The amplitude to apply to the sine table (default 1.0) if you need values between say -+ 125 then give 125 as the value
	 * @param cosAmplitude 	The amplitude to apply to the cosine table (default 1.0) if you need values between say -+ 125 then give 125 as the value
	 * @param frequency 	The frequency of the sine and cosine table data
	 * @return	Returns the sine table
	 * @see getSinTable
	 * @see getCosTable
	 */
	public static function sinCosGenerator(length:Int, sinAmplitude:Float = 1.0, cosAmplitude:Float = 1.0, frequency:Float = 1.0):Array<Float>
	{
		var sin:Float = sinAmplitude;
		var cos:Float = cosAmplitude;
		var frq:Float = frequency * Math.PI / length;
		
		cosTable = new Array();
		sinTable = new Array();
		
		for (c in 0...length)
		{
			cos -= sin * frq;
			sin += cos * frq;
			
			cosTable[c] = cos;
			sinTable[c] = sin;
		}
		
		return sinTable;
	}
	
	/**
	 * Returns the sine table generated by sinCosGenerator(), or an empty array object if not yet populated
	 * @return Array of sine wave data
	 * @see sinCosGenerator
	 */
	public static inline function getSinTable():Array<Float>
	{
		return sinTable;
	}
	
	/**
	 * Returns the cosine table generated by sinCosGenerator(), or an empty array object if not yet populated
	 * @return Array of cosine wave data
	 * @see sinCosGenerator
	 */
	public static inline function getCosTable():Array<Float>
	{
		return cosTable;
	}
	
	/**
	 * Adds the given amount to the value, but never lets the value go over the specified maximum
	 * 
	 * @param value The value to add the amount to
	 * @param amount The amount to add to the value
	 * @param max The maximum the value is allowed to be
	 * @return The new value
	 */
	public static function maxAdd(value:Int, amount:Int, max:Int):Int
	{
		value += amount;
		
		if (value > max)
		{
			value = max;
		}
		
		return value;
	}
	
	/**
	 * Adds value to amount and ensures that the result always stays between 0 and max, by wrapping the value around.
	 * <p>Values must be positive integers, and are passed through Math.abs</p>
	 * 
	 * @param value The value to add the amount to
	 * @param amount The amount to add to the value
	 * @param max The maximum the value is allowed to be
	 * @return The wrapped value
	 */
	public static function wrapValue(value:Int, amount:Int, max:Int):Int
	{
		var diff:Int;

		value = Std.int(Math.abs(value));
		amount = Std.int(Math.abs(amount));
		max = Std.int(Math.abs(max));
		
		diff = (value + amount) % max;
		
		return diff;
	}
	
	/**
	 * Finds the dot product value of two vectors
	 * 
	 * @param	ax		Vector X
	 * @param	ay		Vector Y
	 * @param	bx		Vector X
	 * @param	by		Vector Y
	 * 
	 * @return	Dot product
	 */
	public static inline function dotProduct(ax:Float, ay:Float, bx:Float, by:Float):Float
	{
		return ax * bx + ay * by;
	}
	
	/**
	 * Keeps an angle value between -180 and +180<br>
	 * Should be called whenever the angle is updated on the FlxSprite to stop it from going insane.
	 * 
	 * @param	angle	The angle value to check
	 * 
	 * @return	The new angle value, returns the same as the input angle if it was within bounds
	 */
	public static function wrapAngle(angle:Float):Int
	{
		var result:Int = Std.int(angle);
		
		if (angle > 180)
		{
			result = -180;
		}
		else if (angle < -180)
		{
			result = 180;
		}
		
		return result;
	}
	
	/**
	 * Keeps an angle value between the given min and max values
	 * 
	 * @param	angle	The angle value to check. Must be between -180 and +180
	 * @param	min		The minimum angle that is allowed (must be -180 or greater)
	 * @param	max		The maximum angle that is allowed (must be 180 or less)
	 * 
	 * @return	The new angle value, returns the same as the input angle if it was within bounds
	 */
	public static function angleLimit(angle:Int, min:Int, max:Int):Int
	{
		var result:Int = angle;
		
		if (angle > max)
		{
			result = max;
		}
		else if (angle < min)
		{
			result = min;
		}
		
		return result;
	}
	
	/**
	 * Converts a Radian value into a Degree
	 * <p>
	 * Converts the radians value into degrees and returns
	 * </p>
	 * @param radians The value in radians
	 * @return Number Degrees
	 */
	public static inline function asDegrees(radians:Float):Float
	{
		return radians * RADTODEG;
	}
	
	/**
	 * Converts a Degrees value into a Radian
	 * <p>
	 * Converts the degrees value into radians and returns
	 * </p>
	 * @param degrees The value in degrees
	 * @return Number Radians
	 */
	public static inline function asRadians(degrees:Float):Float
	{
		return degrees * DEGTORAD;
	}
	
}