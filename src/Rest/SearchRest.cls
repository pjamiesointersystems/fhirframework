Class Rest.SearchRest Extends %CSP.REST [ System = 3 ]
{

Parameter CHARSET = "utf-8";

Parameter CONTENTTYPE = "application/json";

Parameter PAGESIZE As INTEGER = 200;

/// Description
Parameter HandleCorsRequest = 1;

ClassMethod OnPreDispatch(pUrl As %String, pMethod As %String, ByRef pContinue As %Boolean) As %Status
{
  Set tSC = $$$OK
  Try {
    
    // Set the return type according to the Accept type in the request. Default is application/json.
    If ('..AcceptsContentType(..#CONTENTTYPEJSON)) {
      Set tSC = ..ReportHttpStatusCode(..#HTTP406NOTACCEPTABLE), pContinue=0
      Quit 
        } Else {   
      // This always returns json
      Set %response.ContentType=..#CONTENTTYPEJSON
        }
        
        
        // read request object into %DynamicObject format
    If ((pMethod'="POST") && (pMethod'="PUT")) || (%request.Content="") {
      Set %request.Content = {}
    } Else {
      If '$ISOBJECT(%request.Content) {
        Set tContent = %request.Content
      } Else {
        Set tContent = ""
        While '%request.Content.AtEnd {
          Set tContent = tContent_%request.Content.Read()
        }
      }
      If (tContent="") {
        Set %request.Content = {}
      } Else {
        Set tContent = $ZCONVERT(tContent, "I", "UTF8")
        Set %request.Content = ##class(%Library.DynamicObject).%FromJSON(tContent)
      }
    }
        
  } Catch ex {
    Set tSC = ex.AsStatus()
  }
  Quit ##class(%iKnow.REST.Base).%ErrorHandler(tSC, .pContinue)
}

ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{

       Do %response.SetHeader("Access-Control-Allow-Credentials","true")
       Do %response.SetHeader("Access-Control-Allow-Methods","GET,POST,PUT,OPTIONS")
       Do %response.SetHeader("Access-Control-Allow-Origin","*")
       Quit 1
}

/// This is the CORS request handler. User should override this method in their subclass
/// if they don't want the default behavior
ClassMethod OnHandleCorsRequest(pUrl As %String) As %Status
{
  #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim %request As %CSP.Request
    #dim %response As %CSP.Response
    
    #dim tOrigin,tHeaders,tMethod As %String
    
    Try {
        
        #; Get the origin
        Set tOrigin=$GET(%request.CgiEnvs("HTTP_ORIGIN"))
            
        #; Allow requested origin
        Do %response.SetHeader("Access-Control-Allow-Origin","*")
       
        #; Set allow credentials to be true
        Do ..SetResponseHeaderIfEmpty("Access-Control-Allow-Credentials","true")
        
        #; Allow requested headers
        Set tHeaders=$GET(%request.CgiEnvs("HTTP_ACCESS_CONTROL_REQUEST_HEADERS"))
        Do ..SetResponseHeaderIfEmpty("Access-Control-Allow-Headers",tHeaders)
        
        #; Allow requested method
        Set tMethod=$GET(%request.CgiEnvs("HTTP_ACCESS_CONTROL_REQUEST_METHOD"))
        Do ..SetResponseHeaderIfEmpty("Access-Control-Allow-Methods","GET,POST,OPTIONS")
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
}

ClassMethod %ProcessResult(pStatus As %Status = {$$$OK}, pResult As %DynamicObject = "") As %Status [ Internal ]
{
  #dim %response As %CSP.Response
  Set tSC = $$$OK
  If $$$ISERR(pStatus) {
    Set %response.Status = 500
    Set tSC = ..StatusToJSON(pStatus, .tJSON)
    If $ISOBJECT(tJSON) {
      Set pResult = tJSON
    } Else {
      Set pResult = { "errors": [ { "error": "Unknown error parsing status code" } ] }
    }
  } 
  ElseIf pStatus=1 {
    If '$ISOBJECT(pResult){
      Set pResult = {
      }
    }
  }
  Else {
    Set %response.Status = pStatus
    Set error = $PIECE(pStatus, " ", 2, *)
    Set pResult = {
      "error": (error)
    }
  }

  If pResult.%Extends("%Library.DynamicAbstractObject") {
    Write pResult.%ToJSON()
  }
  ElseIf pResult.%Extends("%JSON.Adaptor") {
    Do pResult.%JSONExport()
  }
  ElseIf pResult.%Extends("%Stream.Object") {
    Do pResult.OutputToDevice()
  }
  
  Quit tSC
}

ClassMethod %ProcessJson(pStatus As %Status = {$$$OK}, pResult As %String) As %Status [ Internal ]
{
  #dim %response As %CSP.Response
  Set tSC = $$$OK
  If $$$ISERR(pStatus) {
    Set %response.Status = 500
    Set tSC = ..StatusToJSON(pStatus, .tJSON)
    If $ISOBJECT(tJSON) {
      Set pResult = tJSON
    } Else {
      Set pResult = { "errors": [ { "error": "Unknown error parsing status code" } ] }
    }
  } 

  Write pResult
  Quit tSC
}

ClassMethod ReportHttpStatusCode(pHttpStatus, pSC As %Status = {$$$OK}) As %Status
{
  Set %response.Status=pHttpStatus
  
  If $$$ISERR(pSC) Do ..outputStatus(pSC)
  /*
  If (+pHttpStatus>=400) {
    Set %response.ContentType = "application/json"
    SET pResult = {
      "error": ($PIECE(pHttpStatus, " ", 2, *))
    }
    Return ..%ProcessResult($$$OK, pResult)
  }*/
      
  Return $$$OK
}

}
