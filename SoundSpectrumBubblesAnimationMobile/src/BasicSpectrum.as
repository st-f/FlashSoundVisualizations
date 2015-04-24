package {
	
	import com.greensock.TweenMax;
	
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.SampleDataEvent;
	import flash.events.TimerEvent;
	import flash.events.TransformGestureEvent;
	import flash.media.Microphone;
	import flash.media.Sound;
	import flash.media.SoundMixer;
	import flash.media.SoundTransform;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	/**
	 * Simple Microphone test for Flash Player 10.1
	 * @author Devon O.
	 */
	
	[SWF(width='550', height='450', backgroundColor='#000000', frameRate='60')]
	public class BasicSpectrum extends Sprite {
		
		// sound
		protected static const LINES:int = 128;
		protected var animationSpeed:int = 120;
		private var _soundBytes:ByteArray = new ByteArray();
		private var _micBytes:ByteArray;
		private var _micSound:Sound;
		private var _lines:Vector.<Shape> = new Vector.<Shape>(LINES, true);
		protected var timer:Timer;
		private var _ctr:int;
		
		protected var useTimer:Boolean = false;
		
		public function BasicSpectrum() 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(event:Event = null):void 
		{
			initEqualizer();
			timer = new Timer(animationSpeed);
			timer.addEventListener(TimerEvent.TIMER, animate, false, 0);
			this.addEventListener(TransformGestureEvent.GESTURE_SWIPE, handleSwipe, false, 0, true);
			trace("init");
			init2();
		}
		
		protected var swipeNumber:int = 0;
		
		protected function handleSwipe(event:TransformGestureEvent):void
		{
			switch(swipeNumber)
			{
				case 0:
				{
					useTimer = true;
					timer.stop();
					timer.delay = animationSpeed;
					timer.start();
					useTimer = true;
					break;
				}
				case 1:
				{
					useTimer = true;
					timer.stop();
					timer.delay = animationSpeed * 2;
					timer.start();
					break;
				}
				case 2:
				{
					useTimer = true;
					timer.stop();
					timer.delay = animationSpeed * 4;
					timer.start();
					break;
				}
				case 3:
				{
					useTimer = false;
					timer.stop();	
					break;
				}
			}
			(swipeNumber > 3) ? swipeNumber = 0 : swipeNumber++;
		}
		
		protected function init2():void
		{
			var mic:Microphone = Microphone.getMicrophone(); 
			mic.setSilenceLevel(0, 4000); 
			mic.rate = 44;
			mic.gain = 100;
			mic.addEventListener(SampleDataEvent.SAMPLE_DATA, micSampleDataHandler);
		}
		
		protected var sample:Number;
		protected var readNumber:Number;
		
		protected function micSampleDataHandler(event:SampleDataEvent):void 
		{ 
			var total:Number = 0;
			var i:int = 0;
			_soundBytes = new ByteArray();
			while(event.data.bytesAvailable)    
			{ 
				if(i >= LINES-1) 
				{
					//trace("average: "+total/LINES);
					i = 0;
					return;
				}
				sample = event.data.readFloat();
				_soundBytes.writeFloat(sample);
				_soundBytes.writeFloat(sample);
				//_lines[i].scaleY = sample;
				//trace("useTimer: "+useTimer);
				if(useTimer == false) animateLine(_lines[i], sample, 0);
				total += sample;
				i++;
			}
			//_soundBytes = event.data;
		}
		
		
		protected function animate(event:TimerEvent):void
		{
			if(_soundBytes.length < LINES) return;
			_soundBytes.position = 0;
			TweenMax.killAll();
			//trace("animate: "+_soundBytes.length);
			for (var i:int = 0; i < LINES; i++)
			{
				readNumber = _soundBytes.readFloat();
				animateLine(_lines[i], readNumber);
			}
		}
		
		protected function animateLine(line:Shape, dest:Number, speed:int = -1):void
		{
			var _speed:Number;
			if(speed == -1)
			{
				_speed = timer.delay/1000;
			}
			else
			{
				_speed = speed;
			}
			var colorR:uint = 0xFF0000;
			var colorG:uint = 0x00FF00;
			var color:uint;
			if(dest > 0)
			{
				color = colorG;
			}
			else
			{
				color = colorR;
			}
			TweenMax.to(line, _speed, {scaleY:dest, tint:color});
		}
		
		private function initEqualizer():void 
		{
			var holder:Sprite = new Sprite();
			for (var i:int = 0; i < LINES; i++) 
			{
				var line:Shape = new Shape();
				with(line.graphics) 
				{
					beginFill(0xFFFFFF);
					drawRect(0, -200, 200/LINES, 200);
					endFill();
				}
				line.x = i * stage.stageWidth/LINES;
				line.scaleY = 0;
				holder.addChild(line);
				_lines[i] = line;
			}
			holder.y = 200;
			holder.x = stage.stageWidth * .5 - holder.width * .5;
			addChild(holder);
		}	
		
	}
}