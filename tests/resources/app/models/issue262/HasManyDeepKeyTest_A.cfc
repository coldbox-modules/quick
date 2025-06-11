component
	table    ="HasManyDeepKeyTest_A"
	extends  ="quick.models.BaseEntity"
	accessors=true
{

	property name="aID";

	variables._key = "aID";

	function Bs() {
		return hasMany(
			relationName = "HasManyDeepKeyTest_B",
			foreignKey   = "aID",
			localKey     = "aID"
		)
	}

	function Cs() {
		return hasManyThrough( [ "Bs", "Cs" ] )
	}

}
