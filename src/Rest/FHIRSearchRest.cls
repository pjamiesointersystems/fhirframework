Class Rest.FHIRSearchRest Extends Rest.SearchRest
{

Parameter Version = "1.0.0";

/// Default the Content-Type for this application.
Parameter CONTENTTYPE = "application/json";

/// By default convert the input stream to Unicode
Parameter CONVERTINPUTSTREAM = 1;

/// The default response charset is utf-8
Parameter CHARSET = "utf-8";

Parameter %JSONNULL = 1;

Parameter %JSONIGNORENULL = 1;

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<!-- Server Info -->
<Route Url="/info" Method="GET" Call="GetInfo" Cors="true"/>
<Route Url="/resources" Method="GET" Call="GetResources" Cors="true"/>
<!-- GET method to return collection of search parameters for a given resource -->
<Route Url="/searchparams/:id" Method="GET" Call="GetSearchParameters"/>
<!-- GET method to return collection of reverse include parameters for a given resource -->
<Route Url="/reverseinclude/:id" Method="GET" Call="GetRevSearchInclude"/>
</Routes>
}

/// FHIRSearchRest general information
ClassMethod GetInfo() As %Status
{
  Set version = ..#Version
  Set info = {
    "version": (version)
  }
  Return ..%ProcessResult($$$OK, info)
}

/// Get and Return a list of all FHIR resources
/// 
ClassMethod GetResources() As %Status
{
    Set sc = $$$OK
  

    Set resService = ##class(Services.ResourceService).%New()
    If '$ISOBJECT(resService){
        Set %response.Status = ..#HTTP404NOTFOUND
        Set error = {"errormessage": "Resource Service not found"}
        Write error.%ToJSON()
        Quit $$$OK
    }

    Set resources = resService.resourceNames
   

    If '$ISOBJECT(resources){
        Set %response.Status = ..#HTTP404NOTFOUND
        Set error = {"errormessage": "Resources in Resource Service not found"}
        Write error.%ToJSON()
        Quit $$$OK
    }

    //Set resourcesJSON = ""
    //Do resources.%JSONExport()
    //Set sc = resources.%JSONExportToString(.resourcesJSON)
    //Throw:$$$ISERR(sc) $$$ERROR($$$GeneralError, "Couldn't execute resource list to json conversion") 
    Set resourcesString = ..ResourcesToJson(resources)
    Set result = {}
    Set result.Resources = resourcesString
    Return ..%ProcessResult($$$OK, result)
}

ClassMethod ResourcesToJson(res As %Collection.ListOfDT) As %String
{
    Set JSON = "["
    For i=1:1:res.Count(){
      Set JSON = JSON_res.GetAt(i)_", "
    }

    Set JSON = $EXTRACT(JSON, 1, *-2)
    Set JSON = JSON_"]"
    Return JSON
}

ClassMethod GetSearchParameters(id As %String) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException

    Set sc = $$$OK
    //Set %response.ContentType = ..#CONTENTTYPEJSON
    Set spService = ##class(Services.SearchParamService).%New()
    If '$ISOBJECT(spService){
        Set %response.Status = ..#HTTP404NOTFOUND
        Set error = {"errormessage": "Search Parameter Service not found"}
        Write error.%ToJSON()
        Quit $$$OK
    }

    Set spParameters = spService.GetParamsForResource(id)
    If '$ISOBJECT(spParameters){
        Set %response.Status = ..#HTTP404NOTFOUND
        Set message = "No Search Parameters found for"_id
        Set error = {}
        Set error.message = message
        Write error.%ToJSON()
        Quit $$$OK
    }

    Set searchParametersforResource = spParameters.SearchParameters
    Set result = ..SearchParamsToJson(searchParametersforResource)
    //Set result.SearchParameters = searchJSON
    //Set resJson = resources.%JSONExport()
    Do ..%ProcessJson($$$OK, result)

    Return sc
}

ClassMethod GetRevSearchInclude(id As %String) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException

    Set sc = $$$OK
    //Set %response.ContentType = ..#CONTENTTYPEJSON
    Set spService = ##class(Services.RevSearchService).%New()
    If '$ISOBJECT(spService){
        Set %response.Status = ..#HTTP404NOTFOUND
        Set error = {"errormessage": "Rev Search  Service not found"}
        Write error.%ToJSON()
        Quit $$$OK
    }

    Set spParameters = spService.GetRevIncludeForResource(id)
    If '$ISOBJECT(spParameters){
        Set %response.Status = ..#HTTP404NOTFOUND
        Set message = "No Rev Include Parameters found for"_id
        Set error = {}
        Set error.message = message
        Write error.%ToJSON()
        Quit $$$OK
    }

    Set revSearchIncludeforResource = spParameters.RevSearchParameters
    Set result = ..RevSearchParamsToJson(revSearchIncludeforResource)
    Do ..%ProcessJson($$$OK, result)

    Return sc
}

ClassMethod SearchParamsToJson(sp As %ArrayOfObjects) As %String
{
    Set searchJsonList = ##class(%ListOfDataTypes).%New()
    //Set JSON = ##class(%DynamicArray).%New()
    Set key = ""
    Do sp.GetNext(.key)
    While (key '= ""){
        Set val = sp.GetAt(.key)
        Set valJson = ..ConvertSearchParameterToJson(.val) 
        //Set valJson = val.%JSONExport()
        Do searchJsonList.Insert(valJson)
        //Write ?5, "Key = "_key_" with value= "_val.ToString(), !
        Do sp.GetNext(.key)
    }

    //now loop through searchJSON and create JSON String
    Set result = "{"""_"SearchParameters"_""""_" : "_"["
    For i=1:1:searchJsonList.Count(){
        Set spo = searchJsonList.GetAt(i)
        Set result = result_spo_"," 
    } 

    Set result = $EXTRACT(result, 1, *-1)
    Set result = result_"]}"

    Return result
}

ClassMethod RevSearchParamsToJson(sp As %ArrayOfObjects) As %String
{
    Set searchJsonList = ##class(%ListOfDataTypes).%New()
    Set key = ""
    Do sp.GetNext(.key)
    While (key '= ""){
        Set val = sp.GetAt(.key)
        Set valJson = ..ConvertRevSearchParameterToJson(.val) 
        Do searchJsonList.Insert(valJson)
        Do sp.GetNext(.key)
    }

    //now loop through revsearchJSON and create JSON String
    Set result = "{"""_"RevSearchParameters"_""""_" : "_"["
    For i=1:1:searchJsonList.Count(){
        Set spo = searchJsonList.GetAt(i)
        Set result = result_spo_"," 
    } 

    Set result = $EXTRACT(result, 1, *-1)
    Set result = result_"]}"

    Return result
}

/// Description
ClassMethod ConvertSearchParameterToJson(val As BaseTypes.SearchParameter) As %String
{
    Set name = val.Name
    Set version = val.Version
    Set experimental = val.Experimental
    Set description = val.Description
    Set type = val.Type
    Set comparator = ..DynamicArrayToJson(val.Comparator)
    Set resTarget = ..DynamicArrayToJson(val.ResTarget)
    Set JSON = "{"
    Set JSON = JSON_""""_"Name"""_":"_""""_name_""","
    Set JSON = JSON_""""_"Version"""_":"_""""_version_""","
    Set JSON = JSON_""""_"Experimental"""_":"_""""_experimental_""","
    Set JSON = JSON_""""_"Description"""_":"_""""_description_""","
    Set JSON = JSON_""""_"Type"""_":"_""""_type_""","
    Set JSON = JSON_""""_"Comparator"""_":"_""""_comparator_""","
    Set JSON = JSON_""""_"ResTarget"""_":"_""""_resTarget_""""
    Set JSON = JSON_"}"
    Return JSON
}

ClassMethod ConvertRevSearchParameterToJson(val As BaseTypes.RevSearchParameter) As %String
{
    Set targetResource = val.TargetResource
    Set baseResource = val.BaseResource
    Set searchField = val.SearchField
    Set JSON = "{"
    Set JSON = JSON_""""_"TargetResource"""_":"_""""_targetResource_""","
    Set JSON = JSON_""""_"BaseResource"""_":"_""""_baseResource_""","
    Set JSON = JSON_""""_"SearchField"""_":"_""""_searchField_""""
    Set JSON = JSON_"}"
    Return JSON
}

/// Description
ClassMethod DynamicArrayToJson(dyn As %DynamicArray) As %String
{
    Set sz = dyn.%Size()
    If (sz = 0){
         Return "[]"
    }
       
    Set key = ""
    Set value = ""
    Set result = "["
    Set iter = dyn.%GetIterator()
    While iter.%GetNext(.key , .value ) {
        Set result = result_value_","
     }

    Set result = $EXTRACT(result, 1, *-1)
        
    Set result = result_"]"
    Return result
    //Return dyn.%ToJSON()
}

ClassMethod CompareArrays2(ByRef pFirst, ByRef pSecond, Output pMessage) As %Boolean
{
    Set pMessage = ""
    Return:(($DATA(pFirst) '= 10) || ($DATA(pSecond) '= 10)) $GET(pFirst) = $GET(pSecond)
    Merge First = pFirst
    Merge Second = pSecond
    Set Key = $ORDER(First(""))
    
    /// Iterate over first array
    While (Key '= "") {
        
        /// $Data on undefined var does not modify second argument
        Kill SecondVal
        
        /// If the second array does not have the same subscript
        /// or the values are different, quit
        If (($DATA(Second(Key), SecondVal) = 0) || ($GET(SecondVal) '= First(Key))) {
            Set pMessage = "Different subscripts at " _ Key
            Return $$$NO
        } Else {
            /// Otherwise remove this element from the second array
            /// In here: Second(Key) = First(Key)
            Kill Second(Key)
        }
        Set Key = $ORDER(First(Key))
    }
    
    /// Second array should have no subscripts
    /// If there are any, that means they are not present
    /// in the first array, and so different
    If $DATA(Second) = 10 {
        Set pMessage = "Different subscripts at " _ $ORDER(Second(""))
        Return $$$NO        
    }
    
    Return $$$YES
}

}
