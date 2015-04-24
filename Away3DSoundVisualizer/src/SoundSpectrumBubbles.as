package
{
	import com.bit101.components.HSlider;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.SampleDataEvent;
	import flash.events.TimerEvent;
	import flash.media.Microphone;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundMixer;
	import flash.media.SoundTransform;
	import flash.ui.Mouse;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import net.hires.Stats;
	
	import spark.core.SpriteVisualElement;
	
	//[SWF(backgroundColor="0x000000", widthPercent="100%", heightPercent="100%", frameRate="60")]
	public class SoundSpectrumBubbles extends SpriteVisualElement
	{
		
		protected var speedSlider:HSlider;
		protected var cPerSecondSlider:HSlider;
		
		protected var _soundBytes:ByteArray = new ByteArray();
		protected var _micBytes:ByteArray;
		protected var son:Sound;
		protected var sc:SoundChannel;
		protected var pow:int=0;
		protected var myBar:Sprite;
		protected var bubblesAnimation:BubblesAnimation;
		
		protected var st:SoundTransform = new SoundTransform();
		protected var mic:Microphone;
			
		public function SoundSpectrumBubbles()
		{
			//stage.align = StageAlign.TOP_LEFT;
			//stage.scaleMode = StageScaleMode.NO_SCALE;
			addEventListener(Event.ADDED_TO_STAGE, handleStageAdded, false, 0, true);
		}
		
		protected function handleStageAdded(event:Event):void
		{
			stage.addEventListener(Event.RESIZE, handleStageResize, false, 0, true);
			stage.addEventListener(KeyboardEvent.KEY_UP, _handleClick);
			var circles:int = 10000; //per second, minimum 100
			var circlesPerSecond:int = 2;
			var speed:int = 20; //px /s
			bubblesAnimation = new BubblesAnimation(circles, circlesPerSecond, speed);
			bubblesAnimation.cacheAsBitmap = true;
			bubblesAnimation.x = stage.stageWidth/2;
			bubblesAnimation.z = 300;
			addChild(bubblesAnimation);
			bubblesAnimation.createCircles();
			addStats();
			init();
		}
		
		protected function addStats():void
		{
			var stats:Stats = new Stats();
			addChild(stats);
		}
		
		protected function addUI():void
		{
			speedSlider = new HSlider();
			speedSlider.width = 200;
			speedSlider.height = 20;
			speedSlider.x = 100;
			speedSlider.y = 60;
			speedSlider.value = bubblesAnimation.speed;
			speedSlider.minimum = -10;
			speedSlider.maximum = 150;
			speedSlider.addEventListener(Event.CHANGE, handleSpeedSliderChange, false, 0, true);
			this.addChild(speedSlider);	
			cPerSecondSlider = new HSlider();
			cPerSecondSlider.width = 200;
			cPerSecondSlider.height = 20;
			cPerSecondSlider.x = 330;
			cPerSecondSlider.y = 60;
			cPerSecondSlider.minimum = 1;
			cPerSecondSlider.maximum = 100;
			cPerSecondSlider.addEventListener(MouseEvent.MOUSE_UP, handlecPerSecondSliderChange, false, 0, true);
			this.addChild(cPerSecondSlider);
		}
		
		protected function handlecPerSecondSliderChange(event:MouseEvent):void
		{
			bubblesAnimation.numCirclesPerSecond = event.currentTarget.value;
		//	setDebugText();
		}
		
		protected function handleSpeedSliderChange(event:Event):void
		{
			bubblesAnimation.speedDiff = event.currentTarget.value;
		//	setDebugText();
		}
		
		
		import flash.display.StageDisplayState;
		
		protected function goFullScreen():void
		{
			if (stage.displayState == StageDisplayState.NORMAL) 
			{
				stage.displayState=StageDisplayState.FULL_SCREEN;
				Mouse.hide();
			} 
			else 
			{
				stage.displayState=StageDisplayState.NORMAL;
				Mouse.show();
			}
		}
		
		protected function _handleClick(event:KeyboardEvent):void
		{
			goFullScreen();
		}
		
		
		protected function handleStageResize(event:Event):void
		{
			trace("resize");
			bubblesAnimation.x = stage.stageWidth/2;
		}
		
		protected function init(event:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			initMic2();
			/*initMic();
			initSound();
			addEventListener(Event.ENTER_FRAME, analyze);*/
		}
		
		
		protected function initMic():void 
		{
			mic = Microphone.getMicrophone();
			trace("initMic: "+mic);
			if (mic) 
			{
				mic.rate = 44;
				mic.addEventListener(SampleDataEvent.SAMPLE_DATA, micSampleDataHandler); 
				mic.setLoopBack(true);
			}
		}
		
		protected function micSampleDataHandler(event:SampleDataEvent):void 
		{
			trace("micSample: " + _micBytes.length);
			_micBytes = event.data;
			sc = son.play(); // CON DE MIME !!!!!!
		}
		
		
		protected function initSound():void 
		{
			son = new Sound();
			son.addEventListener(SampleDataEvent.SAMPLE_DATA, soundSampleDataHandler);
		}
		
		protected function soundSampleDataHandler(event:SampleDataEvent):void 
		{
			trace("soundSampleDataHandler: " + event.data.length);
			for (var i:int = 0; i < 8192 && _micBytes.bytesAvailable > 0; i++) 
			{
				var sample:Number=_micBytes.readFloat();
				event.data.writeFloat(sample);
				event.data.writeFloat(sample);
			}
		}
		
		
		
		
		
		public static const DELAY_LENGTH:int = 1000; 
		protected var timer:Timer;
		protected var soundBytes:ByteArray = new ByteArray();
		protected var sound:Sound = new Sound(); 
		protected var channel:SoundChannel;
		
		protected function initMic2():void
		{	
			mic = Microphone.getMicrophone(); 
			mic.setSilenceLevel(0, DELAY_LENGTH); 
			mic.gain = 100; 
			mic.rate = 44; 
			mic.addEventListener(SampleDataEvent.SAMPLE_DATA, micSampleDataHandler2); 			
			timer = new Timer(DELAY_LENGTH); 
			timer.addEventListener(TimerEvent.TIMER, timerHandler); 
			timer.start(); 
		}
		
		protected function micSampleDataHandler2(event:SampleDataEvent):void 
		{ 
			while(event.data.bytesAvailable) 
			{ 
				var sample:Number = event.data.readFloat(); 
				soundBytes.writeFloat(sample); 
			} 
		} 

		
		protected function timerHandler(event:TimerEvent):void 
		{ 
			trace("timer")
			//mic.removeEventListener(SampleDataEvent.SAMPLE_DATA, micSampleDataHandler); 
			//timer.stop(); 
			soundBytes.position = 0; 
			sound.addEventListener(SampleDataEvent.SAMPLE_DATA, playbackSampleHandler); 
			//channel.addEventListener( Event.SOUND_COMPLETE, playbackComplete ); 
			channel = sound.play(); 
		} 
		
		protected function playbackSampleHandler(event:SampleDataEvent):void 
		{ 
			for (var i:int = 0; i < 8192 && soundBytes.bytesAvailable > 0; i++) 
			{ 
				if(i==0) trace(sample); 
				var sample:Number = soundBytes.readFloat(); 
				event.data.writeFloat(sample); 
				event.data.writeFloat(sample); 
			} 
		} 
		
		
		
		protected function analyze(e:Event):void
		{
			/*SoundMixer.computeSpectrum(_soundBytes, true);
			var average:Number = 0;
			var averagetotal:Number = 0;
			var w:uint = 2;
			for (var i:int=0; i < 256; i++) 
			{
				pow = _soundBytes.readFloat()*100;
				//pow = Math.abs(pow);
				averagetotal += pow;
			}
			average = averagetotal/256;*/
				
			trace("analyze: "+mic.activityLevel)
			//if(average < 1) bubblesAnimation.redValue = Math.round(average/2*100)/100;
			//(" averagetotal: "+averagetotal+" average: "+average);
			if(mic.activityLevel != 0) 
			{
				bubblesAnimation.speed = mic.activityLevel * 12 + bubblesAnimation.speedDiff;
				bubblesAnimation.yRotation = 0;
			}
			else
			{	
				bubblesAnimation.speed = 50;
			}
		}
	}
}