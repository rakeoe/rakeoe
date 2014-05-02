[![Gem Version](https://badge.fury.io/rb/rakeoe.png)](http://badge.fury.io/rb/rakeoe)

# RakeOE : Rake Optimized for Embedded

**A build system for test driven Embedded C/C++ Development based on Ruby rake**

RakeOE is a build system for application/library development. The aim of RakeOE is to make embedded C/C++ development as easy and straight-forward as possible from the point of view of build management. It's possible to use it on the command line or to integrate it into Eclipse CDT. It runs on Windows, Linux and Mac OS X.<br/>
<br/>
RakeOE uses a *convention over configuration* paradigm to enable a fast jump start for developers. It's meant to be used by the casual maker and professional C/C++ developer alike.<br/>
Though it's possible to override defaults, tweak library specific platform flags and do all kind of configuration management settings, one can get a long way without doing so.<br/>
<br/>
RakeOE uses OpenEmbedded / Yocto environment files to automatically pick up all appropriate paths and flags for the given build platform. In this way it supports cross compilation in whatever target platform the cross compiler builds. But it's also possible and encouraged to use it for native host development.<br/>
The toolchain has to be gcc compatible at the moment, e.g. has to implement the -dumpmachine, -MM, -MF and -MT options. Clang qualifies for that as well.


## Prerequisites

### Ruby
RakeOE is based on Rake. Rake comes bundled with Ruby. Therefore you should have installed a recent [Ruby version](http://www.ruby-lang.org/en/ "[Latest Ruby") on your development machine. If using a unixoid system (like Linux / Mac OS X), it's recommended to use [rvm](https://rvm.io/) or [rbenv](https://github.com/sstephenson/rbenv) for managing your ruby installation, as the default ruby installation on those systems might be outdated. If on Windows, use the default Windows installer and follow the installation instruction for your specific Windows version. Required is **Ruby >= 2.0.0**.

### OS
Rake OE has been tested on Linux, Windows(XP,7) and Mac OSX. It should work on whatever platform Ruby/Rake runs on.<br/>

### Toolchain
For the time beeing, **gcc** or a gcc-compatible compiler like **clang** is required. Besides compilation, gcc is used e.g. for header file dependency generation or platform informations.<br/>
<br/>
If you'd want to compile for ARM Cortex-M/R - compatibe microcontrollers, we recommend the [Launchpad ARM](https://launchpad.net/gcc-arm-embedded) toolchain. It's free and very well maintained.<br/>
<br/>
If you'd want to use RakeOE for Linux development, you have various options:

1.      Choose the native toolchain or one of the zillions cross-toolchains out there and adapt one of the available platform files
1.      Install some flavour of Yocto/OpenEmbedded on your host platform and use the provided environment-XXX platform file
 
RakeOE has been tested with [ELDK-5.3/Yocto Danny](http://www.denx.de/wiki/ELDK-5/ "[ELDK-5.3/Yocto Danny") but other OpenEmbedded based toolchains should work similarly well.<br/>

##  Features
### Subprojects
Any subdirectory inside the configured source directories will be scanned for **prj.rake** files. This file contains settings for building libraries or applications and defining dependencies. Any subdirectory that has such a prj.rake file will be automatically converted into a rake task where the directory name is used as the task name and the project type as its top level namespace.</br>
</br>
The project can then be built simply by typing at the command line:

    rake <project type>:<project name>
    
There are 3 buildable project types available: **APP** for applications, **LIB** for a static libraries and **SOLIB** for a dynamic libraries.

#### Settings
Here is an overview with explanations of the settings that can be specified in the subprojects **prj.rake** file:

    # Project type, possible values are APP for applications, LIB for static libraries,
    # SOLIB for shared objects and DISABLED if this project should be excluded from building.
    PRJ_TYPE = 'DISABLED'

    # Additional white space separated list of sub directories this project uses for finding source files.
    # By default only sources in the projects top directory will be used for compilation.
    ADD_SOURCE_DIRS = ''

    # White space separated list of ignored source files. These will be excluded from compilation.
    IGNORED_SOURCES = ''

    # Additional white space separated list of sub directories this project uses for finding includes.
    # By default the subdirectory 'include/' is always supposed.
    ADD_INC_DIRS = ''

    # White space separated list of test source directories.
    TEST_SOURCE_DIRS = ''

    # Additional white space separated list of CFLAGS. Used for all platforms.
    # E.g. '-O3 -Wextra'
    ADD_CFLAGS = ''

    # Additional white space separated list of CXXFLAGS. Used for all platforms.
    # E.g. '-O3 -Wextra'
    ADD_CXXFLAGS = ''

    # Additional white space separated list of libraries this project depends on. These can be either libraries provided
    # from other subprojects or external libraries. In case of the former the include/ directory of that library
    # is used for compilation as well. Used for all platforms.
    # e.g. 'pthread rt m'
    ADD_LIBS = ''

    # Additional white space separated list of linker flags. Used for all platforms.
    ADD_LDFLAGS = ''

    # Set to 1 if you need Qt support. If enabled, all header files will be parsed for the
    # declaration of the keyword Q_OBJECT and if found used as input for the moc compiler.
    # By default QtCore and QtNetwork libs are enabled. If you need more Qt libraries,
    # place them in ADD_LIBS variable.
    USE_QT = 0

    # White space separated list of ignored platforms, i.e. platforms this project will _not_ be compiled for.
    # Possible values depend on your toolchain.
    # E.g. 'arm-linux-gnueabi i686-linux-gnu'
    IGNORED_PLATFORMS = ''

### Dependencies
When using multiple subprojects with libraries, one can build a dependency chain between library => library and application => library. Those dependencies are taken into account for build order, include paths and linkage.<br/>
<br/>
To enable dependency from one subproject to another library subproject, use the following setting in the subprojects prj.rake file:

    ADD_LIBS = '<lib1> <lib2> ... <libn>'

Recursive dependencies are detected and an error is given in this case.<br/>

### Qt
RakeOE has built-in support for Qt. It will automatically parse header files in Qt enabled sub projects and run the moc compiler on them if a **Q_OBJECT** declaration is encountered. Build settings of the used Qt framework have to be provided by the platform file.<br/>
<br>
To enable Qt in your subproject, use the following setting in the subprojects prj.rake file:

    USE_QT = 1
    
### Usage friendliness
There are "top level" rake tasks which are documented and lower level rake tasks that are not. All application and library subprojects are top level rake tasks. If there are tests present, those are also top level rake tasks.<br/>
<br/>
To get a list of all top level rake tasks, type at the command line:

    rake -T

All final and intermediate build steps can be executed with all dependencies managed automatically. You can specify to build just a single object file or a moc file because all generated files are in fact low level rake tasks.<br/>
<br/>
To get a list of all rake tasks (including low level rake tasks), type at the command line:

    rake -T -A

    
### Versioning
You can pass a version string to all compiled files via environment variable **SW_VERSION_ENV**. The content of this environment variable is passed to the build in CFLAGS/CXXFLAGS as **-DPROGRAM_VERSION**. The default value in case no such environment variable is present is "unversioned".


## Usage:

You need a top level Rakefile where you require the rakeoe gem, create a RakeOE::Config object and initialize
the project by calling RakeOE::init.


You define subprojects somewhere beneath the root directory each with a prj.rake file inside. Any number of subprojects can be added like this. RakeOE knows apps, static and dynamic libraries. You can make apps and libraries dependent on other libraries. All build dependencies are then handled automatically.<br/>

    rake <target> <TOOLCHAIN_ENV=filename> <RELEASE=1>


Use **` rake all`**<br/>
to compile all applications and libraries

Use **` rake app:all`**<br/>
to compile only applications

Use **` rake lib:all`**<br/>
to compile only libraries

Use **` rake test`**<br/>
to execute all unit tests for applications/libraries

Use **` rake -T `**<br/>
for a list of important targets with explanation.

Use **` rake -T -A `**<br/>
for a list of all possible targets.


If no parameter given, **`rake all`** is assumed and the native compiler of the host system is used.<br/>
Furthermore without any parameters, no compiler optimization settings are enabled.

If **`RELEASE`** is set to any value, compilation is executed with optimizations **and** debugging set to on.

By setting the variable **`TOOLCHAIN_ENV`**, the native toolchain settings can be overwritten with the environment file.<br/>
from OpenEmbedded. This file is parsed by RakeOE and configures the specific toolchain settings.

## Examples:

1.     **`rake`**
       Uses the native host toolchain as defined in rake/toolchain/environment-setup-native-linux-gnu

1.     **`rake all RELEASE=1`**
       Same as above but a release build will be triggered

1.     **`rake all TOOLCHAIN_ENV=/data/eldk-5.3/nitrogen/environment-setup-armv7a-vfp-neon-linux-gnueabi`**
       Cross compiles in debug mode with the cross compiler definitions found in provided ELDK-5.3 environment
       file.<br/>In this particular case it would cross compile with the armv7a-vfp-neon gcc of a 5.3 ELDK



## Shell autocompletion for rake:

If you'd like to save on key presses when trying to find out which rake task to run, add bash autocompletion for rake tasks like this:

1. 	download https://github.com/mernen/completion-ruby/blob/master/completion-rake
1.	copy downloaded file to /etc/bash_completion.d/rake


* * *

## Defaults:

### Directory layout
The build systems assumes a directory layout similar to this:

    project-root
        ├── build
        │   └── <platform>
        │       ├── dbg
        │       │   ├── apps
        │       │   └── libs
        │       └── release
        │           ├── apps
        │           └── libs
        ├── rake
        ├── Rakefile
        └── src
            ├── 3rdparty
            │   └── CppUTest
            │       └── prj.rake
            ├── app
            │   └── appA
            │       └── prj.rake
            └── lib
                └── libB
                    └── prj.rake

####build/
The build sub directory contains all build artefacts. `<platform>` is the platform specific build directory. For each unique platform a new build<br/>
directory is created. Inside those directories the directories `dbg` and `release` are created, depending on if you<br/>
started a debug or a release build.<br/>
Directly therunder the directories `apps/` and `libs/` can be found in which either application or library binaries are built.<br/>

Whenever you start a build with a different build configuration of either platform or debug mode, instead of overwriting<br/>
binaries from the previous build configuration a separate new directory is used.<br/>

The build directory setting can be changed via Rakefile.<br/>

####rake/
In this directory most build system relevant files and classes can be found. Most are internal and typically will not<br/>
be changed by the user.

####Rakefile
This file is the main Rakefile and will be automatically parsed by Rake. You can do configuration changes here like setting<br/>
paths of source/build directories, file suffix assignments, etc.

####src/
The RakeOE build system knows the build primitives *library* and *application*. It expects libraries and<br/>
applications to be in separate source directories.<br/>

By default these are in `src/lib` and `src/app`. The directory `src/3rdparty/` is treated by RakeOE as a normal library<br/>
directory and is meant as structural separation between 3rd party components that are not part of the platform SDK and<br/>
project specific libraries in `src/lib`.<br/>
The directory `src/app/appA` contains some user application project and `src/lib/libB` some user library project.<br/>
As mentioned above all those projects beneath `src/` have to contain a `prj.rake` file.

The source directory setting can be changed via Rakefile.<br/>

## Installation

Add this line to your application's Gemfile:

    gem 'rakeoe'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rakeoe

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
