<p align="center">
    <img src="/quick300.png" /><br />
    <a href="https://travis-ci.org/coldbox-modules/quick"><img src="https://travis-ci.org/coldbox-modules/quick.svg?branch=master" alt="Build Status"></a>
</p>

## A CFML ORM Engine

### Why?

Quick was built out of lessons learned and persistent challenges in developing complex RDBMS applications using built-in Hibernate ORM in CFML.

-   Hibernate ORM error messages often obfuscate the actual cause of the error because they are provided directly by the Java classes.
-   Complex CFML Hibernate ORM applications can consume significant memory and processing resources, making them cost-prohibitive and inefficient when used in microservices architecture.
-   Hibernate ORM is tied to the engine releases. This means that updates come infrequently and may be costly for non-OSS engine users.
-   Hibernate ORM is built in Java. This limits contributions from CFML developers who don't know Java or don't feel comfortable contributing to a Java project.
-   Hibernate ORM doesn't take advantage of a lot of dynamic- and meta-programming available in CFML. \(Tools like CBORM have helped to bridge this gap.\)

We can do better.

### What?

Quick is an ORM \(Object Relational Mapper\) written in CFML for CFML. It provides an [ActiveRecord](https://en.wikipedia.org/wiki/Active_record_pattern) implementation for working with your database. With it you can map database tables to components, create relationships between components, query and manipulate data, and persist all your changes to your database.

### Prerequisites

You need the following configured before using Quick:

-   Configure a default datasource in your CFML engine
-   ColdBox 6+
-   qb 14.x (installed as a dependency of Quick)
-   Add a mapping for `quick` in your `Application.cfc`
-   Configure your `BaseGrammar` in `config/ColdBox.cfc`

See [Getting Started](https://quick.ortusbooks.com/guide/getting-started) for more details.

### Supported Databases

Quick supports all databases supported by [qb](https://qb.ortusbooks.com).

### Example

Here's a "quick" example to whet your appetite.

We'll show the database structure using a [migrations file](https://forgebox.io/view/commandbox-migrations). This isn't required to use `quick`, but it is highly recommended.

```javascript
// 2017_11_10_122835_create_users_table.cfc
component {

    function up() {
        schema.create( "users", function( table ) {
            table.increments( "id" );
            table.string( "username" ).unique();
            table.string( "email" ).unique();
            table.string( "password" );
            table.timestamp( "createdDate" );
            table.timestamp( "updatedDate" );
        } );
    }

}
```

```javascript
// User
component extends="quick.models.BaseEntity" {

    // the name of the table is the pluralized version of the model
    // this can be configured on a per-entity basis

}
```

```javascript
// handlers/Users.cfc
component {

    // /users/:id
    function show( event, rc, prc ) {
        // this finds the User with an id of 1 and retrieves it
        prc.user = getInstance( "User" ).findOrFail( rc.id );
        event.setView( "users/show" );
    }

}
```

```markup
<!-- views/users/show.cfm -->
<cfoutput>
    <h1>Hi, #prc.user.getUsername()#!</h1>
</cfoutput>
```

Now that you've seen an example, [dig in to what you can do](https://quick.ortusbooks.com/) with Quick!

### Caching queries

Quick passes query options through to `queryExecute`, so applications can use the query cache provided by their CFML engine. This works with collection queries and primary-key lookups:

```javascript
var users = getInstance( "User" ).get(
    options = { cachedWithin : createTimeSpan( 0, 0, 5, 0 ) }
);

var user = getInstance( "User" ).find(
    rc.id,
    { cachedWithin : createTimeSpan( 0, 0, 5, 0 ) }
);
```

An entity can also configure defaults for every query by assigning `_queryOptions` in its pseudo-constructor:

```javascript
component extends="quick.models.BaseEntity" {

    variables._queryOptions = {
        cachedWithin : createTimeSpan( 0, 0, 5, 0 )
    };

}
```

Query caching stores database results, not live Quick entities or loaded relationships. Cache lifetime and invalidation are managed by the CFML engine, so use short lifetimes for data that Quick or another process may update. For application-specific invalidation or distributed caching, cache entity mementos in CacheBox at the service layer and rehydrate them through Quick's public APIs.

### Passing a Quick query to qb

`asQuery()` changes how Quick returns results; it still returns a QuickBuilder. When a plain qb query needs a subquery built with Quick, pass the underlying qb builder using `getQB()` or `retrieveQuery()`:

```javascript
var userIds = getInstance( "User" ).where( "active", true ).select( "id" );
var posts = getInstance( "QueryBuilder@qb" )
    .from( "posts" )
    .whereIn( "user_id", userIds.getQB() )
    .get();
```

Keep Quick-specific scopes and column selection on the Quick builder before crossing this boundary. `asQuery()` is not a replacement for `retrieveQuery()`.

### Creating related entities

`belongsToMany().create( attributes, pivotAttributes )` saves the related entity, attaches its pivot row, and returns the saved entity. Supply additional pivot values in the second argument. Configure a pivot model with `using()` when reading pivot attributes through a model with casts or behavior.

A through relationship can traverse multiple intermediate entities and relationship types. Creating a target does not identify which intermediate records to reuse or create. Persist the target and intermediate associations explicitly through the direct relationship methods, using a transaction when those writes must succeed together. Quick does not infer and cascade-create an arbitrary through path.

### Optional parallel eager loading

Parallel eager loading is disabled by default. To allow independent eager-load branches to run concurrently on Lucee and BoxLang, explicitly enable it in your ColdBox module settings:

```javascript
moduleSettings = {
    quick = {
        parallelEagerLoading = true
    }
};
```

Then opt in on individual queries:

```javascript
var posts = getInstance( "Post" )
    .with( [ "author", "tags" ], true )
    .get();
```

With `parallelEagerLoading = false` (the default), Quick does not create or validate a parallel executor, and all eager loading remains sequential even when `.with( relations, true )` is used. Enabling the module setting still requires the per-query opt-in shown above. Adobe ColdFusion, a single top-level relationship, and active database transactions use the sequential path. Parallel workers retrieve and hydrate separate branches; matching the results onto the parent entities happens on the calling thread. Worker errors and timeouts propagate to the caller.

Quick's module settings include `parallelEagerLoadingMaxThreads` (default `4`), `parallelEagerLoadingTimeout` (default `60000` milliseconds per batch), and `parallelEagerLoadingExecutor` (the name of an optional application-provided bounded ColdBox executor). When parallel eager loading is enabled, Quick creates and manages a fixed executor when none is supplied. Account for database connection capacity when increasing concurrency.

### Testing with model factories

Quick includes Laravel-inspired model factories under `quick.resources.testing`. Define application factories outside of your production model code:

```javascript
// tests/resources/factories/UserFactory.cfc
component extends="quick.resources.testing.Factory" {

    struct function definition() {
        return {
            username  : "factory-#lCase( createUUID() )#",
            firstName : "Factory",
            lastName  : "User"
        };
    }

    any function administrator() {
        return state( { type : "admin" } );
    }

}
```

Create a manager in your test base class and expose a short `factory()` helper:

```javascript
variables.factoryManager = new quick.resources.testing.FactoryManager(
    wirebox     = getWireBox(),
    factoryPath = "tests.resources.factories"
);

any function factory( required string name ) {
    return variables.factoryManager.factory( arguments.name );
}
```

Factories support default definitions, explicit and named states, counts, sequences, attribute closures, and `afterMaking` and `afterCreating` callbacks. `make()` returns unsaved Quick entities, while `create()` persists through the entity's normal `save()` lifecycle:

```javascript
var admin = factory( "User" ).administrator().create();
var users = factory( "User" ).count( 3 ).create();
var unsavedUser = factory( "User" ).make( { firstName : "Override" } );
```

Factories do not manage database transactions. Integration tests should start a transaction around each test and roll it back in `finally`, ensuring both passing and failing tests leave the database unchanged.

All factory implementation classes are isolated beneath `resources/testing`; production deployment tooling may exclude that directory. Quick does not load or register these classes during normal module startup.

### Tests and Contributing

To run the tests, first clone this repo and run a `box install`.

Quick's test suite runs specifically on MySQL, so you will need a MySQL database to run the tests.
If you do not have one, Docker provides an easy way to start one.

```sh
docker run -d --name quick -p 3306:3306 -e MYSQL_RANDOM_ROOT_PASSWORD=yes -e MYSQL_DATABASE=quick -e MYSQL_USER=quick -e MYSQL_PASSWORD=quick mysql:5
```

Finally, copy the `.env.example` file to `.env` and fill in the values for your database.

### Prior Art, Acknowledgements, and Thanks

Quick is backed by [qb](https://www.forgebox.io/view/qb). Without qb, there is no Quick.

Quick is inspired heavily by [Eloquent in Laravel](https://laravel.com/docs/5.6/eloquent). Thank you Taylor Otwell and the Laravel community for a great library.

Development of Quick is sponsored by Ortus Solutions. Thank you Ortus Solutions for investing in the future of CFML.


## Community and Support
Join us in our Ortus Community and become a valuable member of this project [Quick ORM](https://community.ortussolutions.com/c/communities/quick-orm/23). We are looking forward to hearing from you!
