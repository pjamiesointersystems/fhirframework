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

ClassMethod GetResourceCount(res As %String = "") As %Integer
{
    Set statement=##class(%SQL.Statement).%New()   
    Set sc = statement.%PrepareClassQuery("Services.FHIRPathQuery","ResourceCount")   
   
    If $$$ISERR(sc) {
    Do $SYSTEM.OBJ.DisplayError(sc) 
    }
  
    Set resultset=statement.%Execute(res)
    Do resultset.%Next()
    Set result= resultset.%Get("Count")
    Return result
}

ClassMethod GetFhirPathExp(res As %String, sp As %String) As %String
{
    Set statement=##class(%SQL.Statement).%New()   
    Set sc = statement.%PrepareClassQuery("Services.FHIRPathQuery","FHIRPathExp")   
    If $$$ISERR(sc) {
    Do $SYSTEM.OBJ.DisplayError(sc) 
    }
  
    Set resultset=statement.%Execute(res, sp)   
    Do resultset.%Next() 
    Set fp = resultset.%Get("Expression")
    Return fp
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
        Do $SYSTEM.OBJ.DisplayError(tSC) 
    }


    Return sc
}

// take a fhir path expresion and use it to evaluate against a resource

// exp is a fhirpath EvalFHIRPathExpression

// res is a resource

ClassMethod EvalFHIRPathExpression(exp As %String, res As %String, matchArray As %Library.ArrayOfDataTypes)
{
    Try {
        Set fhirPathAPI = ##class(HS.FHIRPath.API).getInstance($LISTBUILD("hl7.fhir.r4.core@4.0.1"))
        Set exptree = fhirPathAPI.parse(exp)
        Set resultArray = fhirPathAPI.evaluateToJson(res, exptree)
        //Write !, exp
        //Write !, resultArray.%ToJSON()
        Do ..BuildMatchExpressions(exp, resultArray, .matchArray)
        
    }
    Catch ex {
        Set tSC=ex.AsStatus()
        Do $SYSTEM.OBJ.DisplayError(tSC) 
    }
}

ClassMethod EvalFHIRPathExpOne(exp As %String, res As %String) As %String
{
    Try {
        Set fhirPathAPI = ##class(HS.FHIRPath.API).getInstance($LISTBUILD("hl7.fhir.r4.core@4.0.1"))
        Set exptree = fhirPathAPI.parse(exp)
        Set result = fhirPathAPI.evaluateToJson(res, exptree)
        Write !, exp
        Write !, result.%ToJSON()
        Return result
    }
    Catch ex {
        Set tSC=ex.AsStatus()
        Do $SYSTEM.OBJ.DisplayError(tSC) 
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
        Do $SYSTEM.OBJ.DisplayError(tSC) 
        Return 0
    }
}

ClassMethod BuildMatchExpressions(pkey As %String, exp As %DynamicArray, matchArray As %Library.ArrayOfDataTypes)
{
    //Set matchArray =##class(%Library.ArrayOfDataTypes).%New()
    Do ..IterateOverFhirObject(pkey, exp, .matchArray)
}

ClassMethod PrintArray(col As %Library.ArrayOfDataTypes)
{
    ; iterate over contents of array
    Write !
    Set key=""
	For  Set value=col.GetNext(.key) Quit:key=""   Write key,":",value,!
}

ClassMethod CreateJson(col As %Library.ArrayOfDataTypes) As %Library.DynamicObject
{
    ; iterate over contents of array
    Set key=""
    
    Set allresults = []
    Set val = col.GetNext(.key)
    While val {
        //mp are matching parameters, which is a dynamic array
        Set result = {}
        Set mp = val.GetMatchValsArray()
        Set ja = mp.%ToJSON()
        Do result.%Set(key, mp)
        //Write !, result.%ToJSON()
        Set val = col.GetNext(.key)
        Do allresults.%Push(result)
    }

    //Write !, allresults
    //Write !, allresults.%ToJSON()
    //Return allresults
    Set ar = {}
    Do ar.%Set("result", allresults)
    Return ar
    //Return ar.%ToJSON()
}

ClassMethod IterateOverFhirObject(pkey As %String, exp As %DynamicObject, matchArray As %Library.ArrayOfDataTypes)
{
   Try {   
    If $CLASSNAME(exp) = "%Library.DynamicObject"{
        #dim iterator As %Iterator.Object
        Set iterator = exp.%GetIterator()
        While iterator.%GetNext(.key , .fhirPath ){
            If $ISVALIDNUM(fhirPath){
                 Do ..AddMatchInfo(fhirPath, pkey_"."_key, .matchArray)
            }
            ElseIf $CLASSNAME(fhirPath) = "%Library.DynamicObject"{
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
            If $ISVALIDNUM(fhirPath){
                 Do ..AddMatchInfo(fhirPath, pkey_"."_key, .matchArray)
            }
            ElseIf $CLASSNAME(fhirPath) = "%Library.DynamicObject"{
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
         Write !, exp
    }
   }
    Catch ex {
        Set tSC=ex.AsStatus()
        Do $SYSTEM.OBJ.DisplayError(tSC) 
    }
}

ClassMethod FhirPathSample(res As %String, exp As %String) As %String
{
    //holds the result of evaluation of FHIRPath expression against list of resources
    Set resultArray = []
    //holds the result of evaluation of one FHIRPath expression
    Set fhirPathArray = []
    //holds a array of all matches against a sample of resources (n=10)
    Set matchArray =##class(%Library.ArrayOfDataTypes).%New()
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
        Do ..EvalFHIRPathExpression(exp, resJson, .matchArray)
        //Write !, matchArray.Count()
        //Write fhirPathArray.%ToJSON(), !
        //Write response.Json.%ToJSON(), !
    }

    //Write !, "Nearly Done"
    //Write !, matchArray.Count()
    Set results = ..CreateJson(.matchArray)
    //Do ..PrintArray(matchArray)
    //Write !, results
    Return results
}

ClassMethod TransformFhirPathExpression(exp As %String) As %String
{
    Set newstr=$REPLACE(exp,"-",".")
    Return newstr
}

// Take a simple fhirpath expression consisting of resource and elements

// , and sample values over 10 resources

ClassMethod FHIRPathValues(res As %String, sp As %String) As %Library.DynamicArray
{
   Set exp = ..GetFhirPathExp(res, sp)
   If exp = "" {
       //see if replacing sp (search parameter) "-" with "."
       Set exp = ..TransformFhirPathExpression(sp)
   }


   If exp '= "" {
      Set output = ..FhirPathSample(res, exp)
      Set valArray = output.result
      If ($CLASSNAME(valArray) = "%Library.DynamicArray"){
        #dim iterator As %Iterator.Object
        Set iterator = valArray.%GetIterator()
        Do iterator.%GetNext(.key,.vals) 
        If ($CLASSNAME(vals) = "%Library.DynamicObject"){
            Set iterator = vals.%GetIterator()
            Do iterator.%GetNext(.key,.finalvals) 
            Return finalvals
        }
        Else {
            Return vals
        }
      }
      Else {
          Return valArray
      }
      
   }
   Else {
      Return []
   }
}

// Take in a fhirpath expression, and sample it over 10 resources

ClassMethod FHIRPathRest(exp As %String) As %String
{
    Set res = $PIECE(exp, ".", 1)
    Set result = ..FhirPathSample(res, exp)
    //Write !, result
    Return result
}

ClassMethod FhirPathTest() As %Status
{
    /* Set url = "/csp/healthshare/demo/fhir/r4"
    Set fhirService = ##class(HS.FHIRServer.Service).EnsureInstance(url)
    Set request = ##class(HS.FHIRServer.API.Data.Request).%New()
    Set request.RequestPath = "/Patient/1"
    Set request.RequestMethod = "GET"
    Do fhirService.DispatchRequest(request, .response) */
    //Write response.Json.%ToJSON()
    //Do ##class(Services.FHIRPathService).GetIdsforResource("Claim")
    //Do ##class(Services.FHIRPathService).FhirPathSample("Patient", "Patient.extension")
    //Do ##class(Services.FHIRPathService).FhirPathSample("Patient", "Patient.identifier")
    //Do ##class(Services.FHIRPathService).FhirPathSample("Patient", "Patient.extension.where(url='http://hl7.org/fhir/StructureDefinition/patient-birthPlace')")
    //Set res = response.Json
    //Do ..EvalFHIRPathExpOne("Patient.name.given[0]", res)
    //Do ..EvalFHIRPathExpOne("Patient.extension", res)
    //Do ..EvalFHIRPathExpOne("Patient.extension.where(url='http://hl7.org/fhir/StructureDefinition/patient-birthPlace')", res)
    //Do ..EvalFHIRPathExpOne("Patient.extension.valueAddress.where(country='US')", res)
    //Do ..EvalFHIRPathExpOne("Patient.extension.valueAddress", res)
    //Do ..EvalFHIRPathExpOne("Patient.extension.valueString", res)
    //Do ..EvalFHIRPathExpOne("Patient.extension.url", res)
    //Do ..EvalFHIRPathExpOne("Patient.identifier.system", res)
    //Do ..EvalFHIRPathExpOne("Patient.identifier.where(system='http://hospital.smarthealthit.org')", res)
    //Do ..EvalFHIRPathExpOne("Patient.identifier.type.coding.where(code='MR')", res)
    //Do ..EvalFHIRPathExpOne("Patient.name", res)
    //Do ..EvalFHIRPathExpOne("Patient.telecom.exists(system='phone')", res)
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
