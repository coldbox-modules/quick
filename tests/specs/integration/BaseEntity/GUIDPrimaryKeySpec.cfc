component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe(
			title = "GUID Primary Key Spec",
			body  = function() {
				it( "sets the primary key with a guid before saving", function() {
					var country = getInstance( "Actor" ).create( { "name" : "Tina Fey" } );

					expect( country.getId() ).notToBeNumeric();
				} );
			},
			skip = !server.keyExists( "lucee" ) && !server.keyExists( "boxlang" )
		);
	}

}
