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
<Route Url="/createFhirServer/:serverPath" Method="Get" Call="CreateFhirServer"  Cors="true"/>
<Route Url="/deleteFhirServer/:serverPath" Method="Get" Call="DeleteFhirServer" Cors="true"/>
<Route Url="/info" Method="GET" Call="GetInfo" Cors="true"/>
<Route Url="/resources" Method="GET" Call="GetResources" Cors="true" />
<!-- GET method to return collection of search parameters for a given resource -->
<Route Url="/searchparams/:id" Method="GET" Call="GetSearchParameters" Cors="true" />
<!-- GET method to return collection of reverse include parameters for a given resource -->
<Route Url="/reverseinclude/:id" Method="GET" Call="GetRevSearchInclude" Cors="true" />
<!-- GET method to return result of FHIR path expression evaluation -->
<Route Url="/evalFhirexp/:exp" Method="GET" Call="EvalFhirExp" Cors="true" />
<!-- GET method to return count of FHIR resources in FHIR repository-->
<Route Url="/fhircount/:exp" Method="GET" Call="GetResourceCount" Cors="true" />
<!-- GET method to return sample values from Fhir Search-->
<Route Url="/fhirval/:res/:sp" Method="GET" Call="GetSampleVals" Cors="true" />
<Route Url="/fhirdata/:dir" Method="GET" Call="GetDirectories" Cors="true" />
<Route Url="/fhircount" Method="GET" Call="GetFileCount" Cors="true" />
<Route Url="/fhirload/:np" Method="GET" Call="LoadFhirData" Cors="true" />
<Route Url="/fhirload/progress/:np" Method="GET" Call="ProgressLoadFhirData" Cors="true" />
</Routes>
}

/// Description
ClassMethod DeleteFhirServer(np As %String) As %Status
{
    #dim tCookie As %String
    #dim tMsgArray As %DynamicArray = []

    Set sc = $$$OK
    Try {
         #; Capture output
         Set tSC=##class(%Atelier.v1.Utils.General).BeginCaptureOutput(.tCookie)
         If $$$ISERR(tSC) Quit
         Set retVal = ##class(Services.FHIRServerService).DeleteFHIRServer(np)
          #; MUST close the redirect whatever happens
         If $DATA(tCookie) Do ##class(%Atelier.v1.Utils.General).EndCaptureOutput(tCookie,.tMsgArray)
         If $$$ISERR(sc) Quit
         If (retVal = 0) Quit
         Set msg = "Fhir Server "_np_" deleted"
         Set statusCode = 1
         Set result = {}
         Set result.msg = msg
         Set result.statusCode = statusCode
         Return ..%ProcessResult($$$OK, result)
    }
    Catch ex {
          If (retVal = 0){
            Set msg = "%Status exception"
            Set code = "Fhir server not deleted, internal error"
          }
          Else {
            Set sc = ex.AsStatus()
            Do $SYSTEM.Status.DisplayError(sc)
            Set msg = "%Status exception"
            Set code = ex.Code
            Set data = $LISTGET(ex.Data,1)
          }
          
          Set error = {}
          Set error.Message = msg
          Set error.Code = code
          Set error.data = data
          Set $NAMESPACE = "DEMO"
          Return ..%ProcessResult($$$OK, error)
    }
}

ClassMethod CreateFhirServer(np As %String) As %Status
{
    #dim tCookie As %String
    #dim tMsgArray As %DynamicArray = []
    Set sc = $$$OK
    Try {
        #; Capture output
         //Set tSC=##class(%Atelier.v1.Utils.General).BeginCaptureOutput(.tCookie)
         //Set retVal = ##class(Services.FHIRServerService).CreateFHIRServer(np)
         Job ##class(Services.FHIRServerService).CreateFHIRServer(np)
         //Set retVal = ##class(Services.FHIRServerService).CreateFhirServerUsingQueue(np)
         //If $DATA(tCookie) Do ##class(%Atelier.v1.Utils.General).EndCaptureOutput(tCookie,.tMsgArray)
         //If $$$ISERR(tSC) Quit
         Set msg = "Fhir Server "_np_" creation in progress..."
         Set statusCode = 1
         Set result = {}
         Set result.msg = msg
         Set result.statusCode = statusCode
         Return ..%ProcessResult($$$OK, result)
    }
    Catch ex {
          Set sc = ex.AsStatus()
          Do $SYSTEM.Status.DisplayError(sc)
          Set msg = "%Status exception"
          Set code = ex.Code
          Set data = $LISTGET(ex.Data,1)
          Set error = {}
          Set error.Message = msg
          Set error.Code = code
          Set error.data = data
          Return ..%ProcessResult($$$OK, error)
        }
}

ClassMethod GetSampleVals(res As %String, sp As %String) As %String
{
    Set result = ##class(Services.FHIRPathService).FHIRPathValues(res, sp)
    If (result '= ""){
        Return ..%ProcessResult($$$OK, result)
    }
    Else {
        Return ..%ProcessResult($$$OK, [])
    }
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
  Set fhirservers = []
  Set sc =  ##class(Services.FHIRServerService).FindFhirServers(.fhirservers)
  Return ..%ProcessResult($$$OK, fhirservers)
}

ClassMethod GetDirectories(root As %String) As %String
{
  Set fhirdirs = []
  Try {
     $$$TOE(sc, ##class(Services.FHIRServerService).GetDirectoryTree("/"_root,"*.json",.fhirdirs))
     Return ..%ProcessResult($$$OK, fhirdirs)
  }
  Catch ex {
        Set sc = ex.AsStatus()
        //Do $SYSTEM.Status.DisplayError(sc)
        Set msg = "%Status exception"
        Set code = ex.Code
        Set data = $LISTGET(ex.Data,1)
        Set error = {}
        Set error.Message = msg
        Set error.Code = code
        Set error.data = data_" does not exists"
        Return ..%ProcessResult($$$OK, error)
  }
}

ClassMethod GetFileCount() As %String
{
  Set fhirdirs = []
  Set pathRequest = %request.Data("path",1)
  Set newRequest = $REPLACE(pathRequest, "'", "")
  Set pCount = 0
  Set fhirCount = {}
  Try {
     $$$TOE(sc, ##class(Services.FHIRServerService).GetFileCount(newRequest,"*.json", .pCount))
     Set fhirCount.count = pCount
     Return ..%ProcessResult($$$OK, fhirCount)
  }
  Catch ex {
        Set sc = ex.AsStatus()
        //Do $SYSTEM.Status.DisplayError(sc)
        Set msg = "%Status exception"
        Set code = ex.Code
        Set data = $LISTGET(ex.Data,1)
        Set error = {}
        Set error.Message = msg
        Set error.Code = code
        Set error.data = data_" does not exists"
        Set fhirCount.count = 0
        Return ..%ProcessResult($$$OK, fhirCount)
  }
}

ClassMethod LoadFhirData(np As %String) As %String
{
  Set fhirdirs = []
  Set pathRequest = %request.Data("path",1)
  Set newRequest = $REPLACE(pathRequest, "'", "")
  Set pCount = 0
  Set fhirCount = {}
  Set fhirCount.message = "Loading json bundles into namespace="_np_" using path="_newRequest
  Try {
     $$$TOE(sc, ##class(Services.FHIRServerService).GetFileCount(newRequest,"*.json", .pCount))
     Set fhirCount.count = pCount
     Job ##class(Services.FHIRServerService).LoadSampleData(np, newRequest)
     
     Return ..%ProcessResult($$$OK, fhirCount)
  }
  Catch ex {
        Set sc = ex.AsStatus()
        //Do $SYSTEM.Status.DisplayError(sc)
        Set msg = "%Status exception"
        Set code = ex.Code
        Set data = $LISTGET(ex.Data,1)
        Set error = {}
        Set error.Message = "Unable to load bundles"
        Set error.Code = code
        Set error.data = data
        Return ..%ProcessResult($$$OK, error)
  }
}

ClassMethod ProgressLoadFhirData(np As %String) As %String
{
  Set fhirlog = {}
  Try {
     $$$TOE(sc, ##class(Services.FHIRServerService).SampleLoadProgress(np, .fhirlog))     
     Return ..%ProcessResult($$$OK, fhirlog)
  }
  Catch ex {
        Set sc = ex.AsStatus()
        //Do $SYSTEM.Status.DisplayError(sc)
        Set msg = "%Status exception"
        Set code = ex.Code
        Set data = $LISTGET(ex.Data,1)
        Set error = {}
        Set error.Message = "Unable to determine progress"
        Set error.Code = code
        Set error.data = data
        Return ..%ProcessResult($$$OK, error)
  }
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

}
