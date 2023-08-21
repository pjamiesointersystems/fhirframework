Class Framework.Main Extends %RegisteredObject
{

/// The loader program for testing various classes and methods
Method %OnNew() As %Status
{
   
    Set sc = $$$OK
    //Set res = ##class(Services.ResourceService).%New()
    //Set res = ##class(Services.SearchParamService).%New()
    //Set res = ##class(Services.RevSearchService).%New()
    //Do ##class(Rest.FHIRSearchRest).GetResources()
    //Do ##class(Rest.FHIRSearchRest).GetSearchParameters("Account")
    //Do ##class(Rest.FHIRSearchRest).GetRevSearchInclude("Account")
    //Do ##class(Rest.FHIRSearchRest).EvalFhirExp("Patient.extension")
    //Do ##class(Rest.FHIRSearchRest).EvalFhirExp("Patient.extension.where(url='http://hl7.org/fhir/StructureDefinition/patient-birthPlace')")
    //Do ##class(Rest.FHIRSearchRest).GetSampleVals("Patient", "address-city")

    //set status =##class(HS.FHIRServer.Config.REST.v1).GetEndpoints()
    //set flag = ##class(HS.FHIRServer.ServiceAdmin).EndpointExists("/csp/healthshare/demo/fhir/r4")
    Do ##class(HS.FHIRServer.Config.REST.v1).GetEndpoints()
    //Do ##class(Rest.FHIRSearchRest).DeleteFhirServer("test")
   //Do ##class(Rest.FHIRSearchRest).CreateFhirServer("test")
    //Do ##class(Services.FHIRServerService).CreateFhirServerUsingQueue("test")
    //Set files = []
    //Set sc=##class(Services.FHIRServerService).GetDirectoryTree("/twst1","*.json",.files)
    Set pCount = 0
    //Set sc=##class(Rest.FHIRSearchRest).GetFileCount()
    //Write sc
    //Do ##class(Services.FHIRServerService).LoadSampleData( "test", "/data/fhirdata/1000Set") 
    //Do ##class(Services.FHIRServerService).SampleLoadProgress("test", .logger)
    Return sc
}

}
