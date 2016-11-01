package helper;

class XmlHelper
{
    //static var regex = ~/([A-z]+):([A-z]+)/; //does not comply with xml standard
    
    public static function getElementsByTagName (xml : Xml, name : String) : Array<Xml>
    {
        var results = [];
        
        var children = xml.elements ();
        for (element in children) {
            if (element.nodeName == name || name == "*") {
                results.push (element);
            }
            
            results = results.concat (getElementsByTagName (element, name));
        }
        
        return results;
    }
    
    public static function getElementsByTagNameWithoutNS (xml : Xml, name : String) : Array<Xml>
    {
        var results = [];
        
        var children = xml.elements ();
        for (element in children) {
            var tag = element.nodeName.split (":");
            var tagName = tag.length > 1 ? tag[1] : tag[0];
            
            if (tagName == name || name == "*") {
                results.push (element);
            }
            
            
            results = results.concat (getElementsByTagNameWithoutNS (element, name));
        }
        
        return results;
    }
    
    public static function getInnerXml (xml : Xml) : String
    {
        var child = xml.firstChild ();
        if (child == null) return "";
        
        return child.nodeValue;
    }
}
