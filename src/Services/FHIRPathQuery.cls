Class Services.FHIRPathQuery Extends %Persistent
{

Query GetResIds(res As %String = "") As %SQLQuery(COMPILEMODE = "IMMEDIATE", CONTAINID = 1, ROWSPEC = "ID:%Integer,ResourceId:%Integer", SELECTMODE = "RUNTIME") [ SqlName = SP_GetResIds, SqlProc ]
{
SELECT Top 10 ID, ResourceId
FROM HSFHIR_X0001_R.Rsrc
WHERE (ResourceType = :res)
}

Query ResourceCount(res As %String = "") As %SQLQuery(COMPILEMODE = "IMMEDIATE", CONTAINID = 1, ROWSPEC = "Count:%Integer", SELECTMODE = "RUNTIME") [ SqlName = SP_ResourceCount, SqlProc ]
{
SELECT Count(ResourceType)
FROM HSFHIR_X0001_R.Rsrc
WHERE (ResourceType = :res)
}

Query FHIRPathExp(res As %String = "", sp As %String = "") As %SQLQuery(COMPILEMODE = "IMMEDIATE", CONTAINID = 1, ROWSPEC = "Expression:%String", SELECTMODE = "RUNTIME") [ SqlName = SP_FhirPathExp, SqlProc ]
{
SELECT Top 1 PathExpression
FROM BaseTypes.SearchParameter 
WHERE (BaseResource = :res and Name = :sp)
}

Storage Default
{
<Data name="FHIRPathQueryDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Resource</Value>
</Value>
</Data>
<DataLocation>^Services.FHIRPathQueryD</DataLocation>
<DefaultData>FHIRPathQueryDefaultData</DefaultData>
<IdLocation>^Services.FHIRPathQueryD</IdLocation>
<IndexLocation>^Services.FHIRPathQueryI</IndexLocation>
<StreamLocation>^Services.FHIRPathQueryS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
