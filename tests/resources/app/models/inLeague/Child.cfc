component extends="quick.models.BaseEntity" accessors="true" {

	property name="childID";
	property name="familyID";

	variables._key = "childID";

	function family() {
		return belongsTo(
			relationName = "Family",
			foreignKey = "familyID",
			localKey = "familyID"
		);
	}

	function parent1() {
		return hasOneThrough( [ "family", "parent1" ] );
	}

	function parent2() {
		return hasOneThrough( [ "family", "parent2" ] );
	}

	function registration() {
		return hasMany(
			relationName = "Registration",
			foreignKey = "childID",
			localKey = "childID"
		);
	}

}
