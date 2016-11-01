package net.kvdb.webdav.io;

import haxe.io.BytesOutput;
import haxe.io.Bytes;

 
class CallbackOutput extends BytesOutput
{
    var onClose : Bytes->Void;

    public function new (callback : Bytes->Void)
    {
        super ();
        onClose = callback;
    }
    
    override function close () : Void
    {
        super.close ();
        
        if (onClose != null)
            onClose (getBytes ());
    }
}
