Class Collections.RevSearchParameterCollection Extends (%Persistent, %JSON.Adaptor)
{

Property ResourceName As %String;

Property RevSearchParameters As array Of BaseTypes.RevSearchParameter;

Index revSearchResIndex On RevSearchParameters(KEYS) [ Type = bitmap ];

Method %OnNew(rname As %String) As %Status
{
    Set sc = $$$OK
    Set ..ResourceName = rname
    Return sc
}

Method AddRevSearchParam(rsp As BaseTypes.RevSearchParameter, index As %String)
{
    Do ..RevSearchParameters.SetAt(rsp, index)
    //Write "Search Parameters Index:"_index_" for SP: "_sp.ToString()
}

Method WriteRevSearchParameters()
{
    Set key = ""
    Do ..RevSearchParameters.GetNext(.key)
    While (key '= ""){
        Set val = ..RevSearchParameters.GetAt(.key)
        Write ?5, "Key = "_key_" with value= "_val.ToString(), !
        Do ..RevSearchParameters.GetNext(.key)
    }
}

Storage Default
{
<Data name="RevSearchParameterCollectionDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ResourceName</Value>
</Value>
</Data>
<Data name="RevSearchParameters">
<Attribute>RevSearchParameters</Attribute>
<Structure>subnode</Structure>
<Subscript>"RevSearchParameters"</Subscript>
</Data>
<DataLocation>^Collections.RevSearchPaE328D</DataLocation>
<DefaultData>RevSearchParameterCollectionDefaultData</DefaultData>
<IdLocation>^Collections.RevSearchPaE328D</IdLocation>
<IndexLocation>^Collections.RevSearchPaE328I</IndexLocation>
<StreamLocation>^Collections.RevSearchPaE328S</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
