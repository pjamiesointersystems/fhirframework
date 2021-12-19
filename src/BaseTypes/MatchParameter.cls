Class BaseTypes.MatchParameter Extends (%Persistent, %JSON.Adaptor)
{

// unspecificied properties are exported as a null value

Parameter %JSONNULL = 1;

Parameter %JSONIGNORENULL = 1;

Property MatchVals As %DynamicArray;

Method %OnNew(matchVal As %String) As %Status
{
    Set ..MatchVals = []
    Do ..MatchVals.%Push(matchVal)

    Quit $$$OK
}

Method AddVal(matchVal As %String) As %Status
{
    Set iter = ..MatchVals.%GetIterator()
     While iter.%GetNext(.key , .value ) {
        If (value = matchVal){
            //we have already captured this value
            Return $$$OK
        }
     }

    //this value needs to be added
    Do ..MatchVals.%Push(matchVal)
    Return $$$OK
}

Method GetMatchVals() As %Collection.ListOfDT
{
    Set list=##class(%ListOfDataTypes).%New()
        Set iter = ..MatchVals.%GetIterator()
        While iter.%GetNext(.key , .value )
        {
        Do list.Insert(value)
        }

     Return list
}

Method GetMatchValsArray() As %Library.DynamicArray
{
    Return ..MatchVals
}

Storage Default
{
<Data name="MatchParameterDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<Data name="MatchVals">
<Attribute>MatchVals</Attribute>
<Structure>node</Structure>
<Subscript>"MatchVals"</Subscript>
</Data>
<DataLocation>^BaseTypes.MatchParameterD</DataLocation>
<DefaultData>MatchParameterDefaultData</DefaultData>
<IdLocation>^BaseTypes.MatchParameterD</IdLocation>
<IndexLocation>^BaseTypes.MatchParameterI</IndexLocation>
<StreamLocation>^BaseTypes.MatchParameterS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
