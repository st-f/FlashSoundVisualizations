package 
{
	import away3d.cameras.*;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import away3d.controllers.HoverController;
	import away3d.debug.AwayStats;
	import away3d.debug.Trident;
	import away3d.entities.Mesh;
	import away3d.filters.BloomFilter3D;
	import away3d.lights.DirectionalLight;
	import away3d.lights.PointLight;
	import away3d.materials.ColorMaterial;
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.primitives.CubeGeometry;
	
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
	
	import org.libspark.betweenas3.tweens.ITween;
	
	[SWF(width='1280', height='800', backgroundColor='#000000', frameRate='60')]
	
	public class Away3DGlassCubes extends Sprite
	{
		protected var scene:Scene3D;
		protected var camera:Camera3D;
		protected var view:View3D;
		protected var cameraController:HoverController;
		protected var cube:Mesh;
		protected var directionalLight:DirectionalLight;
		protected var pointLight:PointLight;		
		
		protected var trident:Trident;
		
		protected var cameraViewDistance:Number = 100000;
		protected var antiAlias:Number = 2;
		protected var stats:AwayStats;
		protected var cubeMaterial:ColorMaterial;	
		// Away3D4 Camera handling variables (Hover Camera)
		protected var move:Boolean = false;
		protected var _cameraDistance:Number = 700;
		protected var lastPanAngle:Number;
		protected var lastTiltAngle:Number;
		protected var lastMouseX:Number;
		protected var lastMouseY:Number;
		//objects pools
		protected var cubeRowMesh:Vector.<Vector.<Mesh>>;
		protected var cubeLineMesh:Vector.<Mesh>;
		protected static const LINES_PER_ROW:int = 16;
		protected static const CUBES_PER_LINE:int = 16;
		protected static const CUBESIZE:int = 110;
		protected static const CUBEHEIGHT:int = 400;
		protected static const SPACEINLINE:int = 20;
		
		//MIC RELATED
		protected var sample:Number;
		protected var readNumber:Number;
		protected var _soundBytes:ByteArray = new ByteArray();
		protected var _micBytes:ByteArray;
		protected static const FREQLINES:int = CUBES_PER_LINE;
		protected var colorR:uint = 0xFF0000;
		protected var colorG:uint = 0x00FF00;
		protected var color:uint;
		protected var total:Number;
		protected var futurealpha:Number;
		protected var timer:Timer;
		protected var animationSpeed:int = 20;
		protected var valueLine:Vector.<Number>;
		protected var valueRows:Vector.<Vector.<Number>>;
		
		
		public function Away3DGlassCubes()
		{
			valueRows = new Vector.<Vector.<Number>>();
			view = new View3D();
			scene = new Scene3D();
			camera = new Camera3D();
			camera.lens.far = cameraViewDistance;
			setupLights();
			view.scene = scene;
			view.camera = camera;
			view.antiAlias = antiAlias;
			addChild(view);
			//view.filters3d = [new BloomFilter3D(15,15,0.25,1,2)];
			cameraController = new HoverController(camera, null, 0, 15, 2000);
			stats = new AwayStats(view,true);
			stats.x = 0;
			stats.y = 5;
			this.addChild(stats);
			createCubesRow();
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
			stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelHandler);
			stage.addEventListener(Event.RESIZE, resizeHandler);
			stage.addEventListener(KeyboardEvent.KEY_UP, handleKeyboard);
			resizeHandler();
			initMic();
			//createTrident();
			this.addEventListener(Event.ENTER_FRAME, renderThis);
		}
		
		protected function createTrident():void
		{
			trident = new Trident(1000);
			trident.position.y = 1600;
			view.scene.addChild(trident);
		}
		
		protected var lightPicker1:StaticLightPicker;
		protected var cubeLight:PointLight;
		/*protected var colors:Array = [0xFF0000, 0x00FF00, 0x0000FF, 
										0xCC0000, 0x00CC00, 0x0000CC,
										0xFFFF00, 0x00FFFF, 0xFFFF00, 0xFFCC00];*/
		
		protected function createMaterial():void
		{
			cubeMaterial = new ColorMaterial(0xFFFFFF, 1);
			cubeMaterial.specular = 0;
			cubeMaterial.ambient = 0.05;
			cubeMaterial.gloss = 0.5;
			var center:Number = CUBES_PER_LINE * (CUBESIZE + SPACEINLINE) / -2;
			lightPicker1 = new StaticLightPicker([pointLight, directionalLight]);
			cubeMaterial.lightPicker = lightPicker1;
		}
		
		protected function initMic():void
		{
			var mic:Microphone = Microphone.getMicrophone(); 
			mic.setSilenceLevel(0, 4000); 
			mic.rate = 44;
			mic.gain = 100;
			mic.addEventListener(SampleDataEvent.SAMPLE_DATA, micSampleDataHandler);
			//timer = new Timer(animationSpeed);
			//timer.addEventListener(TimerEvent.TIMER, animate, false, 0);
			//timer.start();
		}
		
		
		protected function createCubesRow():void
		{
			trace("Creating " + LINES_PER_ROW + " rows, " + CUBES_PER_LINE + " cubes per row, for a total of " + LINES_PER_ROW * CUBES_PER_LINE + " cubes.");
			cubeRowMesh = new Vector.<Vector.<Mesh>>();
			var center:Number = LINES_PER_ROW * (CUBESIZE+SPACEINLINE) / -2;
			for(var i:int = 0; i < LINES_PER_ROW; i++)
			{
				createCubesLine(center+(CUBESIZE+SPACEINLINE)*i);
			}
		}
		
		protected function createCubesLine(z:int = 0):void
		{
			cubeLineMesh = new Vector.<Mesh>();
			var center:Number = CUBES_PER_LINE * (CUBESIZE+SPACEINLINE) / -2;
			createMaterial();
			for(var i:int = 0; i < CUBES_PER_LINE; i++)
			{
				cube = new Mesh(new CubeGeometry(CUBESIZE, CUBEHEIGHT, CUBESIZE));
				cube.material = cubeMaterial;
				cube.position = new Vector3D(center+(CUBESIZE+SPACEINLINE)*i, 0, z);
				view.scene.addChild(cube);
				cubeLineMesh.push(cube);
			}
			cubeRowMesh.push(cubeLineMesh);
		}
		
		protected function setupLights():void
		{
			trace("setupLights()");
			directionalLight = new DirectionalLight();
			directionalLight.position = new Vector3D(1000, 1500, 200);
			directionalLight.lookAt(new Vector3D());
			directionalLight.ambient = 0.1;
			directionalLight.diffuse = 0.5;
			directionalLight.color = 0xFFFF00;
			scene.addChild(directionalLight);
			pointLight = new PointLight();
			pointLight.position = new Vector3D(1000, 1000, 0);
			pointLight.lookAt(new Vector3D());
			pointLight.ambient = 0.1;
			pointLight.diffuse = 0.5;
			pointLight.color = 0x00FF00;
			scene.addChild(pointLight);
		}
		
		
		//RENDER + INTERACTIONS
		
		protected function renderThis(e:Event = null):void 
		{
			animate();
			if (move) 
			{
				cameraController.panAngle = 0.3 * (stage.mouseX - lastMouseX) + lastPanAngle;
				cameraController.tiltAngle = 0.3 * (stage.mouseY - lastMouseY) + lastTiltAngle;
			}
			else
			{
				cameraController.panAngle += 1.5;
				//view.rotationY += 2;
			}
			view.render();
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
		
		protected function mouseDownHandler(e:MouseEvent):void
		{
			lastPanAngle = cameraController.panAngle;
			lastTiltAngle = cameraController.tiltAngle;
			lastMouseX = stage.mouseX;
			lastMouseY = stage.mouseY;
			move = true;
			stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		protected function mouseWheelHandler(e:MouseEvent):void
		{
			_cameraDistance += e.delta / 100;
			trace(_cameraDistance);
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
			//trace("resize: "+stage.stageWidth);
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
			valueLine = new Vector.<Number>();
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
				if(!dest) dest = 0;
				valueLine.push(dest);
				total += readNumber;
			}
			if(valueRows.length > LINES_PER_ROW-1)
			{
				valueRows.pop();	
			}
			valueRows.unshift(valueLine);
			animateRowsAndColumns();
		}
		
		
		protected var animateLoopr:int; 
		protected var animateLoopl:int; 
		protected var animateLoopCenter:int; 
		
		protected function animateRowsAndColumns():void
		{
			//var tween:ITween;
			//TweenMax.killAll(false);
			//var tweens:Array = [];
			for (animateLoopr = 0; animateLoopr < valueRows.length; animateLoopr++)
			{
				//var localTweens:Array = [];
				for (animateLoopl = 0; animateLoopl < CUBES_PER_LINE; animateLoopl++)
				{
					if(!valueRows[animateLoopr][animateLoopl]) return;				
					//tween = BetweenAS3.tween(cubeRowMesh[r][l], {scaleY:valueRows[r][l]}, animationSpeed/1000);
					//tweens.push(tween);
					//tween.play();
					cubeRowMesh[animateLoopr][animateLoopl].scaleY = valueRows[animateLoopr][animateLoopl];
					//trace("valueRows["+r+"]["+l+"] : " + valueRows[r][l]+" cubeRowMesh["+r+"]["+l+"]: "+cubeRowMesh[r][l].position.x);
					//TweenLite.to(mesh, animationSpeed/1000, {overwrite:true,scaleY:dest});
					//BetweenAS3.tween(mesh, {scaleY:dest}, animationSpeed/1000);
				}
				//tweens.push(BetweenAS3.parallelTweens(localTweens));
			}
			//var tweenGroup:ITween = BetweenAS3.parallelTweens(tweens);
			//tweenGroup.play();
			/*if(move == false)
			{*/
				//cameraController.panAngle = total/FREQLINES * 90 * 10;
				//cameraController.panAngle = total/FREQLINES * 90 * 10;
			//}
		}
		
		
	}
}
