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
	import flash.media.Microphone;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundMixer;
	import flash.media.SoundTransform;
	import flash.ui.Mouse;
	import flash.utils.ByteArray;
	
	import net.hires.Stats;
	
	[SWF(backgroundColor="0x000000", widthPercent="100%", heightPercent="100%")]
	public class SoundSpectrumBubbles extends Sprite
	{
		
		protected var speedSlider:HSlider;
		protected var cPerSecondSlider:HSlider;
		protected var fpsSlider:HSlider;
		
		protected var _soundBytes:ByteArray = new ByteArray();
		protected var _micBytes:ByteArray;
		protected var son:Sound;
		protected var sc:SoundChannel;
		protected var pow:int=0;
		protected var myBar:Sprite;
		protected var bubblesAnimation:BubblesAnimation;
			
		public function SoundSpectrumBubbles()
		{
			stage.align = StageAlign.TOP_LEFT;
			//stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.addEventListener(Event.RESIZE, handleStageResize, false, 0, true);
			stage.addEventListener(KeyboardEvent.KEY_UP, _handleClick);
			var circles:int = 10000; //per second, minimum 100
			var circlesPerSecond:int = 2;
			var speed:int = 20; //px /s
			var fps:int = 60;
			bubblesAnimation = new BubblesAnimation(circles, circlesPerSecond, speed, fps);
			bubblesAnimation.cacheAsBitmap = true;
			bubblesAnimation.x = stage.stageWidth/2;
			bubblesAnimation.z = 300;
			addChild(bubblesAnimation);
			bubblesAnimation.createCircles();
			//addStats();
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
		
		protected function handlefpsSliderChange(event:MouseEvent):void
		{
			bubblesAnimation.fps = event.currentTarget.value;
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
			myBar=new Sprite;
			initMic();
			initSound();
			addEventListener(Event.ENTER_FRAME, drawLines);
		}
		
		protected var st:SoundTransform = new SoundTransform(0);
		protected var mic:Microphone=Microphone.getMicrophone();
		
		protected function initMic():void 
		{
			mic=Microphone.getMicrophone();
			if (mic) 
			{
				//SoundMixer.soundTransform = st;
				mic.rate=44;
				mic.setSilenceLevel(0);
				mic.setUseEchoSuppression(true);
			//	mic.setLoopBack(false);
				mic.addEventListener(SampleDataEvent.SAMPLE_DATA, micSampleDataHandler);
			} 
			else 
			{
				// no mic
			}
		}
		protected function micSampleDataHandler(event:SampleDataEvent):void 
		{
			_micBytes = event.data;
			sc = son.play();
			//sc.soundTransform = st;
		}
		
		
		protected function initSound():void 
		{
			son = new Sound();
			son.addEventListener(SampleDataEvent.SAMPLE_DATA, soundSampleDataHandler);
		}
		
		protected function soundSampleDataHandler(event:SampleDataEvent):void 
		{
			for (var i:int = 0; i < 8192 && _micBytes.bytesAvailable > 0; i++) 
			{
				var sample:Number=_micBytes.readFloat();
				event.data.writeFloat(sample);
				event.data.writeFloat(sample);
			}
		}
		
		protected function drawLines(e:Event):void{
			
			SoundMixer.computeSpectrum(_soundBytes, true);
			myBar.graphics.clear();
			myBar.graphics.lineStyle(2,0xabc241);
			var average:int = 0;
			var averagetotal:int = 0;
			for (var i:int=0; i < 256; i++) 
			{
				pow=_soundBytes.readFloat()*200;
				pow=Math.abs(pow);
				averagetotal += pow*20;
				//trace("> "+i+" : "+pow);
				//myBar.graphics.drawRect(i*5, 0, 2, pow*2);
				//addChild(myBar);
			}
			average = averagetotal/256;
			if(mic.activityLevel != 0) 
			{
				bubblesAnimation.speed = mic.activityLevel * 12 + average * 5 + bubblesAnimation.speedDiff;
				bubblesAnimation.yRotation = average / 5;
			}
			else
			{	
				bubblesAnimation.speed = 50;
			}
		}
	}
}