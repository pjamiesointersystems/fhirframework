Class Rest.SearchRest Extends %CSP.REST [ System = 3 ]
{

Parameter CHARSET = "utf-8";

Parameter CONTENTTYPE = "application/json";

Parameter HandleCorsRequest = 1;

Parameter PAGESIZE As INTEGER = 200;

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
