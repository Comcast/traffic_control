# Traffic Router

## Building

Traffic Router can be built with either Maven or Gradle

If you are building on a Mac OS X host and you want to create a personal RPM bundle
you must build using Gradle as there's no support for this with Maven on OS X.

### Building with Maven

Which version of Maven do I use?

* It is recommended to use version 3.3.3 or higher

Which Maven goals do I run to build Traffic Router?

* Run `mvn clean verify` from the command line, this cleans, compiles, tests, and (on Linux only) builds the rpm 

### Building with Gradle

Which version of Gradle do I use?

* It is recommended to use version 3.0 or higher

Which Gradle tasks do I run?

* Run `./gradlew` from the command line, this cleans, compiles, tests, and builds the rpm

