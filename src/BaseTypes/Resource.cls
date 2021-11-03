Class BaseTypes.Resource Extends (%Persistent, %JSON.Adaptor)
{

Property ResName As %String;

Method %OnNew(resName As %String) As %Status
{
    If resName = "" Quit $$$ERROR($$$GeneralError, "Must supply resource name")
    Set ..ResName = resName
    Quit $$$OK
}

Storage Default
{
<Data name="ResourceDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ResName</Value>
</Value>
</Data>
<DataLocation>^BaseTypes.ResourceD</DataLocation>
<DefaultData>ResourceDefaultData</DefaultData>
<IdLocation>^BaseTypes.ResourceD</IdLocation>
<IndexLocation>^BaseTypes.ResourceI</IndexLocation>
<StreamLocation>^BaseTypes.ResourceS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
