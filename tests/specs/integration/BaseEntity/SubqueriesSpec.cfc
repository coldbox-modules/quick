component extends="tests.resources.ModuleIntegrationSpec" {

	function beforeAll() {
		super.beforeAll();
		controller
			.getInterceptorService()
			.registerInterceptor( interceptorObject = this, interceptorName = "SubqueriesSpec" );
	}

	function afterAll() {
		controller.getInterceptorService().unregister( "SubqueriesSpec" );
		super.afterAll();
	}

	function run() {
		describe( "Subqueries Spec", function() {
			beforeEach( function() {
				variables.queries = [];
			} );

			it( "can add a subquery to an entity", function() {
				var elpete = getInstance( "User" ).withLatestPostId().findOrFail( 1 );
				expect( elpete.getLatestPostId() ).notToBeNull();

				expect( elpete.getLatestPostId() ).toBe( 523526 );
				expect( variables.queries ).toHaveLength(
					1,
					"Only one query should have been executed. #arrayLen( variables.queries )# were instead."
				);
			} );

			it( "can add a subquery to an entity using a relationship", function() {
				var elpete = getInstance( "User" ).withLatestPostIdRelationship().findOrFail( 1 );
				expect( elpete.getLatestPostId() ).notToBeNull();
				expect( elpete.getLatestPostId() ).toBe( 523526 );
				expect( variables.queries ).toHaveLength(
					1,
					"Only one query should have been executed. #arrayLen( variables.queries )# were instead."
				);
			} );

			it( "can add a subquery to an entity using a relationship shortcut", function() {
				var elpete = getInstance( "User" ).withLatestPostIdRelationshipShortcut().findOrFail( 1 );
				expect( elpete.getLatestPostId() ).notToBeNull();
				expect( elpete.getLatestPostId() ).toBe( 523526 );
				expect( variables.queries ).toHaveLength(
					1,
					"Only one query should have been executed. #arrayLen( variables.queries )# were instead."
				);
			} );

			it( "can add a subquery to an entity using a relationship shortcut and a nested relationship", function() {
				var post = getInstance( "Post" )
					.addSubselect( "countryName", "author.country.name" )
					.findOrFail( 523526 );
				expect( post.getCountryName() ).notToBeNull();
				expect( post.getCountryName() ).toBe( "United States" );
				expect( variables.queries ).toHaveLength(
					1,
					"Only one query should have been executed. #arrayLen( variables.queries )# were instead."
				);
			} );

			it( "can add a subquery to an entity using a belongsToThrough relationship", function() {
				var post = getInstance( "Post" ).addSubselect( "countryName", "country.name" ).findOrFail( 523526 );
				expect( post.getCountryName() ).notToBeNull();
				expect( post.getCountryName() ).toBe( "United States" );
				expect( variables.queries ).toHaveLength(
					1,
					"Only one query should have been executed. #arrayLen( variables.queries )# were instead."
				);
			} );

			it( "can add a subquery to an entity using a hasOne relationship", function() {
				var family = getInstance( "Family" )
					.addSubselect( "parent2FirstName", "parent2.firstname" )
					.findOrFail( 1 );
				expect( family.getParent2FirstName() ).notToBeNull();
				expect( family.getParent2FirstName() ).toBe( "Rory" );
				expect( variables.queries ).toHaveLength(
					1,
					"Only one query should have been executed. #arrayLen( variables.queries )# were instead."
				);
			} );

			it( "can add a subquery to an entity using multiple belongsTo and hasOne relationships", function() {
				var registration = getInstance( "Registration" )
					.addSubselect( "parent2FirstName", "child.family.parent2.firstname" )
					.findOrFail( 1 );
				expect( registration.getParent2FirstName() ).notToBeNull();
				expect( registration.getParent2FirstName() ).toBe( "Rory" );
				expect( variables.queries ).toHaveLength(
					1,
					"Only one query should have been executed. #arrayLen( variables.queries )# were instead."
				);
			} );

			it( "can add a subquery to an entity using a hasOneThrough relationship", function() {
				var registration = getInstance( "Child" )
					.addSubselect( "parent2FirstName", "parent2.firstname" )
					.findOrFail( 1 );
				expect( registration.getParent2FirstName() ).notToBeNull();
				expect( registration.getParent2FirstName() ).toBe( "Rory" );
				expect( variables.queries ).toHaveLength(
					1,
					"Only one query should have been executed. #arrayLen( variables.queries )# were instead."
				);
			} );

			it( "can add a subselect using a belongsTo relationship with multiple foreign keys", function() {
				var game = getInstance( "Game" ).addSubselect( "fieldName", "field.fieldName" ).findOrFail( 1 );
				expect( game.getFieldName() ).notToBeNull();
				expect( game.getFieldName() ).toBe( "Second Field" );
				expect( variables.queries ).toHaveLength(
					1,
					"Only one query should have been executed. #arrayLen( variables.queries )# were instead."
				);
			} );

			// https://github.com/coldbox-modules/quick/issues/104
			it( "can add a subselect using a query builder instance", () => {
				var elpete = getInstance( "User" )
					.addSubselect( "latestPostId", ( qb ) => {
						qb.from( "my_posts" )
							.select( "post_pk" )
							.whereColumn( "my_posts.user_id", "=", "users.id" )
							.orderByRaw( "COALESCE(published_date, created_date)" );
					} )
					.findOrFail( 1 );
				expect( elpete.getLatestPostId() ).toBe( 1245 );
			} );

			it( "can add a subquery to an entity using a hasManyThrough relationship with table aliases", function() {
				// expect( () => {
				var rmmeAs = getInstance( "RMME_A" ).asMemento( includes = [ "C" ] ).get();
				// } ).notToThrow();
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
		arrayAppend( variables.queries, interceptData );
	}

}
