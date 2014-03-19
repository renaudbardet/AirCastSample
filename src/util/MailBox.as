package util
{
	import util.f.callback;
	

	public class MailBox
	{
		
		private var stack:Array;
		
		private var typeConstraint:*;
		
		private var _mailAvailable:Signal = new Signal(int, this);
		public function get mailAvailable():Signal { return this._mailAvailable; }
		
		public function MailBox( typeConstraint:* = null )
		{
			
			this.typeConstraint = typeConstraint;
			stack = [];
			
		}
		
		/** hook this to a signal */
		public function listener( data:* ):void
		{
			
			if ( data != null && typeConstraint != null && !(data is typeConstraint) )
				// throw "Bad input, this mailbox is can only accomodate events of type "+typeconstraint;
				return;
			stack.push( data );
			_mailAvailable.dispatch(stack.length, this);
			
		}
		
		/** pop the oldest event from the stack */
		public function readOldest():Option
		{
			
			if(stack.length > 0)
				return Option.Some(stack.pop());
			
			return Option.None;
			
		}
		
		/** remove all the events from the stack and discard all the oldests */
		public function readLatest():Option
		{
			
			if(stack.length > 0)
				return Option.Some(readAll().shift());
			return Option.None;
			
		}
		
		/** return all the events from the stack */
		public function readAll():Array
		{
			
			return stack.splice(0);
			
		}
		
		public function consume( consumer:Function ):Future
		{
			
			var consumed:Future = Future.completed();
			for each ( var event:* in readAll() )
			{
				function scope(event:*):void {
					consumed = consumed.chain( callback( consumer, event) );
				}
				scope( event );
			}
			
			return consumed;
			
		}
		
	}
}