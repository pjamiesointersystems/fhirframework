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

ClassMethod DeleteFHIRServer(np As %String) As %Integer
{
    If (##class(%SYS.Namespace).Exists(np)){
        Set $NAMESPACE = np
    }

    Try {
        Set appKey= "/csp/healthshare/"_np_"/fhir/r4"
        Do ##class(HS.FHIRServer.Installer).UninstallInstance(appKey)
        //this is the primary namespace for FHIR tools
        Set $NAMESPACE = "DEMO"
        Return 1
    }
    Catch ex {
        Set tSC=ex.AsStatus()
        Do $SYSTEM.Status.DisplayError(tSC)
        Set $NAMESPACE = "DEMO"
        Return 0
    }
}

///  Query the progress in loading sample data
ClassMethod SampleLoadProgress(np As %String, log As %Library.DynamicObject) As %Status
{
    Set sc = $$$OK
    Try {
        Set $NAMESPACE = np
        Set log = {}
        Set key = ""
    For {
        Set key = $ORDER(^fhirlogs(key))
        Quit:key=""
        
        Set val = $GET(^fhirlogs(key))
        Do log.%Set(key, val)
        }
        Set $NAMESPACE = "DEMO"
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

/// Load sample data into newly created FHIRServer
ClassMethod LoadSampleData(np As %String, path As %String) As %Status
{
    // example path to resources 
    // example serve path  np=Demo "/csp/healthshare/fhir/demo/r4"
    Set sc = $$$OK
    Set appKey= "/csp/healthshare/"_np_"/fhir/r4"
    Try {
        Set $NAMESPACE = np
        Kill ^fhirlogs  
        $$$TOE(sc, ##class(HS.FHIRServer.Tools.DataLoader).SubmitResourceFiles(path, "FHIRServer", appKey, 1, "^fhirlogs"))
        //Set status = ##class(HS.FHIRServer.Tools.DataLoader).SubmitResourceFiles(path, "FHIRServer", appKey)
        Set $NAMESPACE = "DEMO"
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

ClassMethod AddMap(packageName As %String, datadb As %String)
{
    Set Namespace = "%ALL"
    Set $NAMESPACE = "%SYS"
    Set Properties("Database")= datadb
    //Set status = $SYSTEM.Config.MapPackages.Create(Namespace,packageName,.Properties)
    Set status = ##class(Config.MapPackages).Create(Namespace,packageName,.Properties)
    If ('status=$$$OK){
        Do $SYSTEM.Status.DisplayError(status)
    }
}

/// Description - for a new FHIR server definition add some packages
/// from the demo namespace or other namespace to target database
ClassMethod AddPackageMappings(np As %String) As %Status
{
    Set sc = $$$OK

    Try {
        //determine if the %ALL namespace exists, and set it if it does
        If (##class(%SYS.Namespace).Exists("%ALL")){
            
        }
        Else {
            // if not create it
            Set $NAMESPACE = "HSLIB"
            Do ##class(HS.HC.Util.Installer).InstallFoundation("%ALL")
            Set $NAMESPACE = "%ALL"
        }  
    }
    Catch ex {
        Set tSC=ex.AsStatus()
    }
    Set Namespace = np
    Set Properties("Database")= np
    
    Do ..AddMap("Rest", np)
    Do ..AddMap("Services", np)
    Do ..AddMap("BaseTypes", np)
    Do ..AddMap("Collections", np)
    Do ..AddMap("Framework", np)

    Return sc
}

/// This will create a FHIR server asynchronously using a work queue
ClassMethod CreateFhirServerUsingQueue(np As %String) As %Status
{
    Set sc = $$$OK
   
    Set queue = ##class(%SYSTEM.WorkMgr).Initialize(, .sc)
    If $$$ISERR(sc){
        Return sc
    }
    Set sc = queue.QueueCallback("..CreateFHIRServer", "##class(Services.FHIRServerService).CompleteQueue", np)
     If $$$ISERR(sc){
        Return sc
    }

    Set sc= queue.Wait("cuk",.AtEnd)
    If $$$ISERR(sc){
        Return sc
    }

    Return sc
}

/// Call back method from Work Queue Manager
ClassMethod CompleteQueue(np As %String) As %Status
{
    Set sc = $$$OK
    Write %job, !
    Write %staus, !
    Write %workqueue, !
    Set %exit = 1
    Return sc
}

/// Configure a FHIR Server in a namespace that already exist
ClassMethod CreateFHIRServer(np As %String) As %Integer
{
    Set sc = $$$OK
    Set tSC = $$$OK
    Set appKey= "/csp/healthshare/"_np_"/fhir/r4"
    Set strategyClass = "HS.FHIRServer.Storage.Json.InteractionsStrategy"
    Try {
        //determine if the namespace exists, and set it if it does
        If (##class(%SYS.Namespace).Exists(np)){
            Set $NAMESPACE = np
        }
        Else {
            // if not create it
            Set $NAMESPACE = "HSLIB"
            Do ##class(HS.HC.Util.Installer).InstallFoundation(np)
            Set $NAMESPACE = np
        }  
    }
    Catch ex {
        Set tSC=ex.AsStatus()
        Do $SYSTEM.Status.DisplayError(tSC)
        Set $NAMESPACE = "DEMO"
        Return 0
    }
    //next determine if the fhir sever already exists
    If (##class(HS.FHIRServer.Installer).CSPAppExists(appKey)){
        Write "FHIR server exists at path:"_appKey
        Return 0
    }
    Else {
        Set metadataPackages = $LISTBUILD("hl7.fhir.r4.core@4.0.1","hl7.fhir.us.core@3.1.0")
        Do ##class(HS.FHIRServer.Installer).InstallNamespace()
        Do ##class(HS.FHIRServer.Installer).InstallInstance(appKey, strategyClass, metadataPackages)
        Set strategy = ##class(HS.FHIRServer.API.InteractionsStrategy).GetStrategyForEndpoint(appKey)
        Set configData = strategy.GetServiceConfigData()
        Set configData.DefaultSearchPageSize = 1000
        Set configData.MaxSearchPageSize = 1000
        Set configData.MaxSearchResults = 1000
        Do strategy.SaveServiceConfigData(configData)
    }

    Set $NAMESPACE = "DEMO"
    
    Return 1
}

/* ClassMethod GetFileTree(pFolder As %String, pWildcards As %String = "*", Output oFiles) As %Status
{
    Set fileset=##class(%ResultSet).%New("%Library.File:FileSet")
    Set sc=fileset.Execute(##class(%File).NormalizeDirectory(pFolder),pWildcards,,1)
    While $$$ISOK(sc),fileset.Next(.sc) {
        If fileset.Get("Type")="D" {
            Set sc=..GetFileTree(fileset.Get("Name"),pWildcards,.oFiles)
        } Else {
            Set oFiles(fileset.Get("Name"))=""
        }    
    }
    Quit sc
} */
ClassMethod ExcludeDirName(dir As %String) As %Boolean
{
    Set lastPart = $PIECE(dir, "/", *)
    Set lastLength = $LENGTH(lastPart)
    If (lastLength > 0){
        Set firstChar = $EXTRACT(lastPart, 1)
        If ((firstChar = ".") || ($LOCATE(lastPart, "ifconfig"))){
            Return 1
        }
        Else {
            Return 0
        }
    }
    Else {
        Return 0
    }
}

ClassMethod GetDirectoryTree(pFolder As %String, pWildcards As %String = "*", oFiles As %Library.DynamicArray) As %Status
{
    Set fileset=##class(%ResultSet).%New("%Library.File:FileSet")
    Set sc=fileset.Execute(##class(%File).NormalizeDirectory(pFolder),pWildcards,,1)
    While $$$ISOK(sc),fileset.Next(.sc) {
        If (fileset.Get("Type")="D"){
            Set fileName = fileset.Get("Name")
            If ('..ExcludeDirName(fileName)){
                Do oFiles.%Push(fileName)
                Set sc=..GetDirectoryTree(fileName,pWildcards,.oFiles)
            }
        }   
    }
    Quit sc
}

ClassMethod GetFileCount(pFolder As %String, pWildcards As %String = "*", pCount As %Integer) As %Status
{
    Set oFiles = []
    Set fileset=##class(%ResultSet).%New("%Library.File:FileSet")
    Set sc=fileset.Execute(##class(%File).NormalizeDirectory(pFolder),pWildcards,,1)
    While $$$ISOK(sc),fileset.Next(.sc) {
        If '(fileset.Get("Type")="D"){
            Set fileName = fileset.Get("Name")
            If ('..ExcludeDirName(fileName)){
                Do oFiles.%Push(fileName)
            }
        }   
    }
    Set pCount =  oFiles.%Size()
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
