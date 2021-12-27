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
<Route Url="/createFhirServer/:serverPath" Method="GET" Call="CreateFhirServer" Cors="true"/>
<Route Url="/deleteFhirServer/:serverPath" Method="GET" Call="DeleteFhirServer" Cors="true"/>
<Route Url="/info" Method="GET" Call="GetInfo" Cors="true"/>
<Route Url="/resources" Method="GET" Call="GetResources" />
<!-- GET method to return collection of search parameters for a given resource -->
<Route Url="/searchparams/:id" Method="GET" Call="GetSearchParameters" />
<!-- GET method to return collection of reverse include parameters for a given resource -->
<Route Url="/reverseinclude/:id" Method="GET" Call="GetRevSearchInclude" />
<!-- GET method to return result of FHIR path expression evaluation -->
<Route Url="/evalFhirexp/:exp" Method="GET" Call="EvalFhirExp" Cors="true" />
<!-- GET method to return count of FHIR resources in FHIR repository-->
<Route Url="/fhircount/:exp" Method="GET" Call="GetResourceCount" Cors="true" />
</Routes>
}

ClassMethod EvalFhirExp(exp As %String = "") As %String
{
  Set exp2 =  $GET(%request.Data("where",1))
  Set exp2 = $ZSTRIP(exp2, "*W")
  If '(exp2 = ""){
      Set fullquery = exp_".where"_exp2
      Set result = ##class(Services.FHIRPathService).FHIRPathRest(fullquery)
  }
  Else {
      Set result = ##class(Services.FHIRPathService).FHIRPathRest(exp)
  }
  
  Return ..%ProcessResult($$$OK, result)
}

/// FHIRSearchRest general information
ClassMethod GetInfo() As %String
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

ClassMethod GetResourceCount(res As %String)
{
    #dim e As %Exception.AbstractException

    Set sc = $$$OK
    Set result ={}
    If '(res = ""){
      Set count = ##class(Services.FHIRPathService).GetResourceCount(res)
      Set result.count = count 
    }
    Else {
      Set count = 0
      Set result.count = count
    }

    Return ..%ProcessResult($$$OK, result)
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

/// Load sample data into newly created FHIRServer
ClassMethod LoadSampleData(path As %String, np As %String) As %Status
{
    // example path to resources 
    // example serve path  np=Demo "/csp/healthshare/fhir/demo/r4"
    Set sc = $$$OK
    Set appKey= "/csp/healthshare/fhir/"_np_"/r4"
    Try {
        Set $NAMESPACE = np
        Set status = ##class(HS.FHIRServer.Tools.DataLoader).SubmitResourceFiles(path, "FHIRServer", appKey)
    }
    Catch ex {
        Set tSC=ex.AsStatus()
    }
    Return sc
}

ClassMethod AddMap(packageName As %String, datadb As %String)
{
    Set Namespace = "%ALL"
    Set $NAMESPACE = "%SYS"
    Set Properties("Database")= datadb
    //Set status = $SYSTEM.Config.MapPackages.Create(Namespace,packageName,.Properties)
    Set status = ##class(Config.MapPackages).Create(Namespace,packageName,.Properties)
    If ('status=$$$OK){
        Do $SYSTEM.Status.DisplayError(status)
    }
}

/// Description - for a new FHIR server definition add some packages
/// from the demo namespace or other namespace to target database
ClassMethod AddPackageMappings(np As %String) As %Status
{
    Set sc = $$$OK

    Try {
        //determine if the %ALL namespace exists, and set it if it does
        If (##class(%SYS.Namespace).Exists("%ALL")){
            
        }
        Else {
            // if not create it
            Set $NAMESPACE = "HSLIB"
            Do ##class(HS.HC.Util.Installer).InstallFoundation("%ALL")
            Set $NAMESPACE = "%ALL"
        }  
    }
    Catch ex {
        Set tSC=ex.AsStatus()
    }
    Set Namespace = np
    Set Properties("Database")= np
    
    Do ..AddMap("Rest", np)
    Do ..AddMap("Services", np)
    Do ..AddMap("BaseTypes", np)
    Do ..AddMap("Collections", np)
    Do ..AddMap("Framework", np)

    Return sc
}

/// Configure a FHIR Server in a namespace that already exist
ClassMethod CreateFHIRServer(np As %String) As %Status
{
    Set sc = $$$OK
    Set tSC = $$$OK
    Set appKey= "/csp/healthshare/fhir/"_np_"/r4"
    Set strategyClass = "HS.FHIRServer.Storage.Json.InteractionsStrategy"
    Try {
        //determine if the namespace exists, and set it if it does
        If (##class(%SYS.Namespace).Exists(np)){
            Set $NAMESPACE = np
        }
        Else {
            // if not create it
            Set $NAMESPACE = "HSLIB"
            Do ##class(HS.HC.Util.Installer).InstallFoundation(np)
            Set $NAMESPACE = np
        }  
    }
    Catch ex {
        Set tSC=ex.AsStatus()
    }
    //next determine if the fhir sever already exists
    If (##class(HS.FHIRServer.Installer).CSPAppExists(appKey)){
        Write "FHIR server exists at path:"_appKey
    }
    Else {
        Set metadataPackages = $LISTBUILD("hl7.fhir.r4.core@4.0.1","hl7.fhir.us.core@3.1.0")
        Do ##class(HS.FHIRServer.Installer).InstallNamespace()
        Do ##class(HS.FHIRServer.Installer).InstallInstance(appKey, strategyClass, metadataPackages)
        Set strategy = ##class(HS.FHIRServer.API.InteractionsStrategy).GetStrategyForEndpoint(appKey)
        Set configData = strategy.GetServiceConfigData()
        Set configData.DefaultSearchPageSize = 1000
        Set configData.MaxSearchPageSize = 1000
        Set configData.MaxSearchResults = 1000
        Do strategy.SaveServiceConfigData(configData)
    }

    
    Return sc
}

ClassMethod DeleteFHIRServer(np As %String) As %Status
{
    Set sc = $$$OK
    Set appKey= "/csp/healthshare/fhir/"_np_"/r4"
    Do ##class(HS.FHIRServer.Installer).UninstallInstance(appKey)
    Return sc
}

}
