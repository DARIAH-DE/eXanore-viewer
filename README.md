# Annotation Viewer
View, share and export annotations from eXanore annotation store.
Store your annotations with the [eXanore Annotation Store](https://github.com/DARIAH-DE/eXanore).
JWT enabled version.


## Build
Call `ant` in the root directory of this repo.

### Dependencies
environment:
* eXist-db >= 2.2

required by installation:
* [XQJson](https://github.com/joewiz/xqjson/blob/master/src/content/xqjson.xql)
* JWT implementation

further requirements:
* eXanore annotation store

## Setup
insert your JWT secret in ../eXanore/modules/params.xqm at $exanoreParam:JwtSecret

## References
* [AnnotatorJS](http://annotatorjs.org/)
* [JWT](https://jwt.io)

## Credits
* Development by Mathias Göbel
* JWT implementation by Ubbo Veentjer

## License
This package is available under the terms of [GNU LGPL-3 License](https://www.gnu.org/licenses/lgpl-3.0.txt) a copy of the license can be found in the repository [LICENSE](LICENSE).
