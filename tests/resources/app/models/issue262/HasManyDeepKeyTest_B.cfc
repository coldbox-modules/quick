component
	table    ="HasManyDeepKeyTest_B"
	extends  ="quick.models.BaseEntity"
	accessors=true
{

	property name="bID";
	property name="aID";
	property name="cKey1";
	property name="cKey2";

	variables._key = "bID";

	function Cs() {
		return hasMany(
			relationName = "HasManyDeepKeyTest_C",
			foreignKey   = [ "cKey1", "cKey2" ],
			localKey     = [ "cKey1", "cKey2" ]
		)
	}

}
