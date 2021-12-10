Class Services.SearchParamService Extends %Persistent
{

/// The fully qualifed path of the search-parameters.json
/// Note well: the Definitions directory must be put into the container under /data
/// 
Parameter FHIRSearchParamFileName = "/data/Definitions/search-parameters.json";

Property SearchParams As array Of Collections.SearchParameterCollection(SQLTABLENAME = "SearchParamaters");

Index searchResIndex On SearchParams(KEYS) [ Type = bitmap ];

/// The loader program getting resource information
Method %OnNew() As %Status
{
    Set sc = $$$OK
    //check and see if SearchParams already populated
    If (##class(Services.SearchParamService).%ExistsId(1)){
         Set temp = ##class(Services.SearchParamService).%OpenId(1, , .sc)
         If '$ISOBJECT(temp){
             Do $SYSTEM.Status.DisplayError(sc) Quit:sc
         } 
         Set sp = temp.SearchParams
         Set ..SearchParams = sp
    }
    Else {
        Set sp = ""
    }
   
    //no search parameters were peristed, must rebuild
    If ('$DATA(sp) || (sp = "")){
        Do ..ReadFHIRSearchParams()
        Set sc = $THIS.%Save()
          If $$$ISERR(sc)
          {
            Do $SYSTEM.Status.DisplayError(sc) Quit:sc
          }
    }

    //Do ..WriteSearchParameters()


    Return sc
}

Method GetBaseResource(resourceId As %String) As %String
{
    Return $PIECE(resourceId, "-", 1)
}

Method AddSearchParam(searchP As BaseTypes.SearchParameter, baseName As %String) As %Status
{
    Set sc = $$$OK
    Set searchParamCol = ..SearchParams.GetAt(baseName)
    If (searchParamCol = ""){
        Set searchParamCol = ##class(Collections.SearchParameterCollection).%New(baseName)
        Set status = searchParamCol.%Save()
        Do searchParamCol.AddSearchParam(searchP, searchP.Name)
        Do ..SearchParams.SetAt(searchParamCol, baseName)
    }
    Else {
        Do searchParamCol.AddSearchParam(searchP, searchP.Name)
    }

    Return sc
}

Method ScanForContainedText(searchString As %String, text As %String) As %Boolean
{
    Set pos = $FIND($ZCONVERT(text, "L"), $ZCONVERT(searchString, "L"))
    If (pos = 0){
        Return 0
    }
    Else {
        Return 1
    }
}

Method ReadFHIRSearchParams() As %Status
{
    
    Set sc = $$$OK
    Try {
    Set FhirSearchParamObj = {}.%FromJSON(..#FHIRSearchParamFileName)
    }
    Catch err {
        Write !, "Error name: ", ?20, err.Name,
              !, "Error code: ", ?20, err.Code,
              !, "Error location: ", ?20, err.Location,
              !, "Additional data: ", ?20, err.Data, !
        Set sc = $$$ERROR($$$GeneralError,"could not read file as json")
        Write !, "could not read search parameter file as json"
        Return sc      
    }
    Set i = FhirSearchParamObj.entry.%GetIterator()
    While i.%GetNext(.key , .fhirPath ) {
        //Write key_"="_fhirPath,!
        Set id = "", rtype = "", br = "", ver = "", sp = "", exp = "", des = "", ty = "", comp = "", tar = ""
        Set j = fhirPath.resource.%GetIterator()
        While j.%GetNext(.subkey, .subfhirPath){
            //Write subkey_"="_subfhirPath, !
            If (subkey = "resourceType"){
                Set rtype = subfhirPath
                Continue
            }
            If (subkey = "id"){
                Set br = ..GetBaseResource(subfhirPath)
                Set id = subfhirPath
                Continue
                //Write "Base Resource"_"="_br, !
            }
            If (subkey = "version"){
                Set ver = subfhirPath
                Continue
            }
            If (subkey = "name"){
                Set sp = subfhirPath
                Continue
            }
            If (subkey = "experimental"){
                Set exp = subfhirPath
                Continue
            }
            If (subkey = "description"){
                Set des = subfhirPath
                Continue
            }
            If (subkey = "type"){
                Set ty = subfhirPath
                Continue
            }
            If (subkey = "comparator"){
                Set comp = subfhirPath
                Continue
            }
            If ((ty = "reference") && (subkey = "target")){
                Set tar = subfhirPath
                Continue
            }
    }
        If (rtype = "SearchParameter"){
            Set lookForMultiResources = ..ScanForContainedText("multiple res", des)
            If (lookForMultiResources = 0){
                Set searchParameter = ##class(BaseTypes.SearchParameter).%New(br, sp, ver, exp, des, ty, .comp, .tar)
                //Set status = searchParameter.%Save()
                Do ..AddSearchParam(searchParameter, br)
            } Else {
                Write !, des
                Do ..FindAllResourceDescriptions(des)
            }
           
            //Do ..SearchParams.SetAt(searchParameter, id)
            //Write searchParameter.ToString(), !
            //Write searchParameter.ResTarget, !
            //Write "target instance class name: ",$CLASSNAME(searchParameter.ResTarget), !
        }
    }

    Return sc
}

Method FindAllResourceDescriptions(descriptions As %String) As %DynamicArray
{
    Set resNames = []
    Set resDescriptions = []
    Set matcher = ##class(%Regex.Matcher).%New("\[(.*)\](.*):(.*)")
    Set matcher.Text = descriptions
    While (matcher.Locate()) {
        Set resName = matcher.GroupGet(1)
        If $LENGTH(resName > 0) {
            Do resNames.%Push(resName)
        }
        Set resDescription = matcher.GroupGet(3)
        If $LENGTH(resDescription > 0) {
            Set wresDescription = $ZSTRIP(resDescription, "<>W")
            Do resDescriptions.%Push(wresDescription)
        }


    }

    Return resNames
}

Method GetParamsForResource(resName As %String) As Collections.SearchParameterCollection
{
   Set result =  ..SearchParams.GetAt(resName)
   Return result
}

Method WriteSearchParameters() As %Status
{
    Set key = ""
    Do ..SearchParams.GetNext(.key)
    While (key '= ""){
        Set val = ..SearchParams.GetAt(.key)
        Write "Array: Current Key = "_key_" with value= "_val, !
        Do val.WriteSearchParameters()
        Do ..SearchParams.GetNext(.key)
    }
}

Storage Default
{
<Data name="SearchParamServiceDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<Data name="SearchParams">
<Attribute>SearchParams</Attribute>
<Structure>subnode</Structure>
<Subscript>"SearchParams"</Subscript>
</Data>
<DataLocation>^Services.SearchParamServiceD</DataLocation>
<DefaultData>SearchParamServiceDefaultData</DefaultData>
<IdLocation>^Services.SearchParamServiceD</IdLocation>
<IndexLocation>^Services.SearchParamServiceI</IndexLocation>
<StreamLocation>^Services.SearchParamServiceS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
