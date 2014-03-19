package controllers
{
	import flash.display.Sprite;
	
	import util.Context;

	public class Page extends Sprite
	{
		
		public var context:Context;
		public var hasHud:Boolean = false;
		
		public function Page()
		{
			this.context = new Context();
		}
	}
}