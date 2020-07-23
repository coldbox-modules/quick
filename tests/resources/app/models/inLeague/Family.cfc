component extends="quick.models.BaseEntity" accessors="true" {

	property name="familyID";
	property name="parent1ID";
	property name="parent2ID";

	variables._key = "familyID";

	function parent1() {
		return hasOne(
			relationName = "Parent",
			foreignKey = "ID",
			localKey = "parent1ID"
		);
	}

	function parent2() {
		return hasOne(
			relationName = "Parent",
			foreignKey = "ID",
			localKey = "parent2ID"
		);
	}

	function parents() {
		return belongsToMany(
			relationName = "Parent",
			table = "family_parents",
			foreignPivotKey = "familyID",
			relatedPivotKey = "parentID",
			parentKey = "familyID",
			relatedKey = "ID"
		);
	}

	function children() {
		return hasMany(
			relationName = "Child",
			foreignKey = "familyID",
			localKey = "familyID"
		);
	}

}
