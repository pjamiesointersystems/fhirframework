Class BaseTypes.SearchParameter Extends (%Persistent, %JSON.Adaptor)
{

// unspecificied properties are exported as a null value

Parameter %JSONNULL = 1;

Parameter %JSONIGNORENULL = 1;

Property BaseResource As %String;

Property Name As %String;

Property Version As %String;

Property Experimental As %Boolean;

Property Description As %String(MAXLEN = 1250);

Property Type As %String;

Property Comparator As %DynamicArray;

Property ResTarget As %DynamicArray;

Property PathExpression As %String(MAXLEN = 500);

Method %OnNew(br As %String, name As %String, version As %String = "4.0.1", exp As %Boolean, des As %DynamicArray, ty As %DynamicArray, comp As %DynamicArray, tar As %DynamicArray, fp As %String = "") As %Status
{
    If br = "" Quit $$$ERROR($$$GeneralError, "Must supply base resource name")
    Set ..BaseResource = br
    If name = "" Quit $$$ERROR($$$GeneralError, "Must supply search parameter name")
    Set ..Name = name
    Set ..Version = version
    Set ..Experimental = exp
    //find values based on fhirpath expression
    Set ..PathExpression = fp
    If ($LENGTH(des) > 130){
        Set ..Description = $EXTRACT(des, 1, 130)
    }
    Else {
        Set ..Description = des
    }
    
    Set ..Type = ty
   /*  If (comp = ""){
        Set comp = []
    } */
    Set ..Comparator = comp
    /* If (tar = ""){
        Set tar = []
    } */
    Set ..ResTarget = tar
    Quit $$$OK
}

Method ToString() As %String
{
    Set result = "BaseResource="_..BaseResource_" Search Param="_..Name_" Type="_..Type
    Return result
}

Storage Default
{
<Data name="Comparator">
<Attribute>Comparator</Attribute>
<Structure>node</Structure>
<Subscript>"Comparator"</Subscript>
</Data>
<Data name="ResTarget">
<Attribute>ResTarget</Attribute>
<Structure>node</Structure>
<Subscript>"ResTarget"</Subscript>
</Data>
<Data name="SearchParameterDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>BaseResource</Value>
</Value>
<Value name="3">
<Value>Name</Value>
</Value>
<Value name="4">
<Value>Version</Value>
</Value>
<Value name="5">
<Value>Experimental</Value>
</Value>
<Value name="6">
<Value>Description</Value>
</Value>
<Value name="7">
<Value>Type</Value>
</Value>
<Value name="8">
<Value>PathExpression</Value>
</Value>
</Data>
<DataLocation>^BaseTypes.SearchParameterD</DataLocation>
<DefaultData>SearchParameterDefaultData</DefaultData>
<IdLocation>^BaseTypes.SearchParameterD</IdLocation>
<IndexLocation>^BaseTypes.SearchParameterI</IndexLocation>
<StreamLocation>^BaseTypes.SearchParameterS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
