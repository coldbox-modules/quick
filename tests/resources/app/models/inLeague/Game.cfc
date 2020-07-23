component extends="quick.models.BaseEntity" accessors="true" {

	property name="ID";
	property name="fieldID";
	property name="clientID";

	variables._key = "ID";

	function field() {
		return belongsTo(
			relationName = "PlayingField",
			foreignKey = [ "fieldID", "clientID" ],
			localKey = [ "fieldID", "clientID" ]
		);
	}

}
