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
-   ColdBox 4.3+
-   Add a mapping for `quick` in your `Application.cfc`
-   Configure your `BaseGrammar` in `config/ColdBox.cfc`

See [Getting Started](https://quick.ortusbooks.com/guide-1/getting-started) for more details.

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
