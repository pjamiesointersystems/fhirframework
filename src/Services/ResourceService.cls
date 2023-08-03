Class Services.ResourceService Extends %Persistent
{

/// The fully qualifed path of the fhir.schema.json
/// Note well: the Definitions directory must be put into the container under /data
Parameter FHIRSchemaFileName = "/data/Definitions/fhir.schema.json";

Property resourceNames As list Of %String;

// Property resourceNames As array Of %String;

/// The loader program getting resource information
Method %OnNew() As %Status
{
    Set sc = $$$OK
    //check and see if resourceNames already populated
    If (##class(Services.ResourceService).%ExistsId(1)){
         Set temp = ##class(Services.ResourceService).%OpenId(1)
         Set rn = temp.resourceNames
         Set ..resourceNames = rn
    }
    else {
        Set temp = $THIS
        Set rn = ""
    }
   
    //no resourceNames were peristed, must rebuild
    If ('$DATA(rn) || (rn = "")){
        Do ..ReadFHIRSchema()
        Set temp.resourceNames = ..resourceNames
        Set sc = temp.%Save()
          If $$$ISERR(sc)
          {
            Do $SYSTEM.Status.DisplayError(sc) Quit:sc
          }
    }

    //Set i = ..resourceNames.%GetIterator()
    //While i.%GetNext(.fkey, .rName){
    //Write "Dynamic Array: Current Key = "_fkey_" with value= "_rName, !
    //}

    Return sc
}

/// read a file, with fhir schema properties and create an array of resources
Method ReadFHIRSchema() As %Status
{

    Set sc = $$$OK
    Try {
    Set FhirSchemaObj = {}.%FromJSONFile(..#FHIRSchemaFileName)
    }
    Catch err {
        Write !, "Error name: ", ?20, err.Name,
              !, "Error code: ", ?20, err.Code,
              !, "Error location: ", ?20, err.Location,
              !, "Additional data: ", ?20, err.Data, !
        Set sc = $$$ERROR($$$GeneralError,)
        Write !, "could not read schema file as json"
        Return sc
    }
    
    Set i = FhirSchemaObj.discriminator.mapping.%GetIterator()
    
    While i.%GetNext(.key , .fhirResourcePath ) {
        //Do ..resourceNames.SetAt(key, key)
        Do ..resourceNames.Insert(key)
    }


    Return sc
}

Storage Default
{
<Data name="ResourceServiceDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>resourceNames</Value>
</Value>
</Data>
<DataLocation>^Services.ResourceServiceD</DataLocation>
<DefaultData>ResourceServiceDefaultData</DefaultData>
<IdLocation>^Services.ResourceServiceD</IdLocation>
<IndexLocation>^Services.ResourceServiceI</IndexLocation>
<StreamLocation>^Services.ResourceServiceS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
