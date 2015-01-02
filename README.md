[![Gem Version](https://badge.fury.io/rb/rakeoe.png)](http://badge.fury.io/rb/rakeoe)

Rake Optimized for Embedded: RakeOE is a build system for application/library development. RakeOE utilizes the power of Rake and the easyness of Ruby to make build management for embedded C/C++ development as easy and straight-forward as possible. It's possible to use it on the command line or to integrate it into an IDE like Eclipse. It runs on Windows, Linux and Mac OS X. 
# RakeOE : Rake Optimized for Embedded

**A build system for test driven Embedded C/C++ Development based on Ruby rake**

RakeOE is a build system for application/library development. RakeOE utilizes the power of [Rake](http://rake.rubyforge.org/) and the easyness of Ruby to make build management for embedded C/C++ development as easy and straight-forward as possible. It's possible to use it on the command line or to integrate it into an IDE like Eclipse. It runs on Windows, Linux and Mac OS X.<br/>
<br/>
RakeOE uses the *convention over configuration* paradigm to enable a fast jump start for developers. It's meant to be used by the casual maker and professional C/C++ developer alike.<br/>
Though it's possible to override defaults, tweak library specific platform flags and do all kind of configuration management settings, one can get a long way without doing so.<br/>
<br/>
RakeOE uses OpenEmbedded / Yocto environment files to automatically pick up all appropriate paths and flags for the given build platform. In this way it supports cross compilation in whatever target platform the cross compiler builds. But it's also possible and encouraged to use it for native host development.<br/>
<br/>
The toolchain has to be [gcc](http://gcc.gnu.org/) and GNU ld compatible at the moment, i.e. has to implement the **-dumpmachine**, **-MM**, **-MF**, **-MT** and **-Wl,--start-group** options among others.

## Acknowledgements

The work on this build system has been kindly sponsored by [ifm syntron](http://www.ifm.com/ifmgb/web/home.htm)<br/>
![ifm syntron](http://www.ifm.com/img/head_logo.gif)


## Getting Started

* [Feature list](https://github.com/rakeoe/rakeoe/wiki/Features)
* Make sure you have all [prerequisites](https://github.com/rakeoe/rakeoe/wiki/Prerequisites)
* [Install](https://github.com/rakeoe/rakeoe/wiki/Installation) the gem
* Get familiar with the [basic usage](https://github.com/rakeoe/rakeoe/wiki/Basic-Usage)

## Diving In

* Look at the [examples](https://github.com/rakeoe/rakeoe/wiki/Examples)
* Clone the [Demo projects](https://github.com/rakeoe/rakeoe/wiki/Demo-Projects)
* Add [Bash autocompletion](https://github.com/rakeoe/rakeoe/wiki/Shell-autocompletion-for-rake)
* Study the [Reference](https://github.com/rakeoe/rakeoe/wiki/Reference) section
* [![rakeoe API Documentation](https://www.omniref.com/ruby/gems/rakeoe.png)](https://www.omniref.com/ruby/gems/rakeoe)

## License

See [LICENSE](https://github.com/rakeoe/rakeoe/blob/master/LICENSE)
