Class BaseTypes.RevSearchParameter Extends (%Persistent, %JSON.Adaptor)
{

Property TargetResource As %String;

Property BaseResource As %String;

Property SearchField As %String;

Method %OnNew(tr As %String, bree As %String) As %Status
{
    If tr = "" Quit $$$ERROR($$$GeneralError, "Must supply target resource name")
    Set ..TargetResource = tr
    If bree = "" Quit $$$ERROR($$$GeneralError, "Must supply base-element parameter")
    Do ..SetBaseResource(bree)
    Quit $$$OK
}

Method SetBaseResource(bree As %String) As %Status
{
   Set ..BaseResource = $PIECE(bree, ".", 1)
   Set ..SearchField = $PIECE(bree, ".", 2)
   Quit $$$OK
}

Method ToString() As %String
{
    Set result = "TargetResource= "_..TargetResource_" BaseResource ="_..BaseResource_" Search Field="_..SearchField
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
<Data name="RevSearchParameterDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>TargetResource</Value>
</Value>
<Value name="3">
<Value>BaseResource</Value>
</Value>
<Value name="4">
<Value>SearchField</Value>
</Value>
<Value name="5">
<Value>Version</Value>
</Value>
<Value name="6">
<Value>Experimental</Value>
</Value>
<Value name="7">
<Value>Description</Value>
</Value>
<Value name="8">
<Value>Type</Value>
</Value>
</Data>
<DataLocation>^BaseTypes.RevSearchParameterD</DataLocation>
<DefaultData>RevSearchParameterDefaultData</DefaultData>
<IdLocation>^BaseTypes.RevSearchParameterD</IdLocation>
<IndexLocation>^BaseTypes.RevSearchParameterI</IndexLocation>
<StreamLocation>^BaseTypes.RevSearchParameterS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
