component table="RMME_B" extends="quick.models.BaseEntity" accessors="true" {

    property name="ID_A" type="numeric" sqltype="integer";
    property name="ID_B" type="numeric" sqltype="integer";

    variables._key = "ID_B";

    function C() {
	    return hasMany(
            relationName = "RMME_C",
            foreignKey = "ID_B",
            localKey = "ID_B"
        ).withSomeScope();
    }

}