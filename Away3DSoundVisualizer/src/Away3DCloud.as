package
{
	import away3d.cameras.Camera3D;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import away3d.controllers.HoverController;
	import away3d.debug.AwayStats;
	import away3d.entities.Sprite3D;
	import away3d.materials.BitmapMaterial;
	import away3d.materials.TextureMaterial;
	import away3d.textures.BitmapTexture;
	
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filters.BlurFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.ui.Keyboard;

	[SWF(width="800", height="600")]
	public class Away3DCloud extends Sprite
	{
		protected var _material:TextureMaterial;
		
		protected var scene:Scene3D;
		protected var camera:Camera3D;
		protected var view:View3D;
		protected var cameraController:HoverController;
		protected var antiAlias:Number = 2;
		protected var stats:AwayStats;	
		// Away3D4 Camera handling variables (Hover Camera)
		protected var move:Boolean = false;
		protected var lastPanAngle:Number;
		protected var lastTiltAngle:Number;
		protected var lastMouseX:Number;
		protected var lastMouseY:Number;
		
		public function Away3DCloud()
		{
			view = new View3D();
			scene = new Scene3D();
			camera = new Camera3D();
			view.scene = scene;
			view.camera = camera;
			view.antiAlias = antiAlias;
			addChild(view);
			cameraController = new HoverController(camera, null, 0, 15, 2000);
			stats = new AwayStats(view,true);
			stats.x = 5;
			stats.y = 5;
			this.addChild(stats);
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
			stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
			stage.addEventListener(Event.RESIZE, resizeHandler);
			stage.addEventListener(KeyboardEvent.KEY_UP, handleKeyboard);
			resizeHandler();
			this.addEventListener(Event.ENTER_FRAME, renderThis);
			createScene();
			super();
		}
		
		protected function handleKeyboard(event:KeyboardEvent):void
		{
			if(event.keyCode == Keyboard.DOWN)
			{
				camera.z+=100;
			}
			else if(event.keyCode == Keyboard.UP)
			{
				camera.z-=100;
			}
		}
		
		protected function createScene():void
		{
			_createMaterial();
			var i:int;
			for(i = 0; i < 128; i++)
			{
				var sprite:Sprite3D = new Sprite3D(_material, 256, 256);
				sprite.x = (Math.random()-.5) * 1024;
				sprite.y = (Math.random()-.5) * 1024;
				sprite.z = (Math.random()-.5) * 1024;	
				view.scene.addChild(sprite);
			}
		}
		
		protected function _createMaterial():void
		{
			var puff:Shape = new Shape();
			var dia:Number = Math.random() * 128 + 30;
			puff.graphics.beginFill(0xCCCCCC, Math.random());
			puff.graphics.drawEllipse(-dia/2, -dia/2, dia, dia);			
			var bmp:BitmapData = new BitmapData(256, 256, true, 0);
			bmp.draw(puff, new Matrix(1, 0, 0, 1, 128, 128));			
			var blur:BlurFilter = new BlurFilter(32, 32, 2);
			bmp.applyFilter(bmp, bmp.rect, new Point(), blur);
			_material = new TextureMaterial(new BitmapTexture(bmp));
		}
		
		
		//RENDERING
		
		protected function renderThis(e:Event = null):void 
		{
			if (move) 
			{
				cameraController.panAngle = 0.3 * (stage.mouseX - lastMouseX) + lastPanAngle;
				cameraController.tiltAngle = 0.3 * (stage.mouseY - lastMouseY) + lastTiltAngle;
			}
			else
			{
				//cameraController.panAngle += .15;
				//view.rotationY += 2;
			}
			view.render();
		}
		
		protected function mouseDownHandler(e:MouseEvent):void
		{
			lastPanAngle = cameraController.panAngle;
			lastTiltAngle = cameraController.tiltAngle;
			lastMouseX = stage.mouseX;
			lastMouseY = stage.mouseY;
			move = true;
			stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		protected function mouseUpHandler(e:MouseEvent):void
		{
			move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		protected function onStageMouseLeave(e:Event):void
		{
			move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		protected function resizeHandler(e:Event=null):void
		{
			// Position Away3D4s view
			view.width = stage.stageWidth;
			view.height = stage.stageHeight;
			trace("resize: "+stage.stageWidth);
		}
	}
}