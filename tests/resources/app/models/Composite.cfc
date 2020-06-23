component table="composites" extends="quick.models.BaseEntity" accessors="true" {

    property name="a";
    property name="b";

    variables._key = [ "a", "b" ];

    function keyType() {
        return variables._wirebox.getInstance( "NullKeyType@quick" );
    }

}
