component extends="quick.models.BaseEntity" table="externalThings" accessors="true" {

    property name="thingID";
    property name="externalID"; // the external vendor foreign key
    property name="userID"; // our userID that created this thingID
    property name="value";

    variables._key = "thingID";

    function users() { return hasMany( relationName = "User", foreignKey = "externalID", localKey = "externalID" ); }

}
