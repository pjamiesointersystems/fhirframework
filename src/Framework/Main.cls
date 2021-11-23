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
    Do ##class(Rest.FHIRSearchRest).FhirPathTest()
    //Do ##class(Rest.FHIRSearchRest).GetSearchParameters("Account")
    //Do ##class(Rest.FHIRSearchRest).GetRevSearchInclude("Account")
    //Do res.ReadFHIRSchema()
    //Do res.ReadFHIRSearchParams()
    //Do res.ReadFHIRRevInclude()
    Return sc
}

}
