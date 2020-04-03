component {

    this.name = "ColdBoxTestingSuite" & hash(getCurrentTemplatePath());
    this.sessionManagement  = true;
    this.setClientCookies   = true;
    this.sessionTimeout     = createTimeSpan( 0, 0, 15, 0 );
    this.applicationTimeout = createTimeSpan( 0, 0, 15, 0 );

    testsPath = getDirectoryFromPath( getCurrentTemplatePath() );
    this.mappings[ "/tests" ] = testsPath;
    rootPath = REReplaceNoCase( this.mappings[ "/tests" ], "tests(\\|/)", "" );
    this.mappings[ "/root" ] = rootPath;
    this.mappings[ "/testingModuleRoot" ] = listDeleteAt( rootPath, listLen( rootPath, '\/' ), "\/" );
    this.mappings[ "/quick" ] = listDeleteAt( rootPath, listLen( rootPath, '\/' ), "\/" );
    this.mappings[ "/app" ] = testsPath & "resources/app";
    this.mappings[ "/coldbox" ] = testsPath & "resources/app/coldbox";
    this.mappings[ "/testbox" ] = rootPath & "/testbox";

    this.datasource = "quick";

    function onRequestStart() {
        structDelete( application, "cbController" );
        setUpDatabase();
    }

    private function setUpDatabase() {
        queryExecute( "DROP DATABASE IF EXISTS quick" );
        queryExecute( "CREATE DATABASE quick" );
        queryExecute( "USE quick" );

        queryExecute( "
            CREATE TABLE `countries` (
              `id` char(35) NOT NULL,
              `name` varchar(50) NOT NULL,
              `created_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
              `modified_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
              PRIMARY KEY (`id`)
            )
        " );
        queryExecute( "
            INSERT INTO `countries` (`id`, `name`, `created_date`, `modified_date`) VALUES ('02B84D66-0AA0-F7FB-1F71AFC954843861', 'United States', '2017-07-28 02:07:00', '2017-07-28 02:07:00')
        " );
        queryExecute( "
            INSERT INTO `countries` (`id`, `name`, `created_date`, `modified_date`) VALUES ('02BA2DB0-EB1E-3F85-5F283AB5E45608C6', 'Argentina', '2017-07-29 03:07:00', '2017-07-29 03:07:00')
        " );

        queryExecute( "
            CREATE TABLE `offices` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `name` varchar(50) NOT NULL,
                PRIMARY KEY (`id`)
            )
        " );

        queryExecute( "
            INSERT INTO `offices` VALUES (1, 'Acme')
        " );

        queryExecute( "
            CREATE TABLE `teams` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `name` varchar(50) NOT NULL,
                `officeId` int(11) NOT NULL,
                PRIMARY KEY (`id`)
            )
        " );

        queryExecute( "
            INSERT INTO `teams` VALUES (1, 'Engineering', 1)
        " );

        queryExecute( "
            INSERT INTO `teams` VALUES (2, 'Management', 1)
        " );

        queryExecute( "
            CREATE TABLE `users` (
              `id` int(11) NOT NULL AUTO_INCREMENT,
              `username` varchar(50) NOT NULL,
              `first_name` varchar(50) NOT NULL,
              `last_name` varchar(50) NOT NULL,
              `email` varchar(50),
              `password` varchar(100),
              `country_id` char(35),
              `team_id` int(11),
              `created_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
              `modified_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
              `type` varchar(50) NOT NULL DEFAULT 'limited',
              `externalId` varchar(25),
              `streetOne` varchar(100),
              `streetTwo` varchar(100),
              `city` varchar(100),
              `state` varchar(2),
              `zip` varchar(10),
              PRIMARY KEY (`id`)
            )
        " );
        queryExecute( "
          CREATE TABLE `externalThings` (
            `thingId` int(11) NOT NULL AUTO_INCREMENT,
            `userId` int(11) NOT NULL,
            `externalId` varchar(25) NOT NULL,
            `value` varchar(50),
            PRIMARY KEY (`thingId`)
            )
        " );
        queryExecute( "
            INSERT INTO `users` (`id`, `username`, `first_name`, `last_name`, `password`, `country_id`, `team_id`, `created_date`, `modified_date`, `type`, `externalId`, `streetOne`, `streetTwo`, `city`, `state`, `zip`) VALUES (1, 'elpete', 'Eric', 'Peterson', '5F4DCC3B5AA765D61D8327DEB882CF99', '02B84D66-0AA0-F7FB-1F71AFC954843861', 1, '2017-07-28 02:06:36', '2017-07-28 02:06:36', 'admin', '1234', '123 Elm Street', NULL, 'Salt Lake City', 'UT', '84123')
        " );
        queryExecute( "
            INSERT INTO `users` (`id`, `username`, `first_name`, `last_name`, `password`, `country_id`, `team_id`, `created_date`, `modified_date`, `externalId`, `streetOne`, `streetTwo`, `city`, `state`, `zip`) VALUES (2, 'johndoe', 'John', 'Doe', '5F4DCC3B5AA765D61D8327DEB882CF99', '02B84D66-0AA0-F7FB-1F71AFC954843861', 1, '2017-07-28 02:07:16', '2017-07-28 02:07:16', '6789', '123 Elm Street', NULL, 'Salt Lake City', 'UT', '84123');
        " );
        queryExecute( "
            INSERT INTO `users` (`id`, `username`, `first_name`, `last_name`, `password`, `country_id`, `team_id`, `created_date`, `modified_date`, `externalId`, `streetOne`, `streetTwo`, `city`, `state`, `zip`) VALUES (3, 'janedoe', 'Jane', 'Doe', '5F4DCC3B5AA765D61D8327DEB882CF99', NULL, 1, '2017-07-28 02:08:16', '2017-07-28 02:08:16', '5555', '123 Elm Street', NULL, 'Salt Lake City', 'UT', '84123');
        " );
        queryExecute( "
            INSERT INTO `users` (`id`, `username`, `first_name`, `last_name`, `password`, `country_id`, `team_id`, `created_date`, `modified_date`, `type`, `externalId`, `streetOne`, `streetTwo`, `city`, `state`, `zip`) VALUES (4, 'elpete2', 'Another', 'Peterson', '5F4DCC3B5AA765D61D8327DEB882CF99', '02BA2DB0-EB1E-3F85-5F283AB5E45608C6', 2, '2019-06-15 12:29:36', '2017-07-28 02:06:36', 'admin', '1234', '123 Elm Street', NULL, 'Salt Lake City', 'UT', '84123')
        " );
        queryExecute( "
            CREATE TABLE `my_posts` (
              `post_pk` int(11) NOT NULL AUTO_INCREMENT,
              `user_id` int(11),
              `body` text NOT NULL,
              `created_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
              `modified_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
              `published_date` timestamp(0) NULL,
              PRIMARY KEY (`post_pk`)
            )
        " );
        queryExecute( "
            INSERT INTO `my_posts` (`post_pk`, `user_id`, `body`, `created_date`, `modified_date`, `published_date`) VALUES (1245, 1, 'My awesome post body', '2017-07-28 02:07:00', '2017-07-28 02:07:00', '2017-07-28 02:07:00')
        " );
        queryExecute( "
            INSERT INTO `my_posts` (`post_pk`, `user_id`, `body`, `created_date`, `modified_date`, `published_date`) VALUES (523526, 1, 'My second awesome post body', '2017-07-28 02:07:36', '2017-07-28 02:07:36', NULL)
        " );
        queryExecute( "
            INSERT INTO `my_posts` (`post_pk`, `user_id`, `body`, `created_date`, `modified_date`, `published_date`) VALUES (7777, NULL, 'My post with no author', '2017-07-28 02:07:36', '2017-07-28 02:07:36', NULL)
        " );
        queryExecute( "
            INSERT INTO `my_posts` (`post_pk`, `user_id`, `body`, `created_date`, `modified_date`, `published_date`) VALUES (321, 4, 'My post with a different author', '2017-07-28 02:07:36', '2017-07-28 02:07:36', '2017-07-28 02:07:00')
        " );
        queryExecute( "
            CREATE TABLE `videos` (
              `id` int(11) NOT NULL AUTO_INCREMENT,
              `url` varchar(50) NOT NULL,
              `title` varchar(50) NOT NULL,
              `description` varchar(50) NOT NULL,
              `created_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
              `modified_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
              PRIMARY KEY (`id`)
            )
        " );
        queryExecute( "
            INSERT INTO `videos` (`id`, `url`, `title`, `description`, `created_date`, `modified_date`) VALUES (1, 'https://www.youtube.com/watch?v=JDzIypmP0eo', 'Building KiteTail with Adam Wathan', 'Awesome live coding experience', '2017-06-28 02:07:36', '2017-06-30 12:17:24')
        " );
        queryExecute( "
            INSERT INTO `videos` (`id`, `url`, `title`, `description`, `created_date`, `modified_date`) VALUES (1245, 'https://www.youtube.com/watch?v=BgAlQuqzl8o', 'Cello Wars', 'Star Wars Cello Parody', '2017-07-02 04:14:22', '2017-07-02 04:14:22')
        " );
        queryExecute( "
            CREATE TABLE `comments` (
              `id` int(11) NOT NULL AUTO_INCREMENT,
              `body` text NOT NULL,
              `commentable_id` int(11) NOT NULL,
              `commentable_type` varchar(50) NOT NULL,
              `created_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
              `modified_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
              PRIMARY KEY (`id`)
            )
        " );
        queryExecute( "
            INSERT INTO `comments` (`id`, `body`, `commentable_id`, `commentable_type`, `created_date`, `modified_date`) VALUES (1, 'I thought this post was great', 1245, 'Post', '2017-07-02 04:14:22', '2017-07-02 04:14:22')
        " );
        queryExecute( "
            INSERT INTO `comments` (`id`, `body`, `commentable_id`, `commentable_type`, `created_date`, `modified_date`) VALUES (2, 'I thought this post was not so good', 321, 'Post', '2017-07-04 04:14:22', '2017-07-04 04:14:22')
        " );
        queryExecute( "
            INSERT INTO `comments` (`id`, `body`, `commentable_id`, `commentable_type`, `created_date`, `modified_date`) VALUES (3, 'What a great video! So fun!', 1245, 'Video', '2017-07-02 04:14:22', '2017-07-02 04:14:22')
        " );
        queryExecute( "
            CREATE TABLE `tags` (
              `id` int(11) NOT NULL AUTO_INCREMENT,
              `name` varchar(50) NOT NULL,
              PRIMARY KEY (`id`)
            )
        " );
        queryExecute( "INSERT INTO `tags` (`id`, `name`) VALUES (1, 'programming')" );
        queryExecute( "INSERT INTO `tags` (`id`, `name`) VALUES (2, 'music')" );
        queryExecute( "
            CREATE TABLE `my_posts_tags` (
              `custom_post_pk` int(11) NOT NULL,
              `tag_id` int(11) NOT NULL,
              PRIMARY KEY (`custom_post_pk`, `tag_id`)
            )
        " );
        queryExecute( "INSERT INTO `my_posts_tags` (`custom_post_pk`, `tag_id`) VALUES (1245, 1)" );
        queryExecute( "INSERT INTO `my_posts_tags` (`custom_post_pk`, `tag_id`) VALUES (1245, 2)" );
        queryExecute( "INSERT INTO `my_posts_tags` (`custom_post_pk`, `tag_id`) VALUES (523526, 1)" );
        queryExecute( "INSERT INTO `my_posts_tags` (`custom_post_pk`, `tag_id`) VALUES (523526, 2)" );
        queryExecute( "
            CREATE TABLE `links` (
              `link_id` int(11) NOT NULL AUTO_INCREMENT,
              `link_url` varchar(255) NOT NULL,
              `created_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
              `modified_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
              PRIMARY KEY (`link_id`)
            )
        " );
        queryExecute( "
            INSERT INTO `links` (`link_id`, `link_url`, `created_date`, `modified_date`) VALUES (1, 'http://example.com/some-link', '2017-07-28 02:07:00', '2017-07-28 02:07:00')
        " );
        queryExecute( "
            CREATE TABLE `referrals` (
              `id` int(11) NOT NULL AUTO_INCREMENT,
              `type` varchar(255) NOT NULL,
              `created_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
              `modified_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
              PRIMARY KEY (`id`)
            )
        " );
        queryExecute( "
            INSERT INTO `referrals` (`id`, `type`, `created_date`, `modified_date`) VALUES (1, 'external', '2017-07-28 02:07:00', '2017-07-28 02:07:00')
        " );
        queryExecute( "
            CREATE TABLE `songs` (
              `id` int(11) NOT NULL AUTO_INCREMENT,
              `title` varchar(255),
              `download_url` varchar(255) NOT NULL,
              `created_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
              `modified_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
              PRIMARY KEY (`id`)
            )
        " );
        queryExecute( "
            INSERT INTO `songs` (`id`, `title`, `download_url`, `created_date`, `modified_date`) VALUES (1, 'Ode to Joy', 'https://open.spotify.com/track/4Nd5HJn4EExnLmHtClk4QV', '2017-07-28 02:07:00', '2017-07-28 02:07:00')
        " );
        queryExecute( "
            INSERT INTO `songs` (`id`, `title`, `download_url`, `created_date`, `modified_date`) VALUES (2, 'Open Arms', 'https://open.spotify.com/track/1m2INxep6LfNa25OEg5jZl', '2017-07-28 02:07:00', '2017-07-28 02:07:00')
        " );
        queryExecute( "
            CREATE TABLE `phone_numbers` (
              `id` int(11) NOT NULL AUTO_INCREMENT,
              `number` varchar(50),
              `active` tinyint(1),
              PRIMARY KEY (`id`)
            )
        " );
        queryExecute( "
            INSERT INTO `phone_numbers` (`id`, `number`, `active`) VALUES (1, '323-232-3232', 1)
        " );
        queryExecute( "
            INSERT INTO `phone_numbers` (`id`, `number`, `active`) VALUES (2, '545-454-5454', 0)
        " );
        queryExecute( "
            CREATE TABLE `empty` (
              `id` int(11) NOT NULL AUTO_INCREMENT,
              PRIMARY KEY (`id`)
            )
        " );
        queryExecute(
            "
            CREATE TABLE `a` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `name` varchar(50) NOT NULL,
                PRIMARY KEY (`id`)
            )
        "
        );
        queryExecute(
            "
            CREATE TABLE `b` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `a_id` int(11),
                `name` varchar(50) NOT NULL,
                PRIMARY KEY (`id`)
            )
        "
        );
        queryExecute(
            "
            CREATE TABLE `composites` (
                `a` int(11) NOT NULL,
                `b` int(11) NOT NULL,
                PRIMARY KEY (`a`, `b`)
            )
            "
        );
        queryExecute( "
            INSERT INTO `composites` (`a`, `b`) VALUES (1, 1)
        " );
        queryExecute( "
            INSERT INTO `composites` (`a`, `b`) VALUES (1, 2)
        " );
        queryExecute(
            "
            CREATE TABLE `composite_children` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `composite_a` int(11) NOT NULL,
                `composite_b` int(11) NOT NULL,
                PRIMARY KEY (`id`)
            )
            "
        );
        queryExecute( "
            INSERT INTO `composite_children` (`id`, `composite_a`, `composite_b`) VALUES (1, 1, 2)
        " );
        queryExecute( "
            INSERT INTO `composite_children` (`id`, `composite_a`, `composite_b`) VALUES (2, 2, 2)
        " );

    }
}
