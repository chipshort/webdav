package test;

class TraceSocket
{
    public var input(default,null) : haxe.io.Input;
	public var output(default,null) : haxe.io.Output;
    
    var socket : sys.ssl.Socket;
    
    public function new ()
    {
        socket = new sys.ssl.Socket ();
        input = socket.input;
        output = new TraceOutput (this, socket.output);
    }
    
    public function trace (bytes : haxe.io.Bytes) : Void
    {
        Sys.print (bytes.toString ());
    }
    
	public function connect( host : sys.net.Host, port : Int ) : Void
    {
        socket.connect (host, port);
    }
	public function setTimeout( t : Float ) : Void
    {
        socket.setTimeout (t);
    }
	public function write( str : String ) : Void
    {
        Sys.print (str);
        socket.write (str);
    }
	public function close() : Void
    {
        Sys.println ("");
        socket.close ();
    }
	public function shutdown( read : Bool, write : Bool ) : Void
    {
        socket.shutdown (read, write);
    }
	#if hxssl
	public function setCertLocation( file : String, folder : String ) : Void
    {
        socket.setCertLocation (file, folder);
    }
	#end
}
