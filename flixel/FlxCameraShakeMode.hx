package flixel;

/**
 * Camera shaking modes.
 * 
 * Abstracted from an Int type for fast comparrison code:
 * http://nadako.tumblr.com/post/64707798715/cool-feature-of-upcoming-haxe-3-2-enum-abstracts
 */
 @:enum
 abstract FlxCameraShakeMode(Int)
 {
    /**
     * Shake camera on both the X and Y axes.
     */
    var SHAKE_BOTH_AXES         = 0;
    /**
     * Shake camera on the X axis only.
     */
    var SHAKE_HORIZONTAL_ONLY   = 1;
    /**
     * Shake camera on the Y axis only.
     */
    var SHAKE_VERTICAL_ONLY     = 2;

}
