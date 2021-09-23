component {

    function up( sb, qb ) {
        sb.create( "empty", function( t ) {
            t.increments( "id" );
        } );
    }

    function down( sb, qb ) {
        sb.drop( "empty" );
    }

}
