package util
{
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	public class Context
	{
		
		private static const PAUSED_BY_SELF:int = 1;
		private static const PAUSED_BY_PARENT:int = 2;
		
		private var parent:Context;
		
		private var eventListeners:Dictionary; // store target->Object(event->[{listener:Function,useCapture:Boolean,priority:int])
		private var signals:Dictionary; // store target->[{listener:Function,once:Boolean}]
		private var cleaners:Array; // store function():void
		private var pausers:Array;
		private var resumers:Array;
		private var pauseValue:int;
		private function get paused():Boolean { return pauseValue > 0; }
		private var closed:Boolean;
		private var closedFuture:TriggerFuture;
		private var storedCallbacks:Array; // stores a safeCallback call while the context is in pause
		
		public function Context(parent:Context=null)
		{
			eventListeners = new Dictionary();
			signals = new Dictionary();
			cleaners = new Array();
			pausers = new Array();
			resumers = new Array();
			storedCallbacks = new Array();
			
			pauseValue = 0;
			
			if (parent) {
				parent.registerCleaner( close );
				parent.pausers.push(this.pauseFromParent);
				parent.resumers.push(this.resumeFromParent);
				if(parent.paused) pauseFromParent();
			} 
		}
		
		public function registerEventListener(target:EventDispatcher, type:String, listener:Function, useCapture:Boolean=false, priority:int=0):void
		{
			
			if(closed) return;
			
			if(eventListeners[target]==undefined)
				eventListeners[target] = new Object();
			
			if (eventListeners[target][type]==undefined)
				eventListeners[target][type] = new Array();
			
			// flash doesn't reference listeners with same parameters more than once
			if (hasEventListener(target, type, listener, useCapture)) return;
			
			eventListeners[target][type].push({
				'listener':listener,
				'useCapture':useCapture,
				'priority':priority
			});
			
			if(!paused)
				target.addEventListener(type, listener, useCapture, priority, false);
			
		}
		
		public function unregisterEventListener(target:EventDispatcher, type:String, listener:Function, useCapture:Boolean=false):Boolean
		{
			
			if (closed) return false;
			
			if(eventListeners[target]==undefined) return false;
			if(eventListeners[target][type]==undefined) return false;
			var listeners:Array = eventListeners[target][type];
			var index:int = -1;
			for (var i:int=0;i<listeners.length;++i)
			{
				var props:Object = listeners[i];
				if (props.listener == listener && props.useCapture == useCapture)
				{
					index = i;
					break;
				}
			}
			if(index<0) return false;
			listeners.splice(index,1);
			if(eventListeners[target][type].length==0)
			{
				delete eventListeners[target][type];
				var nbListeners:int=0;
				for(var t:String in eventListeners[target]) ++nbListeners;
				if(nbListeners==0)
					delete eventListeners[target];
			}
			target.removeEventListener(type,listener,useCapture);
			return true;
			
		}
		
		public function unregisterAllListeners(target:EventDispatcher):Boolean
		{
			
			if(closed) return false;
			
			if(eventListeners[target]==undefined) return false;
			for (var type:String in eventListeners[target])
			{
				for each(var props:Object in eventListeners[target][type])
				EventDispatcher(target).removeEventListener(type,props.listener,props.useCapture);
				delete eventListeners[target][type];
			}
			delete eventListeners[target];
			return true;
			
		}
		
		public function hasEventListener(target:EventDispatcher, type:String, listener:Function, useCapture:Boolean=false):Boolean
		{
			
			if(closed) return false;
			
			if(eventListeners[target]==undefined) return false;
			if(eventListeners[target][type]==undefined) return false;
			var listeners:Array = eventListeners[target][type];
			for (var i:int=0;i<listeners.length;++i)
			{
				var props:Object = listeners[i];
				if (props.listener == listener && props.useCapture == useCapture)
					return true;
			}
			return false;
			
		}
		
		public function registerSignal(signal:ISignal, listener:Function, once:Boolean=false):void
		{
			
			if(closed) return;
			
			if(signals[signal]==undefined)
				signals[signal]=new Array();
			
			for each (var slot:Object in signals[signal])
				if(slot.listener == listener)
					return;
			
			slot = {listener:listener, onceListener:once?onceListener(signal, listener):null, once:once};
			signals[signal].push(slot);
			if (!paused)
			{
				if(once)
					signal.add(slot.onceListener, true);
				else
					signal.add(slot.listener);
			}
			
		}
		
		public function unregisterSignal(signal:Signal, listener:Function):Boolean
		{
			
			if(closed) return false;
			
			if(signals[signal]==undefined) return false;
			var index:int = -1;
			for (var i:int=0;i<signals[signal].length;++i)
			{
				var slot:Object = signals[signal][i];
				if (slot.listener == listener){
					signal.remove(slot.once?slot.onceListener:slot.listener);
					index=i;
					break;
				}
			}
			if(index<0) return false;
			signals[signal].splice(i,1);
			if(signals[signal].length==0)
				delete signals[signal];
			return true;
			
		}
		
		public function hasSignal(signal:Signal, listener:Function):Boolean
		{
			
			if(closed) return false;
			
			if(signals[signal]==undefined) return false;
			for each (var slot:Object in signals[signal])
				if (slot.listener == listener)
					return true;
			return false;
			
		}
		
		public function registerCleaner(cleaner:Function):void
		{
			
			if(closed) return;
			
			cleaners.push(cleaner);
			
		}
		
		public function unregisterCleaner(cleaner:Function):Boolean
		{
			
			if (closed) return false;
			
			if(cleaners.indexOf(cleaner)<0) return false;
			cleaners.splice(cleaners.indexOf(cleaner),1);
			return true;
			
		}
		
		public function registerPauser(pauser:Function):void
		{
			
			if(closed) return;
			
			pausers.push(pauser);
			
		}
		
		public function registerResumer(resumer:Function):void
		{
			
			if(closed) return;
			
			resumers.push(resumer);
			
		}
		
		public function safeCallback(func:Function):Function
		{
			if ( func.length > 0 )
				return function safeCallbackWithParams( first : * = undefined, ...rest ):* {
					if(closed) return null;
					if ( first != undefined || rest.length > 0 )
						rest = [first].concat(rest);
					if(paused)
					{
						storedCallbacks.push( {func:func,data:rest} );
						return;
					}
					return func.apply( null, rest );
				};
			else
				return function safeCallbackNoParams():* {
					if(closed) return null;
					if(paused)
					{
						storedCallbacks.push( {func:func,data:[]} );
						return;
					}
					return func.call( null );
				};
		}
		
		public function safeFuture(f:Future):Future
		{
			if(closedFuture == null)
			{
				closedFuture = new TriggerFuture();
				registerCleaner( closedFuture.complete );
			}
			
			return f.unless(closedFuture);
		}
		
		public function pause():void
		{
			
			if (closed) return;
			var alreadyPaused:Boolean = paused;
			pauseValue |= PAUSED_BY_SELF;
			if(!alreadyPaused)
				_pause();
			
		}
		
		private function pauseFromParent():void
		{
			if (closed) return;
			var alreadyPaused:Boolean = paused;
			pauseValue |= PAUSED_BY_PARENT;
			if(!alreadyPaused)
				_pause();
		}
		
		// this method performs the actual pause operation, wether it's from the parent or self
		private function _pause():void
		{
			
			for (var target:* in eventListeners)
				for (var type:String in eventListeners[target])
					for each(var props:Object in eventListeners[target][type])
						EventDispatcher(target).removeEventListener(type,props.listener,props.useCapture);
			
			for (var signal:* in signals)
				for each (var slot:Object in signals[signal])
					signal.remove(slot.once?slot.oncelistener:slot.listener);
			
			for each (var pauser:Function in pausers)
			 	pauser();
			
		}
		
		public function resume():void
		{
			if (closed) return;
			var alreadyActive:Boolean = !paused;
			pauseValue &= ~PAUSED_BY_SELF;
			if(!paused && !alreadyActive)
				_resume();
		}
		
		private function resumeFromParent():void
		{
			if (closed) return;
			var alreadyActive:Boolean = !paused;
			pauseValue &= ~PAUSED_BY_PARENT;
			if(!paused && !alreadyActive)
				_resume();
		}
			
		// this method performs the actual pause operation, wether it's from the parent or self
		private function _resume():void
		{
			
			for (var target:* in eventListeners)
				for (var type:String in eventListeners[target])
					for each(var props:Object in eventListeners[target][type])
						EventDispatcher(target).addEventListener(type,props.listener,props.useCapture,props.priority,false);
			
			for (var signal:* in signals)
				for each (var slot:Object in signals[signal])
					signal.add(slot.once?slot.onceListener:slot.listener, slot.once);
			
			for (var funcCall:Object in storedCallbacks)
				funcCall.func.apply(null, funcCall.data);
			storedCallbacks = [];
			
			for each (var resumer:Function in resumers)
				resumer();
			
		}
		
		public function close():void
		{
			
			if(closed) return;
			closed = true;
			
			if (parent) {
				parent.unregisterCleaner( this.close );
				parent.pausers.splice( parent.pausers.indexOf( this.pauseFromParent ), 1 );
				parent.resumers.splice( parent.resumers.indexOf( this.resumeFromParent ), 1 );
			}
			parent = null;
			
			for (var target:* in eventListeners)
			{
				for (var type:String in eventListeners[target])
				{
					for each(var props:Object in eventListeners[target][type])
					EventDispatcher(target).removeEventListener(type,props.listener,props.useCapture);
					delete eventListeners[target][type];
				}
				delete eventListeners[target];
			}
			eventListeners = null;
			
			for (var signal:ISignal in signals) {
				for each (var slot:Object in signals[signal])
					signal.remove(slot.once?slot.onceListener:slot.listener);
				delete signals[signal];
			}
			signals = null;
			
			for each (var cleaner:Function in cleaners)
				cleaner();
			
			cleaners = null;
			pausers = null;
			resumers = null;
			
			pauseValue = 0;
			
		}
		
		private function onceListener(signal:ISignal, listener:Function):Function
		{
			return function(...data):void{
				if (signals[signal]==undefined) return;
				for (var i:int=0; i<signals[signal].length; ++i){
					var slot:Object = signals[signal][i];
					if(slot.listener==listener)
						break;
				}
				signals[signal].splice(i,1);
				if(signals[signal].length == 0)
					delete signals[signal];
				listener.apply(null,data);
			}
		}
		
	}
}