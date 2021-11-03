Class Collections.SearchParameterCollection Extends (%Persistent, %JSON.Adaptor)
{

Property ResourceName As %String;

Property SearchParameters As array Of BaseTypes.SearchParameter;

Index searchResIndex On SearchParameters(KEYS) [ Type = bitmap ];

Method %OnNew(rname As %String) As %Status
{
    Set sc = $$$OK
    Set ..ResourceName = rname
    Return sc
}

Method AddSearchParam(sp As BaseTypes.SearchParameter, index As %String)
{
    Do ..SearchParameters.SetAt(sp, index)
    //Write "Search Parameters Index:"_index_" for SP: "_sp.ToString()
}

Method WriteSearchParameters()
{
    Set key = ""
    Do ..SearchParameters.GetNext(.key)
    While (key '= ""){
        Set val = ..SearchParameters.GetAt(.key)
        Write ?5, "Key = "_key_" with value= "_val.ToString(), !
        Do ..SearchParameters.GetNext(.key)
    }
}

Storage Default
{
<Data name="SearchParameterCollectionDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ResourceName</Value>
</Value>
</Data>
<Data name="SearchParameters">
<Attribute>SearchParameters</Attribute>
<Structure>subnode</Structure>
<Subscript>"SearchParameters"</Subscript>
</Data>
<DataLocation>^Collections.SearchParam7440D</DataLocation>
<DefaultData>SearchParameterCollectionDefaultData</DefaultData>
<IdLocation>^Collections.SearchParam7440D</IdLocation>
<IndexLocation>^Collections.SearchParam7440I</IndexLocation>
<StreamLocation>^Collections.SearchParam7440S</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
