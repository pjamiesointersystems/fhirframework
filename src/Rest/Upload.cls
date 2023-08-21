Class Rest.Upload Extends %CSP.REST
{

Parameter CHARSET = "utf-8";

// Parameter CONVERTINPUTSTREAM = 1;

Parameter CONTENTTYPE = "application/json";

Parameter Version = "1.0.0";

Parameter HandleCorsRequest = 1;

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
 
<Route Url="/postFile" Method="Post" Call="PostFile" />
<Route Url="/loadata/:np/repoId/:rp" Method="Get" Call="LoadData" />
<Route Url="/loadsample/:np/sampledir/:sn/repoId/:rp" Method="Get" Call="LoadSampleData" Cors="true" /> 
<Route Url="/deletedata/:np/repoId/:rp" Method="Get" Call="DeleteData" />
</Routes>
}

/// Load sample data into a FHIRServer
/// for now assume the first part of the directory path for sample
/// data is located at '/data/fhirdata'
ClassMethod LoadSampleData(np As %String, sampleName As %String, repoId As %String) As %Status
{
    // retrieve the path to the FHIRServer using the repoId
    // example serve path  np=Demo "/csp/healthshare/fhir/demo/r4"
    Set sc = $$$OK
    Set temp = $NAMESPACE
    Try {
        Set $NAMESPACE = np
        Set SQL = "SELECT cspUrl FROM HS_FHIRServer.RepoInstance where repo= ?"
	Set statement = ##class(%SQL.Statement).%New()
	Set tSC = statement.%Prepare(SQL)
	$$$ThrowOnError(tSC)
	Set resultSet = statement.%Execute(repoId)
	While resultSet.%Next() {
		Set cspUrl = resultSet.%GetData(1)
	}
        Kill ^fhirlogs  
        //the first argument is the dir path, for now assume /data/fhirdata
        //is the first part of the path, followed by sampleName
        //the second argument is the service type which should always be FHIRServer
        //the third argument is the endpoint path expression
        Set fullDir = "/data/fhirdata/"_sampleName
        $$$TOE(sc, ##class(HS.FHIRServer.Tools.DataLoader).SubmitResourceFiles(fullDir, "FHIRServer", cspUrl, 0, "^fhirlogs"))
        //Set status = ##class(HS.FHIRServer.Tools.DataLoader).SubmitResourceFiles(path, "FHIRServer", appKey)
        Set $NAMESPACE = temp
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
        Set error.data = data
        Set $NAMESPACE = "DEMO"
    }
    Return sc
}

ClassMethod PostFile() As %Status
{
    try {
        Set guid = $System.Util.CreateGUID()
        Set dir="/data/fhirdata/temp/"
        Set destination=##class(%Stream.FileBinary).%New()
        Set info = {}
        Set mimeCount = %request.CountMimeData("file")
        Set mimeData = %request.GetMimeData("file")
    
        Set fileType = mimeData.Attributes("ContentType")
        Set docType=$Select(fileType="application/json":"json",fileType="application/ndjson":"ndjson",fileType="text/plain":"txt",1:"json")
        Set destination.Filename = dir_guid_"."_docType
        do destination.CopyFrom(mimeData)
        set result = destination.%Save()
        set reader = ##class(%Net.MIMEReader).%New()
        Set source = %request.GetMimeData("file")
        
        //do reader.OpenStream(source)
        //set sc = reader.ReadMIMEMessage(.message)
        //set bd = message.Body
        //set part = message.Parts
        //set fn = part.GetHeader("filename")
        set info.message = "File saved into:"_destination.Filename
        set info.return = result
        set info.fileType = fileType
        set info.mimeCount = mimeCount
        set info.guid = guid
        Set %response.ContentType = ..#CONTENTTYPEJSON
        Set %response.Headers("Access-Control-Allow-Origin")="*"
        Write info.%ToJSON()
        Set tSC=$$$OK
    //returns error message to the user
    } catch e {
        Set tSC=e.AsStatus()
        Set pOutput = tSC
    }
 
    Quit tSC
}

// all json and ndjson bundles are assumed to have been uploaded to the dir

// '/data/fhirdata/temp'

ClassMethod LoadData(np As %String, repoId As %String) As %Status
{
    Set sc = $$$OK
    Set temp = $NAMESPACE
    Try {
        Set $NAMESPACE = np
        Set SQL = "SELECT cspUrl FROM HS_FHIRServer.RepoInstance where repo= ?"
	Set statement = ##class(%SQL.Statement).%New()
	Set tSC = statement.%Prepare(SQL)
	$$$ThrowOnError(tSC)
	Set resultSet = statement.%Execute(repoId)
	While resultSet.%Next() {
		Set cspUrl = resultSet.%GetData(1)
	}
        Kill ^fhirlogs  
        //the first argument is the dir path, for now assume /data/fhirdata/temp
        //is the first part of the path followed by dirname
        //the second argument is the service type which should always be FHIRServer
        //the third argument is the endpoint path expression
        Set fullDir = "/data/fhirdata/temp"
       $$$TOE(sc, ##class(HS.FHIRServer.Tools.DataLoader).SubmitResourceFiles(fullDir, "FHIRServer", cspUrl, 0, "^fhirlogs"))
        //Set status = ##class(HS.FHIRServer.Tools.DataLoader).SubmitResourceFiles(path, "FHIRServer", appKey)
        Set $NAMESPACE = temp
        //execute a shell command to remove the temporary json files
        //first change to the directory that we want to delete files
        Do ##class(%SYSTEM.Process).CurrentDirectory("/data/fhirdata/temp")
        //then execute a shell command
        Do $ZF(-100,"/SHELL","rm","*.*")
        Set info = {}
        set info.message = "Files successfully loaded.."
        set info.namespace = np
        set info.repoId = repoId
        Return ##class(Rest.FHIRinfo).%ProcessResult(sc, info)
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
        Set error.data = data
        Set $NAMESPACE = temp
        Set %response.ContentType = ..#CONTENTTYPEJSON
        //Set %response.Headers("Access-Control-Allow-Origin")="*"
        Return ##class(Rest.FHIRinfo).%ProcessResult(sc, error)
    }
    Return sc
}

// this method will remove all FHIR data from the endpoint, but

// will not remove the endpoint itself

ClassMethod DeleteData(np As %String, repoId As %String) As %Status
{
    Set sc = $$$OK
    Set temp = $Namespace
    set $Namespace = np
    try {
        //first, get the AppKey which is the same as the cspURL
        Set SQL = "SELECT cspUrl FROM HS_FHIRServer.RepoInstance where repo= ?"
	    Set statement = ##class(%SQL.Statement).%New()
	    Set tSC = statement.%Prepare(SQL)
	    $$$ThrowOnError(tSC)
	    Set resultSet = statement.%Execute(repoId)
	    While resultSet.%Next() {
		    Set cspUrl = resultSet.%GetData(1)
        }
        Set strategy = ##class(HS.FHIRServer.API.InteractionsStrategy).GetStrategyForEndpoint(cspUrl)
        Set options("deleteDataOnly") = 1
        Do strategy.Delete(.options)
        Set info = {}
        set info.message = "Files successfully deleted.."
        set info.namespace = np
        set info.repoId = repoId
        Do ##class(Rest.FHIRinfo).%ProcessResult(sc, info)
        set $Namespace = temp
        return sc
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
        Set error.data = data
        Set $NAMESPACE = temp
        Set %response.ContentType = ..#CONTENTTYPEJSON
        //Set %response.Headers("Access-Control-Allow-Origin")="*"
        Return ##class(Rest.FHIRinfo).%ProcessResult(sc, error)
    }
}

}
