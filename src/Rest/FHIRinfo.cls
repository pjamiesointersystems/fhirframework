Include HS.FHIRServer

Class Rest.FHIRinfo Extends CorsRest
{

Parameter Version = "1.0.0";

Parameter CONTENTTYPEJSON As STRING = "application/json";

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
<Route Url="/fhirdetails/ns" Method="GET" Call="GetFHIRns" Cors="true" />
<Route Url="/fhirdetails/:np" Method="GET" Call="FHIRDetails" Cors="true"/>
<Route Url="/fhirdetails/:np/repostatistics/:repoId" Method="GET" Call="FHIRRepoStats" Cors="true" />
<Route Url="/fhirdetails/:np/reindex/:repoId" Method="GET" Call="FHIRreindex" Cors="true" />
<Route Url="/fhirdetails/:np/fhirlog/enabledchannels" Method="GET" Call="GetChannels" Cors="true" />
<Route Url="/fhirdetails/:np/fhirlog/data" Method="GET" Call="FHIRLogdata" Cors="true" />
<Route Url="/fhirdetails/:np/fhirlog/clearlog" Method="GET" Call="ClearLog" Cors="true" />
<Route Url="/fhirdetails/:np/fhirlog/setchannels" Method="Post" Call="SetChannels" Cors="true" />
<Route Url="/fhirdetails/postFile" Method="Post" Call="PostFile" Cors="true" />
</Routes>
}

// this will return a list of FHIR enabled namespaces

ClassMethod GetFHIRns() As %Status
{
    Set sc = $$$OK
    Try {
        set returnObj = {}
        set results = []
        set nslist = ##class(HS.HealthConnect.FHIRMeta.Upgrade.Base).GetListOfFHIREnabledNamespaces()
        SET ptr=0,count=0
        WHILE $LISTNEXT(nslist,ptr,value) {
         SET count=count+1
         Do results.%Push($SELECT($DATA(value):value,1:"omitted"))
        }
        do returnObj.%Set("ns", results)
        Return ..%ProcessResult(sc, returnObj)
        Return sc
    }
    catch ex {
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

ClassMethod writeJsonResponse(json As %DynamicObject) As %Status
{
    #dim %response As %CSP.Response
	Set %response.ContentType = ..#CONTENTTYPEJSON
	write json.%ToJSON()
	return $$$OK
}

ClassMethod FHIRreindex(np As %String, repoId As %String)
{
    Set temp = $NAMESPACE
    Set $NAMESPACE = np
    set status = ##class(HS.FHIRServer.Config.REST.v1).Reindex(repoId)
    Set $NAMESPACE = temp
    return status
}

ClassMethod FHIRLogdata(np As %String) As %Status
{
    Try {
    Set sc = $$$OK
    Set temp = $NAMESPACE
    Set $NAMESPACE = np
    set firstRow = 1
    set lastRow = ##class(HS.FHIRServer.Config.FHIRLogHandler).GetLogCount()
    if (lastRow = 0){
        set results = []
        set body = {}
        do body.%Set("rows", results)
        Set $NAMESPACE = temp
        do ..EmitResult(body)
    }
    else {
        set logs = ##class(HS.FHIRServer.Config.FHIRLogHandler).GetLogData(1, lastRow)
        Set $NAMESPACE = temp
        do ..EmitResult(logs)
    }
    
    Return sc
    }
    catch ex {
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

ClassMethod FHIRresourceCount(np As %String, repoId As %String) As %Status
{
    Try {
    Set temp = $NAMESPACE
    Set $NAMESPACE = np
    #dim repo as HS.FHIRServer.Repo = ##class(HS.FHIRServer.Repo).%OpenId(repoId)
    set fhirPackage = repo.searchClassesPackage
	set tablePrefix = $translate(fhirPackage, ".", "_")
    set tablename = $E(tablePrefix,1,$L(tablePrefix)-1)
    set resourceTable = tablename_"R.Rsrc"
    Set SQL = "SELECT count(ID) FROM "_resourceTable
    Set statement = ##class(%SQL.Statement).%New()
	Set tSC = statement.%Prepare(SQL)
	$$$ThrowOnError(tSC)
	Set resultSet = statement.%Execute()
	While resultSet.%Next() {
		Set count = resultSet.%GetData(1)
    }
    set info = {}
    do info.%Set("totalResources", count)
   
    Return ..%ProcessResult($$$OK, info)
    }
    catch ex {
          Set sc = ex.AsStatus()
          Do $SYSTEM.Status.DisplayError(sc)
          Set msg = "%Status exception"
          Set code = ex.Code
          Set data = $LISTGET(ex.Data,1)
          Set error = {}
          Set error.Message = msg
          Set error.Code = code
          Set error.data = data
          Set $NAMESPACE = temp
          Return ..%ProcessResult($$$OK, error)
        }
}

ClassMethod FHIRRepoStats(np As %String, repoId As %String) As %Status
{
    Try {
    Set temp = $NAMESPACE
    Set $NAMESPACE = np
    set status = ##class(HS.FHIRServer.Config.REST.v1).GetRepoStatistics(repoId)
    Set $NAMESPACE = temp
    return status
    }
    catch ex {
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

ClassMethod FHIRDetails(np As %String) As %Status
{
    #dim tCookie As %String
    #dim tMsgArray As %DynamicArray = []
    Set sc = $$$OK
    Try {
        Set temp = $NAMESPACE
        Set $NAMESPACE = np
        set array = []
		set list = ##class(HS.FHIRServer.API.InteractionsStrategy).GetEndpointInfo()
		set pendingEndpoints = ##class(HS.FHIRServer.Config.Setup).ReturnPendingEndpoints(0)
        set setup = ##class(HS.FHIRServer.Config.Setup).GetSetup()
		set ptr = 0
		while $listnext(list, ptr, entry) {
			set url = $listget(entry, 1)
			if url [ "svc:" continue //Endpoints without a URL aren't active, in process of being generated
			set repoId = $listget(entry, 6)
			set endpoint = ##class(HS.FHIRServer.Config.RestHandler).SerializeEndpoint(url, pendingEndpoints)
			if endpoint '= "" {
				do array.%Push(endpoint)
			}
		}
        //set the namespace back to its original value
		Set $NAMESPACE = temp
        //check to see if FHIR Validation operational
        set fhirvalidation = {}
        set fhivalidation = ##class(Rest.FHIRinfo).CheckFHIRValidationServer()
        if (fhirvalidation.status = 1){
            set status = "true"
        }
        else {
            set status = "false"
        }
        //create a new object with both results attached
        set alldetails = {}
        do alldetails.%Set("fhirvalidation", status)
        do alldetails.%Set("namespace", np)
        do alldetails.%Set("setup", setup)
        do alldetails.%Set("details", array)
        do ..EmitResult(alldetails)
        #; do ..EmitResult(array)
        Return sc		
	} catch ex {
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

ClassMethod CheckFHIRValidationServer() As %DynamicAbstractObject
{
    set isRunning = "not running"
    try {
        set runObject = {}
        set isRunning = $system.external.isServerRunning("FHIR_Validation_Server")
        set runObject.status = 1
        set runObject.message = "FHIR Validation running"
        return runObject
    }
    catch ex {
          Set sc = ex.AsStatus()
          //Do $SYSTEM.Status.DisplayError(sc)
          Set msg = "%Status exception"
          Set code = ex.Code
          Set data = $LISTGET(ex.Data,1)
          Set runObject = {}
          Set runObject.Message = msg
          Set runObject.Code = code
          Set runObject.data = data
          Set runObject.message = "FHIR Validation not running"
          Set runObject.status = 0
          return runObject
    }
    return runObject
}

ClassMethod EmitResult(pPayload As %DynamicAbstractObject = "")
{
	#dim %response As %CSP.Response
	If pPayload = "" {
		Set %response.Status = ..#HTTP204NOCONTENT
	} Else {
		Set %response.ContentType = ..#CONTENTTYPEJSON
		Write pPayload.%ToJSON()
	}
}

ClassMethod SetChannels(np As %String) As %Status
{
    Set sc = $$$OK
    Try {
        Set temp = $NAMESPACE
        Set $NAMESPACE = np
        //set channels = {}.%FromJSON(%request.Content)
        Set channels = %request.Content
	    Do ##class(HS.FHIRServer.Config.FHIRLogHandler).SetEnabledChannels($ListFromString(channels.disable), $ListFromString(channels.enable))
        Do ..GetChannels(np)
        Set $NAMESPACE = temp
        Return sc
    } catch ex {
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

ClassMethod GetChannels(np As %String) As %Status
{
    Set sc = $$$OK
    Try {
        Set temp = $NAMESPACE
        Set $NAMESPACE = np
        Set returnObj = {}
        Set results = []
        Set channels = ##class(HS.FHIRServer.Config.FHIRLogHandler).GetEnabledChannels()
        SET ptr=0,count=0
        WHILE $LISTNEXT(channels,ptr,value) {
        SET count=count+1
        Do results.%Push($SELECT($DATA(value):value,1:"omitted"))
        }
        Do returnObj.%Set("enabledChannels", results)
        //set the namespace back to its original value
        Set $NAMESPACE = temp
        Return ..%ProcessResult(sc, returnObj)		
    } catch ex {
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

ClassMethod ClearLog(np As %String) As %Status
{
    Set sc = $$$OK
    Try {
        Set temp = $NAMESPACE
        Set $NAMESPACE = np
        kill $$$FSLogGlobal
	    Set lastClear = $ZDT($H,3,7)
	    Set $$$FSLogGlobal("since") = lastClear
        //GO BACK TO ORIGINAL NS
        Set $NAMESPACE = temp
        Set returnObj = {"operation": "log cleared"}
        Return ..%ProcessResult(sc, returnObj)	
    }
    catch ex {
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

ClassMethod PostFile() As %Status
{
    Try {
        Set info = {}
        write %request
        #; Set source = %request.GetMimeData("fhirfile")
        #; Set destination=##class(%Stream.FileBinary).%New()
        #; Set destination.Filename="/data/temp/fhirdata/"_source.FileName
        #; set tSC=destination.CopyFrom(source) //reader open the file
        #; set result=destination.%Save()
        #; set info.return = result
        set info.message = "File saved into /data/temp/fhirdata/"_source.FileName
       
        Set %response.ContentType = ..#CONTENTTYPEJSON
        Set %response.Headers("Access-Control-Allow-Origin")="*"
 
        //Write info.%ToJSON()
        Set tSC=$$$OK
    }
    catch ex {
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

}
