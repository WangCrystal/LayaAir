package laya.webgl.submit {
	import laya.maths.Matrix;
	import laya.webgl.submit.ISubmit;
	import laya.utils.Stat;
	import laya.webgl.utils.IndexBuffer;
	import laya.webgl.utils.VertexBuffer;
	import laya.webgl.WebGL;
	import laya.webgl.WebGLContext;
	import laya.webgl.canvas.BlendMode;
	import laya.webgl.canvas.WebGLContext2D;
	import laya.webgl.shader.Shader;
	import laya.webgl.shader.d2.value.Value2D;
	import laya.webgl.utils.CONST3D2D;
	import laya.webgl.utils.RenderState2D;
	/**
	 * ...
	 * @author wk
	 */
	public class SubmitOtherIBVB   implements ISubmit
	{
		/*[DISABLE-ADD-VARIABLE-DEFAULT-VALUE]*/
		
		private static var _cache:Array =/*[STATIC SAFE]*/(_cache = [], _cache._length = 0, _cache);
		
		private static var tempMatrix4:Array =/*[STATIC SAFE]*/ [
			1, 0, 0, 0,
			0, 1, 0, 0,
			0, 0, 1, 0,
			0, 0, 0, 1,
		];
		
		public static function create(context:WebGLContext2D,vb:VertexBuffer,ib:IndexBuffer,numElement:int,shader:Shader,shaderValue:Value2D,startIndex:int,offset:int):SubmitOtherIBVB
		{
			var o:SubmitOtherIBVB = (!_cache._length)?(new SubmitOtherIBVB()):_cache[--_cache._length];
			o._ib = ib;
			o._vb = vb;
			o._numEle = numElement;
			o._shader = shader;
			o._shaderValue = shaderValue;
			var blendType:int = context._nBlendType;
			o._blendFn = context._targets?BlendMode.targetFns[blendType]:BlendMode.fns[blendType];
			o.startIndex = startIndex;
			o.offset = offset;
			return o;
		}
		protected var offset:int = 0;
		protected var _vb : VertexBuffer;
		protected var _ib : IndexBuffer;
		protected var _blendFn:Function;
		
		public var _mat:Matrix;
		public var _shader:Shader;
		public var _shaderValue:Value2D;
		public var _numEle : int;
		
		public var startIndex:int=0;
		
		public function SubmitOtherIBVB() 
		{
			super();
			_mat= Matrix.create();
		}
		
		public  function releaseRender():void
		{
			var cache:Array = _cache;
			cache[cache._length++] = this;
		}
				
		public function getRenderType():int
		{
			return Submit.TYPE_OTHERIBVB;
		}
		
		public function renderSubmit() : int {
			
			if (_shaderValue.textureHost)//TODO:阿欢调整
			{
				var source:*= _shaderValue.textureHost.source;
				if ( !source) return 1;
				_shaderValue.texture = source;
			}

			_vb.bind_upload(_ib);
			
			var w:Array = RenderState2D.worldMatrix4;
			var wmat:Matrix = Matrix.TEMP;
			Matrix.mulPre(_mat,w[0],w[1],w[4],w[5],w[12],w[13], wmat);
			
			var tmp:Array = RenderState2D.worldMatrix4 = tempMatrix4;
			tmp[0] = wmat.a;
			tmp[1] = wmat.b;
			tmp[4] = wmat.c;
			tmp[5] = wmat.d;
			tmp[12] = wmat.tx;
			tmp[13] = wmat.ty;
			_shader._offset = this.offset;
			_shaderValue.refresh();
			_shader.upload( _shaderValue );
			_shader._offset = 0;
			var gl:WebGLContext= WebGL.mainContext;
			if (Submit.activeBlendFunction !== _blendFn)
			{
				gl.enable( WebGLContext.BLEND );
				_blendFn(gl);
				Submit.activeBlendFunction = _blendFn;
			}
			Stat.drawCall++;
			Stat.trianglesFaces += _numEle/3;
			gl.drawElements(WebGLContext.TRIANGLES, this._numEle, WebGLContext.UNSIGNED_SHORT,startIndex);
			RenderState2D.worldMatrix4 = w;
			
			Shader.activeShader = null;
			return 1;
		}
		
		
	}

}