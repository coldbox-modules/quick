# v3.0.2
## 11 May 2020 — 20:02:26 UTC

### fix

+ __EagerLoading:__ Apply custom sqltypes during eager loading
 ([c9633d3](https://github.com/coldbox-modules/quick/commit/c9633d3fc42a1e14fe48051a735dd1eeee956318))


# v3.0.1
## 08 May 2020 — 22:04:29 UTC

### fix

+ __BaseEntity:__ Account for null values in fill
 ([3f8bc2c](https://github.com/coldbox-modules/quick/commit/3f8bc2cabb1503d6617ccea9ad0c870b3816461c))
+ __Memento:__ Swap structAppend order for a Lucee bug
 ([1e0d217](https://github.com/coldbox-modules/quick/commit/1e0d2173ad8fe2eefce96ac509cd8d127ab34a0c))


# v3.0.0
## 06 May 2020 — 19:01:56 UTC

### BREAKING

+ __QuickBuilder:__ Prevent duplicate joins by default ([a8ac022](https://github.com/coldbox-modules/quick/commit/a8ac02207b2b7125a11fd4b9ba60ed44ebcfbdbc))
+ __BaseEntity:__ Enforce accessors for entities ([ad16248](https://github.com/coldbox-modules/quick/commit/ad162481322ea8c6a56cc59fa1cc80904e4b666c))
+ __BaseEntity:__ Remove virtual inheritance ([3b026b1](https://github.com/coldbox-modules/quick/commit/3b026b156684332648fbeb093086618c50f5d272))
+ __BaseEntity:__ Improve virtual column support ([5ebc42c](https://github.com/coldbox-modules/quick/commit/5ebc42c9d09d625285594c94311d38b41fd9dc1f))

### chore

+ __CI:__ CI debugging
 ([1111603](https://github.com/coldbox-modules/quick/commit/1111603eaaa1a981822f1c5441af883516dc8922))
+ __CI:__ CI debugging
 ([19b3053](https://github.com/coldbox-modules/quick/commit/19b30532b77fb1cbbed28ac30f22f7d95ddb8f67))
+ __CI:__ CI debugging
 ([6280040](https://github.com/coldbox-modules/quick/commit/6280040c7fc61bbf9573c4e944b6ea7cbfea7612))
+ __CI:__ CI debugging
 ([75bcb64](https://github.com/coldbox-modules/quick/commit/75bcb64d8757778c7a44e4e8efdde77104185aab))
+ __CI:__ CI debugging
 ([fda269a](https://github.com/coldbox-modules/quick/commit/fda269ab259bfa36aaa38174c465d51a8daa2ce4))
+ __CI:__ CI debugging
 ([5662bdc](https://github.com/coldbox-modules/quick/commit/5662bdc450218cddc4da0df6772079b9d05d6fcb))
+ __CI:__ CI debugging
 ([7716222](https://github.com/coldbox-modules/quick/commit/771622240e8e051d5dedd6031a0ba1f11b59fdb5))
+ __CI:__ CI debugging. :-(
 ([1912c2a](https://github.com/coldbox-modules/quick/commit/1912c2a8b80895abc81e446f2754c6df177efae7))
+ __CI:__ Add qb mapping for tests
 ([45c5238](https://github.com/coldbox-modules/quick/commit/45c5238767b57a356dc1a52bc30fee3003ac1348))
+ __CI:__ Fix overriding coldbox@be installation
 ([c4f9ae0](https://github.com/coldbox-modules/quick/commit/c4f9ae02e575855bd5e5d5b14fd01059039a6484))
+ __CI:__ Publish API docs after publishing a new version
 ([690b95d](https://github.com/coldbox-modules/quick/commit/690b95d077c3a179fccdb6d210d932326b6e5f9d))
+ __CI:__ Adjust CI builds to test bleeding edge on cron jobs
 ([0ffdafc](https://github.com/coldbox-modules/quick/commit/0ffdafc1049a4aac1ffd92fb9281200fa1b34b31))
+ __CI:__ Clean up .travis.yml
 ([d5753b5](https://github.com/coldbox-modules/quick/commit/d5753b51736ff2fb37b4c69ac390e1df567e87f6))

### feat

+ __Interceptors:__ Fire the postLoad event for all entities
 ([a480ef2](https://github.com/coldbox-modules/quick/commit/a480ef230ac73975b53995cbd8cb7c9f9177ee3f))
+ __ErrorMessages:__ Improve error message when accessing relationships on unloaded entities ([d43f699](https://github.com/coldbox-modules/quick/commit/d43f6994e8e7c9cf16bf44a79c1bde0170ef43fe))

### fix

+ __BaseEntity:__ Rename is and isNot to isSameAs and isNotSameAs for better ACF compatibility
 ([fff27a1](https://github.com/coldbox-modules/quick/commit/fff27a1f0c17579bb9b229711f7d1937bb18f353))
+ __BaseEntity:__ Improved hasRelationship check ([4064619](https://github.com/coldbox-modules/quick/commit/406461960915aea8d24dd9d448214d0df864f762))
+ __QuickBuilder:__ Fix nested whereHas with belongsToMany Relationships ([99f957e](https://github.com/coldbox-modules/quick/commit/99f957ed4c909860afd73b5b6ea7c0fb1e744b44))
+ __BaseEntity:__ Fix for virtual columns trying to be updated
 ([5f13e4f](https://github.com/coldbox-modules/quick/commit/5f13e4f9f210acf1f9d97b6a740acce9e03cb531))
+ __BaseEntity:__ Qualify all column names and correctly return eager loaded belongsToMany Relationships ([09f9c64](https://github.com/coldbox-modules/quick/commit/09f9c643c095f8b0d936d6fb4234341b0aa04b3c))
+ __BaseEntity:__ Forward updateOrInsert calls to updateOrCreate ([888fa22](https://github.com/coldbox-modules/quick/commit/888fa22c2586bc86fe2ecd6c3a855ca3ac8a1164))
+ __Memento:__ Ensure virtual columns are included in mementos by default
 ([6c72a46](https://github.com/coldbox-modules/quick/commit/6c72a4658be04ddfff6b25148e58ec832bbea064))
+ __BaseEntity:__ qualify columns when using fresh and refresh
 ([1cce0a2](https://github.com/coldbox-modules/quick/commit/1cce0a252b751879c5f74628d8aa24147152cdac))
+ __QuickBuilder:__ Clear orders when querying releationships ([d77c781](https://github.com/coldbox-modules/quick/commit/d77c781b1d204f00bf9514bb3292aaf73da61021))
+ __GlobalScopes:__ Ensure global scopes are only applied once per query
 ([664b288](https://github.com/coldbox-modules/quick/commit/664b288feb25f74f70ed28dd22b7f2b9068b6108))
+ __BaseEntity:__ Duplicate metadata struct when creating new entities ([5c06fa4](https://github.com/coldbox-modules/quick/commit/5c06fa4ea6dfdd508a932302c69cf28581fe8756))
+ __BaseEntity:__ Fix double applying of global scopes
 ([b374caa](https://github.com/coldbox-modules/quick/commit/b374caa9f65d4534c381945eb6af0a2d0e2bdf5c))
+ __BaseEntity:__ Default polymorphicBelongsTo name to the relation method name
 ([72352d6](https://github.com/coldbox-modules/quick/commit/72352d6a7325e95258fbef952375903858a381e0))

### other

+ __\*:__ v3.0.0-beta.13
 ([27ada30](https://github.com/coldbox-modules/quick/commit/27ada3048023a90e615a0f161a3b792eda07fcc7))
+ __\*:__ v3.0.0-beta.12
 ([57c1098](https://github.com/coldbox-modules/quick/commit/57c1098cd419fdffe8963da27b9653cb87c68728))
+ __\*:__ v3.0.0-beta.11
 ([defadc4](https://github.com/coldbox-modules/quick/commit/defadc4707919bfe492d95963ba189c096e2c75f))
+ __\*:__ v3.0.0-beta.10
 ([3ed41b4](https://github.com/coldbox-modules/quick/commit/3ed41b473f976fc1bf92d1f9c94bcda0eddaa651))
+ __\*:__ v3.0.0-beta.9
 ([0e761bf](https://github.com/coldbox-modules/quick/commit/0e761bf82c7cb21eb831a522b51655305a5ee2d9))
+ __\*:__ v3.0.0-beta.8
 ([5f33efa](https://github.com/coldbox-modules/quick/commit/5f33efad60a2701daf4d167e494c248ccada4c00))
+ __\*:__ chore: format with cfformat
 ([ad9d544](https://github.com/coldbox-modules/quick/commit/ad9d5441ee1f04b37eaffabc462c1846c8f0c492))
+ __\*:__ v3.0.0-beta.7
 ([da7eb88](https://github.com/coldbox-modules/quick/commit/da7eb880a8ab8897855de1a74d1ba6af9dbf428c))
+ __\*:__ Update docblocks
 ([b48e1d8](https://github.com/coldbox-modules/quick/commit/b48e1d8f0f8f8156be0e4ce6e5de94277fd73e56))
+ __\*:__ v3.0.0-beta.6
 ([24ad429](https://github.com/coldbox-modules/quick/commit/24ad42992b5f658254c6ef8c03a6acbe1f6bdc42))
+ __\*:__ v3.0.0-beta.5
 ([27e0258](https://github.com/coldbox-modules/quick/commit/27e02585f86be3cb87cae30371e7923031e6e313))
+ __\*:__ v3.0.0-beta.4
 ([d41d071](https://github.com/coldbox-modules/quick/commit/d41d071663db2405ac6647612b7ea5ddd90acbf2))
+ __\*:__ v3.0.0-beta.3
 ([59bb622](https://github.com/coldbox-modules/quick/commit/59bb622f19117263a0b188046a14f06f78355a1e))
+ __\*:__ v3.0.0-beta.2
 ([6e2ceab](https://github.com/coldbox-modules/quick/commit/6e2ceab6f2f8626998e711cc36cc334f2eba7af5))
+ __\*:__ v3.0.0-beta.1
 ([092ce93](https://github.com/coldbox-modules/quick/commit/092ce93beec9577f99136e73f24998ef8ed1e399))
+ __\*:__ chore: Update docblocks
 ([ecd3e27](https://github.com/coldbox-modules/quick/commit/ecd3e277ca1d0a1995362afedf1985f01f6fedb0))
+ __\*:__ v3.0.0-alpha.2
 ([4f01505](https://github.com/coldbox-modules/quick/commit/4f01505258721ce132dca0d947fdd71e47ae72a7))

### refactor

+ __BaseEntity:__ Clean up virtual column naming
 ([88d8237](https://github.com/coldbox-modules/quick/commit/88d823709a50b5c20363011bae3713311285ea89))


# v2.5.7
## 26 Feb 2020 — 00:16:25 UTC

### other

+ __\*:__ docs: Fix link to Gitbook from README ([5a8cf6a](https://github.com/coldbox-modules/quick/commit/5a8cf6aa945b4e5dc21b17823a475feaa0ab8e06))


# v2.5.6
## 19 Feb 2020 — 22:22:10 UTC

### fix

+ __BaseEntity:__ Correctly use the grammar annotation
 ([2312e9e](https://github.com/coldbox-modules/quick/commit/2312e9e3bcfdd441b4d80207d0636402aa612b1a))


# v2.5.5
## 13 Feb 2020 — 17:30:08 UTC

### other

+ __\*:__ chore: Use forgeboxStorage ([ad6c413](https://github.com/coldbox-modules/quick/commit/ad6c41392be2cff5b1d738a15209ed5b01beef1d))


# v2.5.4
## 20 Dec 2019 — 06:20:30 UTC

### fix

+ __CBORMCompat:__ Pass along query options in compat methods
 ([9a2739e](https://github.com/coldbox-modules/quick/commit/9a2739e0030fc1197e0255a1390fb061f07823e2))


# v2.5.3
## 11 Dec 2019 — 21:40:12 UTC

### fix

+ __BaseEntity:__ Revert calling setters when hydrating entities ([670fadb](https://github.com/coldbox-modules/quick/commit/670fadbbc5887952c7040025da16c497229a138e))


# v2.5.2
## 09 Dec 2019 — 17:57:41 UTC

### fix

+ __BaseEntity:__ Pass the entity to `when` closures ([96a8f3a](https://github.com/coldbox-modules/quick/commit/96a8f3af6bec3383e7acc4a9703fe1de3a9bd0cc))


# v2.5.1
## 05 Dec 2019 — 04:55:20 UTC

### fix

+ __BaseEntity:__ Account for null values with custom setters ([685e175](https://github.com/coldbox-modules/quick/commit/685e17572978b6d9f34a883843e765d3910e4870))
+ __BaseEntity:__ Reset underlying query when resetting entity ([83a6fdb](https://github.com/coldbox-modules/quick/commit/83a6fdb43736170671e9d4ad919c4e5b0b51c788))


# v2.5.0
## 04 Dec 2019 — 21:53:02 UTC

### feat

+ __BaseEntity:__ Allow entities to define a custom collection type. ([9135eee](https://github.com/coldbox-modules/quick/commit/9135eeeeddc86e97160cf473fcbbe79a5e336f42))


# v2.4.3
## 19 Nov 2019 — 07:59:46 UTC

### fix

+ __BaseEntity:__ Avoid stack overflow with getMemento and custom getters ([7c9e073](https://github.com/coldbox-modules/quick/commit/7c9e073c089f62047faac1e3e8fcc87eacbc8e0f))


# v2.4.2
## 08 Nov 2019 — 00:45:47 UTC

### fix

+ __memento:__ Use available getters for the memento
 ([ba562c3](https://github.com/coldbox-modules/quick/commit/ba562c3062d1170ff8e50e2a45357358aaf0c444))


# v2.4.1
## 07 Nov 2019 — 16:58:47 UTC

### fix

+ __memento:__ Correctly serialize array relationships by default
 ([479dabc](https://github.com/coldbox-modules/quick/commit/479dabce8f71459a7c3e1f3c084b2290a8b802f1))


# v2.4.0
## 06 Nov 2019 — 22:25:58 UTC

### chore

+ __dependencies:__ Update TestBox to version 3
 ([a0dd6ab](https://github.com/coldbox-modules/quick/commit/a0dd6abb904646f3c0a6eded06186bafa1afd704))

### feat

+ __setters:__ Apply setters when hydrating the entity from the database
 ([e4a0158](https://github.com/coldbox-modules/quick/commit/e4a0158ecb74b189428166c67677147b9ff19d00))
+ __ErrorMessages:__ Improve error messages for not loaded entities ([f3f2e2d](https://github.com/coldbox-modules/quick/commit/f3f2e2d95d2fb47e17765d11d581c1b3283d5dc0))
+ __Scopes:__ Query scopes can return any value ([358e977](https://github.com/coldbox-modules/quick/commit/358e977635b2f6b9f6d30c2c1b3dfdbe26054d73))


# v2.3.1
## 06 Nov 2019 — 21:45:40 UTC

### chore

+ __build:__ Adjust travis testbox run
 ([790df84](https://github.com/coldbox-modules/quick/commit/790df84685a411013128d00dd519602930007b2a))

### fix

+ __tests:__ Fix strange test error on Lucee 5 with nested describe blocks
 ([305e0a2](https://github.com/coldbox-modules/quick/commit/305e0a224282bf12df222116ce4a4dd110ca17c6))
+ __BaseEntity:__ Return the correct memento with accessors on ([59614a0](https://github.com/coldbox-modules/quick/commit/59614a00bea3a73346985be1e9487d599d65d178))


# v2.3.0
## 08 Jul 2019 — 15:46:12 UTC

### feat

+ __BaseEntity:__ Add flag to ignore non-existing attributes to fill ([428b31a](https://github.com/coldbox-modules/quick/commit/428b31ac0ab5de22440ff92341f079735de2db3a))


# v2.2.3
## 17 Jun 2019 — 15:06:40 UTC

### fix

+ __BaseEntity:__ Temporary fix for extra values in data ([821a054](https://github.com/coldbox-modules/quick/commit/821a05492a7184cb7a97361bfb6a1134991e1536))


# v2.2.2
## 14 Jun 2019 — 05:10:05 UTC

### perf

+ __BaseEntity:__ Better caching of metadata ([27b6ec3](https://github.com/coldbox-modules/quick/commit/27b6ec38a4ff3fc513807bad69f4461e7f3b8655))


# v2.2.1
## 14 Jun 2019 — 04:37:21 UTC

### chore

+ __build:__ Use openjdk8 in Travis builds
 ([d8f7d41](https://github.com/coldbox-modules/quick/commit/d8f7d41e00d53b740ee5d824087db90f47129177))

### other

+ __\*:__ docs: Fix Getting Started 404 ([5c9eddd](https://github.com/coldbox-modules/quick/commit/5c9eddd1d3f32daf87d80a2aa47e9c0d845da0c8))


# v2.2.0
## 29 May 2019 — 03:27:23 UTC

### feat

+ __Relationships:__ Add fetch methods to all Relationships ([61a6035](https://github.com/coldbox-modules/quick/commit/61a6035beba2f6d3fbcbcfd5a36941f32d38ae20))


# v2.1.3
## 14 May 2019 — 01:57:33 UTC

### tests

+ __Relationships:__ Prove relationship setters use the cache ([953d653](https://github.com/coldbox-modules/quick/commit/953d65310159a51e8388cf653283c201bd6bc680))


# v2.1.2
## 07 May 2019 — 07:07:20 UTC

### fix

+ __VirtualInheritance:__ Certify virtual inheritance support ([e105f18](https://github.com/coldbox-modules/quick/commit/e105f1899d26a072fd241e2337f060d32525898d))


# v2.1.1
## 03 May 2019 — 22:58:37 UTC

### fix

+ __Subselect:__ Return the entity after executing a subselect
 ([87e5a7a](https://github.com/coldbox-modules/quick/commit/87e5a7a7b2738500a7f1a84a09ca6e263d1df9f5))


# v2.1.0
## 03 May 2019 — 22:25:30 UTC

### feat

+ __Relationships:__ Relationships can be set using relationship setters ([e1e21a8](https://github.com/coldbox-modules/quick/commit/e1e21a83fc72232f8edc370665ed739eb6f33370))
+ __Relationships:__ Allow saving of ids as well as entities
 ([3f30131](https://github.com/coldbox-modules/quick/commit/3f301314629f5f07d474b661dae8db90f1b19815))
+ __HasMany:__ Many entities can be saved to a hasMany relationship at once ([c9f8f47](https://github.com/coldbox-modules/quick/commit/c9f8f4773bea5c7bd7e1ae142c5aad0550614aa5))
+ __Scopes:__ Register global scopes for entities ([995706b](https://github.com/coldbox-modules/quick/commit/995706b1266bf57456cf5f8406d188d6b978e26c))
+ __Subselects:__ Add subselect helper ([cf13ddd](https://github.com/coldbox-modules/quick/commit/cf13dddd8a8e674e6ee98730912220d5eeb010bf))

### fix

+ __Relationships:__ Make mapping foreign keys optional ([708506d](https://github.com/coldbox-modules/quick/commit/708506d8d4eee9fde0307d1fd6ed9bac57d94752))


# v1.3.2
## 30 Apr 2019 — 19:52:39 UTC

### chore

+ __box.json:__ Add author
 ([b38a7ed](https://github.com/coldbox-modules/quick/commit/b38a7edde6e810c71ff139cd295418a86779bb51))


# v1.3.1
## 30 Apr 2019 — 19:43:23 UTC

### chore

+ __Release:__ v2.0.0 ([425d474](https://github.com/coldbox-modules/quick/commit/425d474898058000c4f0b4defa270a75f3e73b64))

### docs

+ __README:__ Document that all fields need to be mapped ([ecece5c](https://github.com/coldbox-modules/quick/commit/ecece5c6a19d21eb0aa5718ad607995375467bef))


# v1.3.0
## 22 Aug 2018 — 19:58:30 UTC

### chore

+ __ci:__ Test on adobe@2018
 ([d42cf61](https://github.com/coldbox-modules/quick/commit/d42cf61e63d4bdeacfb04ab04e4a1c0b3c4f6a4a))

### feat

+ __BaseEntity:__ Enable per entity datasources and grammars ([561f368](https://github.com/coldbox-modules/quick/commit/561f36841bdba0eb238d07167d35754faf32976c))
+ __KeyType:__ Add AssignedKey Type ([897277d](https://github.com/coldbox-modules/quick/commit/897277d0ffeffafb515341ed3f9ed4e71fc50bda))


# v1.2.0
## 19 Jul 2018 — 22:43:54 UTC

### chore

+ __build:__ Fix spotty gpg key ([c3c5a18](https://github.com/coldbox-modules/quick/commit/c3c5a18b132ee73bc3f5dabb2dee6014f0855b59))
+ __build:__ Test adobe@2018 on CI ([299d5b0](https://github.com/coldbox-modules/quick/commit/299d5b0be6972bc7dc966e1b19acb5c24fac6723))

### feat

+ __Scopes:__ Allow scopes to call other scopes ([07bbde1](https://github.com/coldbox-modules/quick/commit/07bbde1f447b85a3ee4f0d80e4c24ca233102a65))


# v1.1.2
## 02 Jul 2018 — 17:22:46 UTC

### chore

+ __build:__ Set location automatically on version update ([183b05a](https://github.com/coldbox-modules/quick/commit/183b05a839e71105ffd1aae2a271dce85c808bbc))

### fix

+ __BaseEntity:__ Only set loaded for attributes successfully retrieved from the database ([665a78a](https://github.com/coldbox-modules/quick/commit/665a78a4cb44e61282f5017d895a41ae0768bcf9))


# v1.1.1
## 02 Jul 2018 — 16:54:21 UTC

### fix

+ __Relationships:__ correct detach function name ([5dceb17](https://github.com/coldbox-modules/quick/commit/5dceb17af5bcccee1b2eb6428a2c1a083b2432e9))

### other

+ __\*:__ Use logo in README ([3125e6b](https://github.com/coldbox-modules/quick/commit/3125e6b589e205718dd1cc19c1f52aa256a7e858))
+ __\*:__ Add quick logo ([9e26b09](https://github.com/coldbox-modules/quick/commit/9e26b0927041218d608b81000df8259fe42d83dc))
+ __\*:__ Copied Readme from docs (#1) ([137c688](https://github.com/coldbox-modules/quick/commit/137c68841facdddb245083e8076b7bbd17861422))


# v1.1.0
## 06 Jun 2018 — 20:50:16 UTC

### chore

+ __box.json:__ remove package scripts in favor of commandbox-semantic-release ([aafe02a](https://github.com/coldbox-modules/quick/commit/aafe02afe8d25683a3d85874f9193aca1b1c7412))

### feat

+ __attributes:__ better guarding against non-existent attributes ([0566e35](https://github.com/coldbox-modules/quick/commit/0566e35b7dca2123d1d115b4a70e9118c3800f5e))
+ __Columns:__ Allow attributes to set a sqltype ([8c3db73](https://github.com/coldbox-modules/quick/commit/8c3db73a49f2d599ddd7179226f9c2fd11437a6e))
+ __Relationships:__ pass arguments through to relationships ([5962a19](https://github.com/coldbox-modules/quick/commit/5962a19082dd9579ce021e139a80674efbf4d9a6))

### fix

+ __Update:__ don't include the key in the SET clause ([846ff78](https://github.com/coldbox-modules/quick/commit/846ff78ef3490b9320e112d3ad6f90635d10dbda))

### other

+ __\*:__ Enable commandbox-semantic-release ([e34f966](https://github.com/coldbox-modules/quick/commit/e34f9660d6c9f840dff25f2e34fbf17416cface8))
