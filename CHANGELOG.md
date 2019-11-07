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
