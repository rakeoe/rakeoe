[![Gem Version](https://badge.fury.io/rb/rakeoe.png)](http://badge.fury.io/rb/rakeoe)

# RakeOE : Rake Optimized for Embedded

**A build system for test driven Embedded C/C++ Development based on Ruby rake**

RakeOE is a build system for application/library development. The aim of RakeOE is to make embedded C/C++ development as easy and straight-forward as possible from the point of view of build management. It's possible to use it on the command line or to integrate it into Eclipse CDT. It runs on Windows, Linux and Mac OS X.<br/>
<br/>
RakeOE uses a *convention over configuration* paradigm to enable a fast jump start for developers. It's meant to be used by the casual maker and professional C/C++ developer alike.<br/>
Though it's possible to override defaults, tweak library specific platform flags and do all kind of configuration management settings, one can get a long way without doing so.<br/>
<br/>
RakeOE uses OpenEmbedded / Yocto environment files to automatically pick up all appropriate paths and flags for the given build platform. In this way it supports cross compilation in whatever target platform the cross compiler builds. But it's also possible and encouraged to use it for native host development.<br/>
<br/>
The toolchain has to be [gcc](http://gcc.gnu.org/) compatible at the moment, i.e. has to implement the **-dumpmachine**, **-MM**, **-MF** and **-MT** options among others. [Clang](http://clang.llvm.org/) qualifies for that as well.

## Acknowledgements

The work on this build system has been kindly sponsored by [ifm syntron](http://www.ifm.com/ifmgb/web/home.htm)<br/>
![ifm syntron](http://www.ifm.com/img/head_logo.gif)


## Prerequisites

### Ruby
RakeOE is based on Rake. Rake comes bundled with Ruby. Therefore you should have installed a recent [Ruby version](http://www.ruby-lang.org/en/ "[Latest Ruby") on your development machine. If using a unixoid system (like Linux / Mac OS X), it's recommended to use [rvm](https://rvm.io/) or [rbenv](https://github.com/sstephenson/rbenv) for managing your ruby installation, as the default ruby installation on those systems might be outdated. If on Windows, use the default Windows Ruby installer and follow the installation instruction for your specific Windows version.<br/>
Required is **Ruby >= 2.0.0**.

### Host OS
RakeOE has been tested on Linux, Windows(XP,7) and Mac OS X. It should work on whatever platform Ruby/Rake runs on.<br/>

### Toolchain
For the time beeing, **gcc** or a gcc-compatible compiler like **clang** is required. Besides compilation, gcc is used e.g. for header file dependency generation or platform informations.<br/>

####  Bare-metal
If you'd want to compile bare metal for ARM Cortex-M/R - compatibe microcontrollers, we recommend the [Launchpad ARM](https://launchpad.net/gcc-arm-embedded) toolchain. It's free and very well maintained. Of course not only ARM toolchains can be used. Any gcc bare-metal toolchain should be usable.<br/>
You have to adapt one of the available platform files for the specific platform you are cross compiling for. Often for bare metal toolchains this means specifying a linker file and various compilation flags.

#### Linux
If you'd want to use RakeOE for Linux development, you have various options:

1.      Choose the native toolchain and adapt one of the available platform files
1.      Choose one of the zillions cross-toolchains out there and adapt one of the available platform files
1.      Install some flavour of [Yocto](https://www.yoctoproject.org/)/[OpenEmbedded](http://www.openembedded.org/) on your host platform and use the provided environment-XXX platform file
 
RakeOE has been tested with the following Linux toolchains:

1.      [ELDK-5.3/Yocto Danny](http://www.denx.de/wiki/ELDK-5/ "[ELDK-5.3/Yocto Danny") (newer Yocto or other OpenEmbedded based toolchains should work similarly well)
1.      Ubuntu 12.04 native (32-Bit / 64-Bit)
1.      SuSe Enterprise 11 native

## Installation

Add this line to your application's Gemfile:

    gem 'rakeoe'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rakeoe
    
##  Features
### Subprojects
Any subdirectory inside the configured source directories will be scanned for **prj.rake** files. This file contains settings for building libraries or applications and defining dependencies. Any subdirectory that has such a prj.rake file will be automatically converted into a top level rake task where the directory name is used as the task name and the general project type as its top level namespace.</br>
</br>
The project can then be built by typing:

    rake <namespace>:<project name>
    
There are 2 buildable namespaces available: **app** for applications, **lib** for static/dynamic libraries.<br/>
There are a multitude of convenience rake tasks generated as well. More of that below.


### Adaptability
In most cases you have already a bunch of source code in a certain directory hierarchy available. It's easy to integrate 3rdparty projects or your own existing source codes into RakeOE. Just copy the top level directory inside the configured source folder and drop appropriate prj.rake file(s) into it.<br>
<br/>
This prj.rake directive controls where RakeOE searches for source and include files:

    ADD_SOURCE_DIRS = '<dir1> <dir2> ... <dirn>'

This directive controls where RakeOE searches for include files:

    ADD_INC_DIRS = '<dir1> <dir2> ... <dirn>'
    
Directories should always be relative to the subprojects directory.<br/>
<br/>
You can exclude specific source files from the build by specifiying:

    IGNORED_SOURCES = '<src1> <src2> ... <srcn>'
    
In the Rakefile you can configure any number of source code suffixes and directories:

    config = RakeOE::Config.new
    config.suffixes = {
        :as_sources => %w[.S .s],                # Assembler source file suffixes
        :c_sources => %w[.c],                    # C source file suffixes
        :c_headers => %w[.h],                    # C header file suffixes
        :cplus_sources => %w[.cpp .cxx .C .cc],  # C++ source file suffixes
        :cplus_headers => %w[.h .hpp .hxx .hh],  # C++ header file suffixes
        :moc_header => '.h',                     # header to search for Q_OBJECT directives
        :moc_source => '.cpp'                    # moc file extension to use for generating moc files
    }
    config.directories = {
              :apps =>         %w[src/app],               # Top level application source directories
              :libs =>         %w[src/lib src/3rdparty],  # Top level library directories
              :build =>        'build'                    # Top level buils directory
            }

### Dependencies
When using multiple subprojects with libraries, one can build a dependency chain between library => library and application => library. Those dependencies are taken into account for build order, include paths and linkage.<br/>
<br/>
To enable dependency from one subproject to another library subproject, use the following setting in the subprojects prj.rake file:

    ADD_LIBS = '<lib1> <lib2> ... <libn>'

To export an include directory for other subprojects to be used for compilation, specify in your prj.rake file:

    EXPORTED_INC_DIRS = '<dir1> <dir2> ... <dirn>'

Recursive dependencies are detected and an error is given in this case.<br/>

### Test Driven Development
RakeOE has built-in support for unit testing and test driven develpoment (TDD). If the configuration has the property `RakeOE::Config.test_fw` set, it searches in the namespace `lib:` for a subproject with the exact same name and uses this library to be linked against encountered test cases. There is only one test runner per subproject you can use.<br/>
<br/>
The following prj.rake directive enables subproject specific unit tests:

    TEST_SOURCE_DIRS  = '<dir1> <dir2> ... <dirn>'
    
Depending on the project type, for every subproject with test cases either a `lib:test:<project-name>` or `app:test:<project-name>` rake task is generated. All those test tasks are invoked when executing `rake test:all`. If the target platform equals the host platform, all test tasks are automatically executed after a successful build.<br/>
<br/>
The following build assumptions are made dependent on the project type:

#### LIB/SOLIB
The library is made just normally. No special flags will be provided when building. Exactly one file in `TEST_SOURCE_DIRS` has to contain a `main()` function that calls the test runner and initializes all test cases. All objects in `TEST_SOURE_DIRS` are given to the linker before all other libraries so that mocking of standard calls is possible.

##### APP
The application is splitted into a static application library and the object containing `main()`. Because RakeOE does not know in which file `main()` exists, the convention is to name the basename of that particular file exactly the same as the subproject name itself. RakeOE links all test cases then similarly to the library convention above to the application library. The file with `main()` is not used. This convention is necessary because otherwise there would be two `main()` functions resulting in a multiple references linking error. To get as much test coverage as possible it is therefore recommended to place as little functionality in the file containing `main()`.

### Qt
RakeOE has built-in support for Qt. It will automatically parse header files in Qt enabled sub projects and run the moc compiler on them if a **Q_OBJECT** declaration is encountered. Build settings of the used Qt framework have to be provided by the platform file.<br/>
<br>
To enable Qt in your subproject, use the following setting in the subprojects prj.rake file:

    USE_QT = 1
    
### User friendliness
There are "top level" rake tasks which are documented and lower level rake tasks that are not. All application and library subprojects are top level rake tasks. If there are tests present, those are also top level rake tasks.<br/>
<br/>
To get a list of all top level rake tasks, type at the command line:

    rake -T

All final and intermediate build steps can be executed with all dependencies managed automatically. You can specify to build just a single object or moc file because all generated files are in fact low level rake tasks.<br/>
<br/>
To get a list of all rake tasks (including low level rake tasks), type at the command line:

    rake -T -A

### Build system friendliness
The possibility to build on a continuous integration server like Jenkins and configuration management features are corner stones of RakeOE. It can be configured to use different toolchains and Rakefiles for different platforms and different build environments. It can even be used to build just specific subprojects for specific platforms but provide common subprojects that are independent from a specific platform.<br/>
Either way you can configure various settings that influence the build behaviour. You can even configure library specific platform settings inside the platform file, e.g. if some library uses platform specific include directories or linkage flags then all can be configured in the platform file without changing any source code or using distracting `#ifdef PLATFORM_X ... #else ... #endif` directives.

#### TOOLCHAIN_ENV
You can specifiy via the `TOOLCHAIN_ENV` environment variable which platform file to use. You can copy the platform file and name it differently according to your needs and tweak just basic settings. Or you have a different platfrom file that describes a completey different toolchain.<br/>
Note that you may also specifiy the platform file via `RakeOE::Config.platform` configuration. If present the `TOOLCHAIN_ENV` environment variable will be ignored.

#### Different Rakefiles
You can specify via `rake -f <Rakefile>` which Rakefile to use. If you don't specify `-f` a file named `Rakefile` in the top-level directory is assumed. Some configurations are only settable via the configuration object `RakeOE::Config` so that you will need different Rakefiles if you want to provide multiple of those settings per project.

#### Debug/Release mode
If you define the `RELEASE` environment variable, RakeOE builds in release mode and uses a different set of optimization flags as well as another build directory. In the `RakeOE::Config` object you can configure the settings `optimization_dbg` and `optimization_release` used for debug and release mode. All other settings like standard CFLAGS/CXXFLAGS and LDFLAGS are taken from the platform file.<br/>
By default RakeOE builds in debug mode.

#### Versioning
You can pass a version string to all compiled files via environment variable **SW_VERSION_ENV**. The content of this environment variable is passed to the build in CFLAGS/CXXFLAGS as **-DPROGRAM_VERSION**. The default value in case no such environment variable is present is **unversioned-$REALEASE**, where **$RELEASE** is either `dbg` or `release` dependent on the release mode.

#### Library specific platform settings
Assume on `platform A` a specific library is placed under `/usr/lib/libA/libA.so` and its include file(s) under `/usr/include/libA/...`. Now on `platform B` a newer version of the library is installed at different places: the binary in `/opt/lib/libA/libAv2.so` and include file(s) in `/opt/inc/libAv2/...`. You can solve this scenario by placing the following directives in the platform files:

Platform file A:

    libA_CFLAGS   = '-I/usr/include/libA'
    libA_CXXFLAGS = '-I/usr/include/libA'
    libA_LDFLAGS  = '-lA -L/usr/lib/libA'
    
Platform file B:

    libA_CFLAGS   = '-I/opt/inc/libAv2'
    libA_CXXFLAGS = '-I/opt/inc/libAv2'
    libA_LDFLAGS  = '-lAv2 -L/opt/lib/libAv2'
    
And in the prj.rake file:

    ADD_LIBS = 'A'

In the same way it's possible to not only resolve platform specific issues for external libraries but also for subproject libraries, if. e.g. different compilation and linker flags have to be used for different platforms.

## Basic usage:

You need a top level Rakefile where you require the rakeoe gem, create a RakeOE::Config object and initialize
the project by calling RakeOE::init.<br/>
<br/>
This is the minimal Rakefile you need:

    require 'rakeoe'
    
    RakeOE::init(RakeOE::Config.new)

Here only defaults are used and the following assumptions are made:

#### Directory layout

    project-root
        ├── build
        │   └── <platform>
        │       ├── dbg
        │       │   ├── apps
        │       │   └── libs
        │       └── release
        │           ├── apps
        │           └── libs
        ├── Rakefile
        └── src
            ├── 3rdparty
            │   └── 3rdpartylibA
            │       └── prj.rake
            ├── app
            │   └── appA
            │       └── prj.rake
            └── lib
                └── libB
                    └── prj.rake

You define subprojects somewhere beneath the root directory each with a prj.rake file inside. Any number of subprojects can be added like this. In the default case your library projects should go to `src/lib` and your application projects to `src/app`. If necessary add library dependencies to the applications by filling in the `ADD_LIBS` variable in the application `prj.rake` file.<br/>
<br/>
After the basic setup has been made, test your project by typing:

    <TOOLCHAIN_ENV=filename> rake -T
    
Now a list of all possible targets should appear.<br/>
<br/>
To make all libraries and applications, type:

    <TOOLCHAIN_ENV=filename> rake <target>


#### Basic rake targets

Use **`rake all`**<br/>
to compile all applications and libraries

Use **`rake app:all`**<br/>
to compile only applications

Use **`rake lib:all`**<br/>
to compile only libraries

Use **`rake test`**<br/>
to execute all unit tests for applications/libraries

Use **`rake -T `**<br/>
for a list of important targets with explanation.

Use **`rake -T -A`**<br/>
for a list of all possible targets.


If no parameter given, **`rake all`** is assumed. Mind off to specify the platform file either via `TOOLCHAIN_ENV` or via `RakeOE::Config` object inside the Rakefile. Otherwise an error is returned.<br/>
Furthermore without any additional parameters, debug mode is assumed.

If **`RELEASE`** is set to any value, compilation is executed with optimizations **and** debugging set to on.


## Examples:

1.     rake
       Uses the native host toolchain as defined in rake/toolchain/environment-setup-native-linux-gnu

1.     rake all RELEASE=1
       Same as above but a release build will be triggered

1.     TOOLCHAIN_ENV=/data/eldk-5.3/nitrogen/environment-setup-armv7a-vfp-neon-linux-gnueabi rake all
       Cross compiles in debug mode with the cross compiler definitions found in provided ELDK-5.3 environment
       file.<br/>In this particular case it would cross compile with the armv7a-vfp-neon gcc of a 5.3 ELDK



## Shell autocompletion for rake:

If your shell is bash and if you'd like to save on key presses when trying to find out which rake task to run, add bash autocompletion for rake tasks like this:

1. download https://github.com/mernen/completion-ruby/blob/master/completion-rake
1.	copy downloaded file to /etc/bash_completion.d/rake


* * *

## Reference

### prj.rake settings
Here is an overview with explanations of the settings that can be specified in the subprojects **prj.rake** file:

    # Project type, possible values are APP for applications, LIB for static libraries,
    # SOLIB for shared objects and DISABLED if this project should be excluded from building.
    PRJ_TYPE = 'DISABLED'

    # Additional white space separated list of sub directories this project uses for finding source files.
    # By default only sources in the projects top directory will be used for compilation.
    ADD_SOURCE_DIRS = ''

    # White space separated list of ignored source files. These will be excluded from compilation.
    IGNORED_SOURCES = ''

    # Exported include directories in case of library projects. These are the directories which will be used
    # for other projects that depend on this project. Include paths listed here need not to be added to the ADD_INC_DIRS
    # variable.
    EXPORTED_INC_DIRS = 'include'

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
        ├── Rakefile
        └── src
            ├── 3rdparty
            ├── app
            └── lib

####build/
The build sub directory contains all build artefacts. `<platform>` is the platform specific build directory. For each unique platform a new build<br/>
directory is created. Inside those directories the directories `dbg` and `release` are created, depending on if you<br/>
started a debug or a release build.<br/>
Directly therunder the directories `apps/` and `libs/` can be found in which either application or library binaries are built.<br/>

Whenever you start a build with a different build configuration of either platform or debug mode, instead of overwriting<br/>
binaries from the previous build configuration a separate new directory is used.<br/>

The build directory setting can be changed via Rakefile.<br/>


####Rakefile
This file is the main Rakefile and will be automatically parsed by Rake. You can do configuration changes here like setting paths of source/build directories, file suffix assignments, etc.

####src/
The RakeOE build system knows the build primitives *library* and *application*. It expects libraries and<br/>
applications to be in separate source directories.<br/>

By default these are in `src/lib` and `src/app`. The directory `src/3rdparty/` is treated by RakeOE as a normal library<br/>
directory and is meant as structural separation between 3rd party components that are not part of the platform SDK and
project specific libraries in `src/lib`.<br/>
The directory `src/app/appA` contains some user application project and `src/lib/libB` some user library project.<br/>
As mentioned above all those projects beneath `src/` have to contain a `prj.rake` file.

The source directory setting can be changed via Rakefile.<br/>

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
