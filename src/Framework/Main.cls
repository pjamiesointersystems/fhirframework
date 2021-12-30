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
    //Do ##class(Rest.FHIRSearchRest).FhirPathTest()
    //Do ##class(Rest.FHIRSearchRest).GetSearchParameters("Account")
    //Do ##class(Rest.FHIRSearchRest).GetRevSearchInclude("Account")
    //Do res.ReadFHIRSchema()
    //Do res.ReadFHIRSearchParams()
    //Do res.ReadFHIRRevInclude()
    //Do ##class(Services.FHIRPathService).FhirPathTest()
    //Do ##class(Rest.FHIRSearchRest).EvalFhirExp("Patient.extension")
    //Do ##class(Rest.FHIRSearchRest).EvalFhirExp("Patient.extension.where(url='http://hl7.org/fhir/StructureDefinition/patient-birthPlace')")
    Do ##class(Rest.FHIRSearchRest).GetSampleVals("Encounter", "patient")
    Return sc
}

}
