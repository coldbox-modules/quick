component extends="quick.models.BaseEntity" accessors="true" {

	property name="ID";
	property name="firstname";
	property name="lastname";

	variables._key = "ID";

	function families() {
		return belongsToMany(
			relationName = "Family",
			table = "family_parents",
			foreignPivotKey = "parentID",
			relatedPivotKey = "familyID",
			parentKey = "ID",
			relatedKey = "familyID"
		);
	}

}
