package util
{
	public class Ui
	{
		private static var _stageWidth:uint;
		private static var _stageHeight:uint;
		
		public static function get stageHeight():uint
		{
			return _stageHeight;
		}

		public static function get stageWidth():uint
		{
			return _stageWidth;
		}

		public static function init( referenceWidth:Number, referenceHeight:Number, screenWidth:uint, screenHeight:uint ):Number
		{
			
			var scaleFitX:Number = screenWidth/referenceWidth;
			var scaleFitY:Number = screenHeight/referenceHeight;
			var scale:Number = Math.min(scaleFitX, scaleFitY);
			var fitUIWidth:Number = screenWidth*scaleFitX/scale;
			var fitUIHeight:Number = screenHeight*scaleFitY/scale;
			_stageWidth = int(screenWidth/scale);
			_stageHeight = int(screenHeight/scale);
			return scale;
			
		}
		
	}
}