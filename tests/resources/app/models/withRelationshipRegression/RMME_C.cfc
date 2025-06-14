component table="RMME_C" extends="quick.models.BaseEntity" accessors="true" {

    property name="ID_B" type="numeric" sqltype="integer";
    property name="ID_C" type="numeric" sqltype="integer";
    property name="ID_D" type="numeric" sqltype="integer";

    variables._key = "ID_C";

    function scopeWithSomeScope( qb ) {
        qb.addSubselect( "inlined_dValue", "d.dValue" );
    }

    function D() {
        return hasOne(
            relationName = "RMME_D",
            foreignKey = "ID_D",
            localKey = "ID_D"
        )
    }

}