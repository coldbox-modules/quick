component {

    function up( sb, qb ) {
        sb.create( "family_parents", function( t ) {
            t.unsignedInteger( "parentID" );
            t.unsignedInteger( "familyID" );
            t.primaryKey( [ "parentID", "familyID" ] );
        } );
    }

    function down( sb, qb ) {
        sb.drop( "family_parents" );
    }

}
