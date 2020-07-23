component extends="quick.models.BaseEntity" accessors="true" {

	property name="ID";

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
