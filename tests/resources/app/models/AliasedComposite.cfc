component table="composites" extends="quick.models.BaseEntity" accessors="true" {

    property name="groupId" column="a";
    property name="memberId" column="b";

    variables._key = [ "a", "b" ];

    this.memento = {
        "defaultIncludes": [ "groupId", "memberId" ]
    };

    function keyType() {
        return variables._wirebox.getInstance( "NullKeyType@quick" );
    }

}
