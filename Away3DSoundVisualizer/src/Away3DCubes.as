package 
{
	import away3d.cameras.*;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import away3d.controllers.HoverController;
	import away3d.debug.AwayStats;
	import away3d.entities.Mesh;
	import away3d.lights.DirectionalLight;
	import away3d.lights.PointLight;
	import away3d.materials.ColorMaterial;
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.primitives.CubeGeometry;
	
	import com.greensock.TweenLite;
	import com.greensock.TweenMax;
	
	import flash.display.BlendMode;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.SampleDataEvent;
	import flash.events.TimerEvent;
	import flash.geom.Vector3D;
	import flash.media.Microphone;
	import flash.ui.Keyboard;
	import flash.ui.Mouse;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import mx.core.FlexGlobals;
	import mx.olap.aggregators.AverageAggregator;
	
	[SWF(width='1280', height='800', backgroundColor='#000000', frameRate='60')]
	
	public class Away3DCubes extends Sprite
	{
		protected var scene:Scene3D;
		protected var camera:Camera3D;
		protected var view:View3D;
		protected var cameraController:HoverController;
		protected var cube:Mesh;
		protected var directionalLight:DirectionalLight;
		protected var pointLight:PointLight;		
		
		protected var cameraViewDistance:Number = 100000;
		protected var antiAlias:Number = 2;
		protected var stats:AwayStats;
		protected var myMaterial:ColorMaterial;	
		// Away3D4 Camera handling variables (Hover Camera)
		protected var move:Boolean = false;
		protected var lastPanAngle:Number;
		protected var lastTiltAngle:Number;
		protected var lastMouseX:Number;
		protected var lastMouseY:Number;
		//objects pools
		protected var cubeLineMesh:Vector.<Mesh>;
		protected static const CUBESPERLINE:int = 128;
		protected static const CUBESIZE:int = 100;
		protected static const CUBEHEIGHT:int = 800;
		protected static const SPACEINLINE:int = 10;
		
		//MIC RELATED
		protected var sample:Number;
		protected var readNumber:Number;
		protected var _soundBytes:ByteArray = new ByteArray();
		protected var _micBytes:ByteArray;
		protected static const FREQLINES:int = CUBESPERLINE;
		protected var colorR:uint = 0xFF0000;
		protected var colorG:uint = 0x00FF00;
		protected var color:uint;
		protected var total:Number;
		protected var futurealpha:Number;
		protected var timer:Timer;
		protected var animationSpeed:int = 100;
		
		public function Away3DCubes()
		{
			view = new View3D();
			scene = new Scene3D();
			camera = new Camera3D();
			setupLights();
			camera.lens.far = cameraViewDistance;
			view.scene = scene;
			view.camera = camera;
			view.antiAlias = antiAlias;
			addChild(view);
			cameraController = new HoverController(camera, null, 0, 15, 2000);
			stats = new AwayStats(view,true);
			stats.x = 5;
			stats.y = 5;
			this.addChild(stats);
			myMaterial = new ColorMaterial(0xFFCC00, 0.5);
			var lightPicker1:StaticLightPicker;
			lightPicker1 = new StaticLightPicker([pointLight, directionalLight]);
			myMaterial.lightPicker = lightPicker1;
			myMaterial.gloss = 20;
			createCubesLine();
			
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
			stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
			stage.addEventListener(Event.RESIZE, resizeHandler);
			stage.addEventListener(KeyboardEvent.KEY_UP, handleKeyboard);
			resizeHandler();
			initMic();
			this.addEventListener(Event.ENTER_FRAME, renderThis);
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
			else
			{
				goFullScreen();
			}
		}
		
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
		protected function initMic():void
		{
			var mic:Microphone = Microphone.getMicrophone(); 
			mic.setSilenceLevel(0, 4000); 
			mic.rate = 44;
			mic.gain = 100;
			mic.addEventListener(SampleDataEvent.SAMPLE_DATA, micSampleDataHandler);
			timer = new Timer(animationSpeed);
			timer.addEventListener(TimerEvent.TIMER, animate, false, 0);
			timer.start();
		}
		
		protected function createCubesLine():void
		{
			cubeLineMesh = new Vector.<Mesh>();
			var center:Number = CUBESPERLINE * (CUBESIZE+SPACEINLINE) / -2;
			for(var i:int = 0; i < CUBESPERLINE; i++)
			{
				cube = new Mesh(new CubeGeometry(CUBESIZE, CUBEHEIGHT, CUBESIZE));
				//cube.position.x = i * 1000;
				cube.material = myMaterial;
				cube.position = new Vector3D(center+(CUBESIZE+SPACEINLINE)*i,0,0);
				view.scene.addChild(cube);
				cubeLineMesh.push(cube);
			}
		}
		
		protected function setupLights():void
		{
			trace("setupLights()");
			directionalLight = new DirectionalLight();
			directionalLight.position = new Vector3D(0,20,0);
			directionalLight.ambient = 1.7;
			directionalLight.diffuse = 0.3;
			scene.addChild(directionalLight);
			pointLight = new PointLight();
			pointLight.position = new Vector3D(-200,-200,-500);
			pointLight.ambient = 2;
			pointLight.diffuse = 2;
			pointLight.color = 0xFFCC00;
			scene.addChild(pointLight);
		}
		
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
		
		
		
		/// MIC SAMPLE DATA
		
		
		protected function micSampleDataHandler(event:SampleDataEvent):void 
		{ 
			var i:int = 0;
			_soundBytes = new ByteArray();
			while(event.data.bytesAvailable)    
			{ 
				if(i >= FREQLINES-1) 
				{
					i = 0;
					return;
				}
				sample = event.data.readFloat() * 1.5; //to double the mic gain
				_soundBytes.writeFloat(sample);
				_soundBytes.writeFloat(sample);
				i++;
			}
		}
		
		protected function animate(event:TimerEvent = null):void
		{
			if(_soundBytes.length < FREQLINES) return;
			var dest:Number;
			total = 0;
			_soundBytes.position = 0;
			TweenMax.killAll(false);
			for (var i:int = 0; i < FREQLINES; i++)
			{
				readNumber = _soundBytes.readFloat();
				//animateLine(_lines[i], readNumber, animationSpeed/1000);
				if(readNumber > 0)
				{
					color = colorG;
					futurealpha = 1;
				}
				else
				{
					color = colorR;
					futurealpha = .4;
				}
				dest = Math.round(Math.abs(readNumber * 10000))/10000 * 3;
				//ColorMaterial(cubeLineMesh[i].material).color = color;
				//cubeLineMesh[i].scaleY = Number(dest);
				/*if(cubeLineMesh[i].scaleY == 2)
				{
					TweenLite.to(cubeLineMesh[i], 1, {overwrite:true,scaleY:"1"});
				}
				else
				{
					TweenLite.to(cubeLineMesh[i], 1, {overwrite:true,scaleY:"2"});
				}*/
				TweenLite.to(cubeLineMesh[i], animationSpeed/1000, {overwrite:true,scaleY:dest});
				//trace("dest: "+dest);
				total += readNumber;
			}
			if(move == false)
			{
				TweenLite.to(cameraController, animationSpeed/1000,{distance:total * 150 + 5500});
				TweenLite.to(cameraController, animationSpeed/1000,{tiltAngle:total/FREQLINES * 180});
				TweenLite.to(cameraController, animationSpeed/1000,{panAngle:total/FREQLINES * 180});
				//TweenLite.to(cameraController, animationSpeed/1000,{wrapPanAngle:total});
			}
			trace("total: "+total);
		}
		
		
		
		
	}
}
