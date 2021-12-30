Class Services.FHIRServerService Extends %Persistent
{

/// find all fhir servers and their namespaces
ClassMethod FindFhirServers(results As %Library.DynamicArray) As %Status
{
    Set sc = $$$OK
    Set sc = ##class(%REST.API).GetAllWebRESTApps(.appList)
    For i=1:1:appList.Count() {
        Set tapp = appList.GetAt(i)
        If (tapp.dispatchClass = "HS.FHIRServer.RestHandler"){
            Set fhirserver = {}
            Set fhirserver.enabled = tapp.enabled
            Set fhirserver.endpoint = tapp.name
            Set fhirserver.namespace = tapp.namespace
            Do results.%Push(fhirserver)
        }

    }
    Return sc
}

Storage Default
{
<Data name="FHIRServerServiceDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^Services.FHIRServerServiceD</DataLocation>
<DefaultData>FHIRServerServiceDefaultData</DefaultData>
<IdLocation>^Services.FHIRServerServiceD</IdLocation>
<IndexLocation>^Services.FHIRServerServiceI</IndexLocation>
<StreamLocation>^Services.FHIRServerServiceS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
