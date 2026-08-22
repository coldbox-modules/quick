component extends="tests.resources.ModuleIntegrationSpec" {

	function beforeAll() {
		super.beforeAll();
		controller
			.getInterceptorService()
			.registerInterceptor( interceptorObject = this, interceptorName = "ReadOnlyPropertySpec" );
	}

	function afterAll() {
		controller.getInterceptorService().unregister( "ReadOnlyPropertySpec" );
		super.afterAll();
	}

	function run() {
		describe( "Read-only properties", function() {
			it( "prevents read-only properties from being saved", function() {
				var link = getInstance( "Link" ).findOrFail( 1 );
				expect( link.getUrl() ).toBe( "http://example.com/some-link" );
				expect( formatTestTimestamp( link.getCreatedDate() ) ).toBe( "2017-07-28 02:07:00" );

				link.setUrl( "https://example.com/" )
					.setCreatedDate( now() )
					.save();

				link.refresh();

				expect( link.getUrl() ).toBe( "https://example.com/" );
				expect( formatTestTimestamp( link.getCreatedDate() ) ).toBe( "2017-07-28 02:07:00" );
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

			it( "excludes read-only properties from generated update statements", function() {
				var link = getInstance( "Link" ).findOrFail( 1 );
				structDelete( request, "readOnlyPropertySpecPreQBExecute" );

				link.setUrl( "https://example.com/updated" ).save();

				expect( request.readOnlyPropertySpecPreQBExecute ).toHaveLength( 1 );
				expect( request.readOnlyPropertySpecPreQBExecute[ 1 ].sql ).notToInclude( "created_date" );
			} );

			it( "excludes read-only properties from generated insert statements", function() {
				var link = getInstance( "Link" );
				link.setUrl( "https://example.com/new" ).forceAssignAttribute( "createdDate", now() );
				structDelete( request, "readOnlyPropertySpecPreQBExecute" );

				link.save();

				expect( request.readOnlyPropertySpecPreQBExecute ).toHaveLength( 1 );
				expect( request.readOnlyPropertySpecPreQBExecute[ 1 ].sql ).notToInclude( "created_date" );
			} );
		} );
	}

	function preQBExecute(
		event,
		interceptData,
		buffer,
		rc,
		prc
	) {
		param request.readOnlyPropertySpecPreQBExecute = [];
		request.readOnlyPropertySpecPreQBExecute.append( duplicate( arguments.interceptData ) );
	}

}
