component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe(
			title = "GUID Primary Key Spec",
			body  = function() {
				it( "sets the primary key with a guid before saving", function() {
					var country = getInstance( "Actor" ).create( { "name" : "Tina Fey" } );

					expect( country.getId() ).notToBeNumeric();
					expect( country.getId() ).toHaveLength( 36 );
					expect(
						reFindNoCase(
							"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
							country.getId()
						)
					).toBe( 1 );
					expect( getInstance( "Actor" ).find( country.getId() ) ).notToBeNull();
				} );
			},
			skip = !server.keyExists( "lucee" ) && !server.keyExists( "boxlang" )
		);
	}

}
