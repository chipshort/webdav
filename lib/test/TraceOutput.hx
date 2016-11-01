package test;

class TraceOutput extends haxe.io.Output
{
    var output : haxe.io.Output;
    var socket : TraceSocket;
    
    public function new (parent : TraceSocket, proxied : haxe.io.Output)
    {
        output = proxied;
        socket = parent;
    }
    
    override public function writeFullBytes (s : haxe.io.Bytes, pos : Int, len : Int) : Void
    {
        output.writeFullBytes (s, pos, len);
        socket.trace (haxe.io.Bytes.ofString ("[BYTE DATA]\n")); //s.sub (pos, len)
    }
}
