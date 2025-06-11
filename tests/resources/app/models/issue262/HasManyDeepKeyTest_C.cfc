component
	table    ="HasManyDeepKeyTest_C"
	extends  ="quick.models.BaseEntity"
	accessors=true
{

	property name="cKey1";
	property name="cKey2";

	variables._key = [ "cKey1", "cKey2" ];

}
