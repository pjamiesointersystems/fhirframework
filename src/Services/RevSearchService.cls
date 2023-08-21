Class Services.RevSearchService Extends (%Persistent, %JSON.Adaptor)
{

/// The fully qualifed path of the profiles-resources.json
/// Note well: the Definitions directory must be put into the container under /data
Parameter FHIRRevIncludeFileName = "/data/Definitions/profiles-resources.json";

Property RevIncludeParams As array Of Collections.RevSearchParameterCollection(SQLTABLENAME = "RevIncludeParameters");

Index reverseIncludIndex On RevIncludeParams(KEYS) [ Type = bitmap ];

Property revSearchLevel As %Integer;

Property typeLevel As %Integer;

Property revSearchType As %String;

Property typeName As %String;

/// The loader program getting reverse include rinformation
Method %OnNew() As %Status
{
    Set sc = $$$OK
    //check and see if RevIncludeParams already populated
    If (##class(Services.RevSearchService).%ExistsId(1)){
         Set temp = ##class(Services.RevSearchService).%OpenId(1, , .sc)
         If '$ISOBJECT(temp){
             Do $SYSTEM.Status.DisplayError(sc) Quit:sc
         } 
         Set rsp = temp.RevIncludeParams
         Set ..RevIncludeParams = rsp
    }
    Else {
        Set rsp = ""
    }
   
    //no search parameters were peristed, must rebuild
    If ('$DATA(rsp) || (rsp = "")){
        Do ..ReadFHIRRevInclude()
        Set sc = $THIS.%Save()
          If $$$ISERR(sc)
          {
            Do $SYSTEM.Status.DisplayError(sc) Quit:sc
          }
    }

    //Do ..WriteRevIncludeParameters()


    Return sc
}

Method AddRevSearchParam(revSearchP As BaseTypes.RevSearchParameter, baseName As %String) As %Status
{
    Set sc = $$$OK
    Set revSearchParamCol = ..RevIncludeParams.GetAt(baseName)
    If (revSearchParamCol = ""){
        Set revSearchParamCol = ##class(Collections.RevSearchParameterCollection).%New(baseName)
        Set status = revSearchParamCol.%Save()
        Do revSearchParamCol.AddRevSearchParam(revSearchP, revSearchP.BaseResource)
        Do ..RevIncludeParams.SetAt(revSearchParamCol, baseName)
    }
    Else {
        Do revSearchParamCol.AddRevSearchParam(revSearchP, revSearchP.BaseResource)
    }

    Return sc
}

/// Read the FHIR rev search parameter (profiles-resources) file
Method ReadFHIRRevInclude() As %Status
{
    
    Set sc = $$$OK
    Try {
    Set FhirRevIncludeObj = {}.%FromJSONFile(..#FHIRRevIncludeFileName)
    }
    Catch err {
        Write !, "Error name: ", ?20, err.Name,
              !, "Error code: ", ?20, err.Code,
              !, "Error location: ", ?20, err.Location,
              !, "Additional data: ", ?20, err.Data, !
        Set sc = $$$ERROR($$$GeneralError,"could not read file as json")
        Write !, "could not read profiles-resouces file as json"
        Return sc      
    }
    Set i = FhirRevIncludeObj.entry.%GetIterator()
    While i.%GetNext(.key , .fhirPath ) {
        Do ..RecursiveRead(.key, .fhirPath, 0, "")
    }
    
    Return sc
}

Method RecursiveRead(key, fhirarg, level, upkey) As %Status
{
    Set sc = $$$OK
    If ($ISOBJECT(fhirarg)) && (fhirarg.%IsA("%Library.DynamicArray")) {
         Set i = fhirarg.%GetIterator()
          //Write ?5*level, "Iterating over Dynamic Array - Current Key = "_key, !
          Set superkey = key
          While i.%GetNext(.fkey, .fpath){
            Do ..RecursiveRead(.fkey, .fpath, level + 1, .superkey)
        }
    }
    ElseIf ($ISOBJECT(fhirarg)) && (fhirarg.%IsA("%Library.DynamicObject")){
            Set i = fhirarg.%GetIterator()
            //Write ?5*level,"Iterating over Dynamic Object - Current Key = "_key, !
            While i.%GetNext(.fkey, .fpath){
            Set superkey = key    
            Do ..RecursiveRead(.fkey, .fpath, level + 1, .superkey)
            }
    }
    Else {
             If (key = "type"){
                Set ..typeLevel = level
                Set ..typeName = fhirarg 
                //Write ?5*level, "Level= "_level_" ", key_"="_fhirarg, !
            }


            If (upkey = "searchRevInclude"){
                Set ..revSearchLevel = level
                Set ..revSearchType = fhirarg
                // Write ?5*level, "Level= "_level_" ", upkey_"="_fhirarg, !
                If ((..revSearchLevel - ..typeLevel) = 1){
                    //we know the type will be the target resource
                    Set revres = ##class(BaseTypes.RevSearchParameter).%New(..typeName, ..revSearchType)
                    Do ..AddRevSearchParam(revres, ..typeName) 
                }
            }
         }

    Return sc
}

Method WriteRevIncludeParameters() As %Status
{
    Set key = ""
    Do ..RevIncludeParams.GetNext(.key)
    While (key '= ""){
        Set val = ..RevIncludeParams.GetAt(.key)
        Write "Array: Current Key = "_key_" with value= "_val, !
        Do val.WriteRevSearchParameters()
        Do ..RevIncludeParams.GetNext(.key)
    }
}

Method GetRevIncludeForResource(resName As %String) As Collections.RevSearchParameterCollection
{
   Set result =  ..RevIncludeParams.GetAt(resName)
   Return result
}

Storage Default
{
<Data name="RevIncludeParams">
<Attribute>RevIncludeParams</Attribute>
<Structure>subnode</Structure>
<Subscript>"RevIncludeParams"</Subscript>
</Data>
<Data name="RevSearchServiceDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>revSearchLevel</Value>
</Value>
<Value name="3">
<Value>typeLevel</Value>
</Value>
<Value name="4">
<Value>revSearchType</Value>
</Value>
<Value name="5">
<Value>typeName</Value>
</Value>
</Data>
<DataLocation>^Services.RevSearchServiceD</DataLocation>
<DefaultData>RevSearchServiceDefaultData</DefaultData>
<IdLocation>^Services.RevSearchServiceD</IdLocation>
<IndexLocation>^Services.RevSearchServiceI</IndexLocation>
<StreamLocation>^Services.RevSearchServiceS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
