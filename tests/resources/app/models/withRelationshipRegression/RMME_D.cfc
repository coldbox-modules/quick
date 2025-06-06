component table="RMME_D" extends="quick.models.BaseEntity" accessors="true" {

    property name="ID_D" type="numeric" sqltype="integer";
    property name="dValue" type="numeric" sqltype="integer";

    variables._key = "ID_D";

    function scopeWithSomeScope( qb ) {
        qb.addSubselect( "inlined_dValue", "d.dValue" );
    }

    function D() {
        return hasOne(
            relationName = "D",
            foreignKey = "ID_D",
            localKey = "ID_D"
        )
    }

}