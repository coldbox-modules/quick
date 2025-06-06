component table="RMME_A" extends="quick.models.BaseEntity" accessors="true" {

    property name="ID_A" type="numeric" sqltype="integer";

    variables._key = "ID_A";

    function B() {
    	return hasMany(
            relationName = "RMME_B",
            foreignKey = "ID_A",
            localKey = "ID_A"
        );
    }

    function C() {
        return hasManyThrough( [ "B", "C" ] );
    }

}