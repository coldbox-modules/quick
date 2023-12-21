component {

    function up( schema, query ) {

        var defaultJson = '{ "analyzed": true, "magnitude": 0.8, "score": 0.6  }';

        schema.alter( "comments", function( table ) {
            table.addColumn( table.string( "sentimentAnalysis" ).nullable() );
        } );


        query.from( "comments" )
            .update( {  "sentimentAnalysis" = defaultJson } );

    }

    function down( schema, query ) {
        schema.alter( "comments", function( table ) {
            table.dropColumn( "sentimentAnalysis" );
        } );
    }

}
