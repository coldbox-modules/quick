component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

	function run() {
		describe( "Read-only properties", function() {
			it( "prevents read-only properties from being saved", function() {
				var link = getInstance( "Link" ).findOrFail( 1 );
				expect( link.getUrl() ).toBe( "http://example.com/some-link" );
				expect( link.getCreatedDate() ).toBe( "2017-07-28 02:07:00" );

				link.setUrl( "https://example.com/" )
					.setCreatedDate( now() )
					.save();

				link.refresh();

				expect( link.getUrl() ).toBe( "https://example.com/" );
				expect( link.getCreatedDate() ).toBe( "2017-07-28 02:07:00" );
			} );

			it( "prevents create from setting read-only properties", function() {
				expect( function() {
					getInstance( "Link" ).create( { createdDate : now() } );
				} ).toThrow( type = "QuickReadOnlyException" );
			} );

			it( "prevents assignAttribute from being called on a read-only property", function() {
				var link = getInstance( "Link" ).findOrFail( 1 );
				expect( function() {
					link.assignAttribute( "createdDate", now() );
				} ).toThrow( type = "QuickReadOnlyException" );
			} );

			it( "prevents fill from being called containing a read-only property", function() {
				var link = getInstance( "Link" ).findOrFail( 1 );
				expect( function() {
					link.fill( { createdDate : now() } );
				} ).toThrow( type = "QuickReadOnlyException" );
			} );

			it( "prevents updates from being performed on a read-only property", function() {
				var link = getInstance( "Link" ).findOrFail( 1 );
				expect( function() {
					link.update( { createdDate : now() } );
				} ).toThrow( type = "QuickReadOnlyException" );
			} );

			it( "prevents mass updates from being performed on read-only properties", function() {
				expect( function() {
					getInstance( "Link" ).updateAll( { createdDate : now() } );
				} ).toThrow( type = "QuickReadOnlyException" );
			} );
		} );
	}

}
