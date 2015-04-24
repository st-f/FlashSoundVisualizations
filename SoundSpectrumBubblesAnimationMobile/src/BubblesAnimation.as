package
{
	import com.greensock.TweenLite;
	import com.greensock.easing.Circ;
	import com.greensock.easing.Linear;
	
	import flash.display.Bitmap;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.filters.BlurFilter;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	
	public class BubblesAnimation extends Sprite
	{
		[Embed(source="circle.png")] public static var circleBmp:Class;
		public var speedDiff:Number = 10;
		public var yRotation:Number = 0;
		
		protected var circleContainer:Sprite;
		protected var circlesBMP:Vector.<Bitmap>;
		protected var circlesPoolBMP:Vector.<Bitmap>;
		
		protected static const SPEED:int = 10;
		protected static const DEFAULT_CIRCLES_NUM:int = 200; 
		protected static const DEFAULT_CIRCLES_NUM_PER_SECOND:int = 1; 
		protected static const DEFAULT_RADIUS:int = 113;
		protected static const DEFAULT_MIN_RADIUS:int = 40;
		protected static const DEFAULT_MAX_RADIUS:int = 70;
		protected static const DEFAULT_COLOR1:uint = 0xFF6600;
		protected static const DEFAULT_COLOR2:uint = 0xFFFF00;
		protected static const DEFAULT_COLOR3:uint = 0x0099FF;
		protected static const DEFAULT_COLOR4:uint = 0x00FF00;
		protected static const COLORS:Array = [DEFAULT_COLOR1, DEFAULT_COLOR2, DEFAULT_COLOR3, DEFAULT_COLOR4];
		
		protected var _numCircles:int; 
		protected var _numCirclesPerSecond:int;
		protected var _speed:int;
		
		protected var useTween:Boolean = false;
		protected var _currentDisplayedCircles:int = 0;
		
		public function BubblesAnimation(circlesNum:int = DEFAULT_CIRCLES_NUM, 
							 circlesPerSecond:int = DEFAULT_CIRCLES_NUM_PER_SECOND, 
							 speed:int = SPEED)
		{
			super();
			_numCircles = circlesNum;
			_speed = speed;
			_numCirclesPerSecond = circlesPerSecond;
		}
		
		public function createCircles():void
		{
			circleContainer = new Sprite();
			//circleContainer.cacheAsBitmap = true;
			addChild(circleContainer);
			circlesBMP = new Vector.<Bitmap>();
			circlesPoolBMP = new Vector.<Bitmap>();
			var tmpc:Bitmap;
			for(var i:int=0; i<_numCircles; i++)
			{
				tmpc = new circleBmp();
				//drawCircle(tmpc, DEFAULT_RADIUS, DEFAULT_RADIUS, COLORS[Math.floor(Math.random()*4)]);
				//drawCircle(tmpc, Math.random()/2+0.5, DEFAULT_MIN_RADIUS + Math.random()*DEFAULT_MAX_RADIUS, COLORS[Math.floor(Math.random()*4)]);
				//tmpc.cacheAsBitmap = true;
				tmpc.visible = false;
				addChild(tmpc);
				circleContainer.addChild(tmpc);
				circlesPoolBMP.push(tmpc);
			}
			addEventListener(Event.ENTER_FRAME, loop);
			this.rotationY = 180;
		}
		
		protected function loop(event:Event):void
		{
			updateCircles();
			spawnCircles();
			//this.rotationY -= yRotation;
		}
		
		protected function spawnCircles():void
		{
			for(var i:int = 0; i < _numCirclesPerSecond; i++)
			{
				var circle:Bitmap = circlesPoolBMP.pop();
				circle.visible = true;
				circle.x = DEFAULT_MAX_RADIUS*-2 - Math.random() * DEFAULT_MAX_RADIUS;
				circle.y = stage.stageHeight/3 + Math.random() * DEFAULT_MAX_RADIUS*3;
				circlesBMP.push(circle);
			}
		}
		
		protected function updateCircles():void
		{
			//trace("updateCircles: "+circles.length);
			for(var i:int=0; i < circlesBMP.length; i++)
			{
				var circleBMP:Bitmap = circlesBMP[i];
				circleBMP.x += _speed;
				if(circleBMP.x > stage.stageWidth + DEFAULT_MAX_RADIUS*2)
				{
					removeCircle(circleBMP, i);
				}
			}
		}
		
		protected function removeCircle(circle:Bitmap, i:int):void
		{
			circle.visible = false;
			circlesBMP.splice(i, 1);
			circlesPoolBMP.push(circle);
		}

		protected static const TF:TextFormat = new TextFormat("Impact", 36, 0);
		
		/*protected function drawCircle(circle:Shape, opacity:Number, radius:int, color:uint):void
		{
			circle.graphics.clear();
			circle.graphics.beginFill(color);
			circle.graphics.drawCircle(0, 0, radius);
			circle.graphics.endFill();
			//circle.filters = [new BlurFilter(radius*.6,radius*.6)];
			circle.filters = [new BlurFilter(50,50)];
		}
*/
		public function get speed():int
		{
			return _speed;
		}

		public function set speed(value:int):void
		{
			_speed = value;
			
		}

		public function get numCirclesPerSecond():int
		{
			return _numCirclesPerSecond;
		}

		public function set numCirclesPerSecond(value:int):void
		{
			_numCirclesPerSecond = value;
			trace("numCirclesPerSecond: "+value);
		}

		public function get numCircles():int
		{
			return _numCircles;
		}

		public function set numCircles(value:int):void
		{
			_numCircles = value;
		}

		public function get currentDisplayedCircles():int
		{
			return _currentDisplayedCircles;
		}

		public function set currentDisplayedCircles(value:int):void
		{
			_currentDisplayedCircles = value;
		}

		
	}
}