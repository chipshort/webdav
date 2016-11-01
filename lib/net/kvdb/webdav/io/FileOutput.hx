package net.kvdb.webdav.io;

import haxe.io.Bytes;
import haxe.io.Output;

class FileOutput extends Output
{
    public var onProgress : Int->Void;
    public var onClose : Void->Void;
    
    var progress : Int = 0;
    var fileOut : Output;
    
    public function new (out : Output)
    {
        fileOut = out;
    }
    
    #if sys
    public static function fromFile (file : String, binary = true) : FileOutput
    {
        return new FileOutput (sys.io.File.write (file, binary));
    }
    #end
    
    override public function writeByte (c : Int) : Void
    {
        fileOut.writeByte (c);
        
        progress += 1;
        showProgress ();
    }
    
    override public function writeBytes (s : Bytes, p : Int, l : Int) : Int
    {
        var len = fileOut.writeBytes (s, p, l);
        
        progress += len;
        showProgress ();
        
        return len;
    }
    
    override public function flush () : Void
    {
        fileOut.flush ();
    }
    
    override public function close () : Void
    {
        fileOut.close ();
        
        if (onClose != null)
            onClose ();
	}
    
    override public function write(s : Bytes) : Void
    {
        fileOut.write (s);
        
        progress += s.length;
        showProgress ();
    }
    
    override public function writeFullBytes (s : Bytes, pos : Int, len : Int) : Void
    {
        fileOut.writeFullBytes (s, pos, len);
        
        progress += len;
        showProgress ();
    }
    
    inline function showProgress () : Void
    {
        if (onProgress != null) onProgress (progress);
    }
}
