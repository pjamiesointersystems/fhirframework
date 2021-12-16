Class Services.FHIRPathService Extends %Persistent
{

/// The base url for the server
Parameter baseUrl = "/csp/healthshare/demo/fhir/r4";

ClassMethod GetIdsforResource(res As %String = "") As %Library.DynamicArray
{
    Set idArray = []
    Set statement=##class(%SQL.Statement).%New()   
    Set sc = statement.%PrepareClassQuery("Services.FHIRPathQuery","GetResIds")   
    If $$$ISERR(sc) {
    Do $SYSTEM.OBJ.DisplayError(sc) 
    }
  
    Set resultset=statement.%Execute(res)   
    While resultset.%Next() {
    Do idArray.%Push(resultset.%Get("ResourceId"))
    //Write !, resultset.%Get("ResourceId")   
    }
    Return idArray
}

ClassMethod AddMatchInfo(matchExp As %String, key As %String, matchArray As %Library.ArrayOfDataTypes) As %Status
{
    Set sc = $$$OK
    Try {
    Set matchExpressions = matchArray.GetAt(key)
    If (matchExpressions = ""){
        Set matchExpressions = ##class(BaseTypes.MatchParameter).%New(matchExp)
        Do matchArray.SetAt(matchExpressions, key)
    }
    Else {
            Do matchExpressions.AddVal(matchExp)
        }
    }
     Catch ex {
        Set tSC=ex.AsStatus()
    }


    Return sc
}

// take a fhir path expresion and use it to evaluate against a resource

// exp is a fhirpath EvalFHIRPathExpression

// res is a resource

ClassMethod EvalFHIRPathExpression(exp As %String, res As %String) As %Library.DynamicArray
{
    Try {
        Set fhirPathAPI = ##class(HS.FHIRPath.API).getInstance($LISTBUILD("hl7.fhir.r4.core@4.0.1"))
        Set exptree = fhirPathAPI.parse(exp)
        Set resultArray = fhirPathAPI.evaluateToJson(res, exptree)
        //Write !, exp
        //Write !, resultArray.%ToJSON()
        Do ..BuildMatchExpressions(exp, resultArray)
        Return resultArray
        
    }
    Catch ex {
        Set tSC=ex.AsStatus()
        Return []
    }
}

ClassMethod CountFHIRPathExpression(exp As %String, res As %String) As %Numeric
{
    Try {
        Set fhirPathAPI = ##class(HS.FHIRPath.API).getInstance($LISTBUILD("hl7.fhir.r4.core@4.0.1"))
        Set exptree = fhirPathAPI.parse(exp)
        Set resultArray = fhirPathAPI.evaluateToJson(res, exptree)
        Return resultArray.%Size()
    }
    Catch ex {
        Set tSC=ex.AsStatus()
        Return 0
    }
}

ClassMethod BuildMatchExpressions(pkey As %String, exp As %DynamicArray)
{
    Set matchArray =##class(%Library.ArrayOfDataTypes).%New()
    Do ..IterateOverFhirObject(pkey, exp, .matchArray)
     //return the results
        Set val = "" 
        Do matchArray.GetNext(.val)
        While $LENGTH(val) > 0 {
        Write !, val 
        Set matchParameter = matchArray.GetAt(val)
        Set matchVals = matchParameter.GetMatchVals()
        Do ..PrintList(matchVals, 5)
        Do matchArray.GetNext(.val)
    }
}

ClassMethod PrintList(col As %Collection.ListOfDT, padding As %Numeric)
{
    ; iterate over contents of list
    Write !
    For i=1:1:col.Count()  Write ?padding, col.GetAt(i),!
}

ClassMethod IterateOverFhirObject(pkey As %String, exp As %DynamicObject, matchArray As %Library.ArrayOfDataTypes)
{
    If $CLASSNAME(exp) = "%Library.DynamicObject"{
        #dim iterator As %Iterator.Object
        Set iterator = exp.%GetIterator()
        While iterator.%GetNext(.key , .fhirPath ){
            If $CLASSNAME(fhirPath) = "%Library.DynamicObject"{
                //Write !, pkey_"."_key
                Do ..IterateOverFhirObject(pkey_"."_key, fhirPath, .matchArray)
            }
            ElseIf $CLASSNAME(fhirPath) = "%Library.DynamicArray"{
                //Write !, pkey
                Do ..IterateOverFhirObject(pkey, fhirPath, .matchArray)
            }
            Else {
                 //Write !, pkey_"."_key_"="_fhirPath
                 Do ..AddMatchInfo(fhirPath, pkey_"."_key, .matchArray)
            }
        }
    }
    ElseIf $CLASSNAME(exp) = "%Library.DynamicArray"{
        #dim iterator2 As %Iterator.Array
        Set iterator2 = exp.%GetIterator()
        While iterator2.%GetNext(.key , .fhirPath ){
            If $CLASSNAME(fhirPath) = "%Library.DynamicObject"{
                //Write !, pkey
                Do ..IterateOverFhirObject(pkey, fhirPath, .matchArray)
            }
            ElseIf $CLASSNAME(fhirPath) = "%Library.DynamicArray"{
                //Write !, pkey
                Do ..IterateOverFhirObject(pkey, fhirPath, .matchArray)
            }
            Else {
                 //Write !, pkey_"="_fhirPath
                 Do ..AddMatchInfo(fhirPath, pkey_"."_key, .matchArray)
            }
        }
    }
    Else {
         //Write !, exp
    }
}

ClassMethod FhirPathSample(res As %String, exp As %String)
{
    //holds the result of evaluation of FHIRPath expression against list of resources
    Set resultArray = []
    //holds the result of evaluation of one FHIRPath expression
    Set fhirPathArray = []
    Set baseUrl = ..#baseUrl
    Set fhirService = ##class(HS.FHIRServer.Service).EnsureInstance(baseUrl)
    Set request = ##class(HS.FHIRServer.API.Data.Request).%New()
    Set idArray = ..GetIdsforResource(res)
    Set request.RequestMethod = "GET"
    Set id = idArray.%Pop()
    //make a request to FHIR server to get each resouce by Id
    While id '= "" {
        Set request.RequestPath = "/"_res_"/"_id
        Set id = idArray.%Pop()
        Do fhirService.DispatchRequest(request, .response)
        Set resJson = response.Json
        Set fhirPathArray = ..EvalFHIRPathExpression(exp, resJson)
        Write fhirPathArray.%ToJSON(), !
        //Write response.Json.%ToJSON(), !
    }
}

ClassMethod FhirPathTest() As %Status
{
    //Set url = "/csp/healthshare/demo/fhir/r4"
    //Set fhirService = ##class(HS.FHIRServer.Service).EnsureInstance(url)
    //Set request = ##class(HS.FHIRServer.API.Data.Request).%New()
    //Set request.RequestPath = "/Claim"
    //Set request.RequestMethod = "GET"
    //Do fhirService.DispatchRequest(request, .response)
    //Write response.Json.%ToJSON()
    //Do ##class(Services.FHIRPathService).GetIdsforResource("Claim")
    Do ##class(Services.FHIRPathService).FhirPathSample("Patient", "Patient.extension")
    //Set res = response.Json
    //Do ..EvalFHIRPathExpression("Patient.name.given[0]", res)
    //Do ..EvalFHIRPathExpression("Patient.identifier", res)
    //Do ..EvalFHIRPathExpression("Patient.identifier.system", res)
    //Do ..EvalFHIRPathExpression("Patient.identifier.where(system='http://hospital.smarthealthit.org')", res)
    //Do ..EvalFHIRPathExpression("Patient.identifier.type.coding.where(code='MR')", res)
    //Do ..EvalFHIRPathExpression("Patient.name", res)
    //Do ..EvalFHIRPathExpression("Patient.telecom.exists(system='phone')", res)
    //Set telecount = ..CountFHIRPathExpression("Patient.telecom", res)
    //Write !, "Telecom count = "_telecount
}

Storage Default
{
<Data name="FHIRPathServiceDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^Services.FHIRPathServiceD</DataLocation>
<DefaultData>FHIRPathServiceDefaultData</DefaultData>
<IdLocation>^Services.FHIRPathServiceD</IdLocation>
<IndexLocation>^Services.FHIRPathServiceI</IndexLocation>
<StreamLocation>^Services.FHIRPathServiceS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
