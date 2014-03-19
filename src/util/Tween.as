package util
{

	public class Tween extends Progressor
	{
		
		public static var juggler:Signal;
		
		private var updateFct:Function;
		private var time:Number;
		private var duration:Number;
		private var ctx:Context;
		
		public function Tween(ctx:Context, duration:Number, updateFct:Function)
		{
			super();
			autoComplete = true;
			this.ctx = ctx;
			this.duration = duration;
			this.updateFct = updateFct;
			this.time = 0;
			ctx.registerCleaner(abort);
		}
		
		public function play():void
		{
			// ctx is null once completed
			if(ctx == null) return;
			if(juggler == null)
				throw "no juggler";
			ctx.registerSignal(juggler, update);
		}
		
		public function pause():void
		{
			if(ctx == null) return;
			ctx.unregisterSignal(juggler, update);
		}
		
		private function abort():void
		{
			_fail("context closed before tween ended");
		}
		
		private function update(dt:Number):void
		{
			time += dt;
			if(time > duration) time=duration;
			_updateProgress(time/duration)
		}
		
		override protected function _updateProgress(prog:Number):void
		{
			updateFct(prog);
			super._updateProgress(prog);
		}
		
		override protected function _completeEither(res:Either):void
		{
			pause();
			ctx=null;
			super._completeEither(res);
		}	
		
		public static function tweenProperty(ctx:Context, object:Object, prop:String, from:Number, to:Number, duration:Number, ease:Function=null):Tween
		{
			
			var t:Tween = new Tween(
				ctx,
				duration,
				function(prog:Number):void{
					if(ease!=null)
						prog = ease(prog);
					object[prop] = from + (to - from)*prog;
				});
			t.play();
			return t;
			
		}
		
		public static function makeElasticEase(rebounds:Number):Function
		{
			return function elasticEase(prog:Number):Number {
				return Math.cos(prog*((2*rebounds+1)*Math.PI))*(Math.sqrt(prog)-1)+1; 
			};
		}
		
	}
}