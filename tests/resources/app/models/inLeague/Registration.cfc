component extends="quick.models.BaseEntity" accessors="true" {

	property name="registrationID";
	property name="childID";

	variables._key = "registrationID";

	function child() {
		return belongsTo(
			relationName = "Child",
			foreignKey = "childID",
			localKey = "childID"
		);
	}

}
