# -*- ruby -*-

module RakeOE
  
#
# Qt specific compilation and linker settings
#

class QtSettings
  # @return [String] Library infix dependent on if either Qt Embedded is used or Desktop Qt
  attr_accessor  :lib_infix

  # @param [Toolchain] toolchain    The toolchain used
  def initialize(toolchain)
    @tc = toolchain
    @qt_file_macros = %w[OE_QMAKE_MOC OE_QMAKE_UIC OE_QMAKE_UIC3 OE_QMAKE_RCC OE_QMAKE_QDBUSCPP2XML OE_QMAKE_QDBUSXML2CPP OE_QMAKE_QT_CONFIG ]
    @qt_path_macros = %w[OE_QMAKE_LIBDIR_QT OE_QMAKE_INCDIR_QT QMAKESPEC]
    @checked = false
    if check_once
      @cfg_file = read_config(@tc.settings['OE_QMAKE_QT_CONFIG'])
      if @cfg_file
        @lib_infix = @cfg_file.env['QT_LIBINFIX']
      else
        @lib_infix = ''
      end
    end
  end

  # Check if all mandatory files and paths are present
  def check
    @prerequisites_resolved = true
    @qt_file_macros.each do |macro|
      macro_value = @tc.settings[macro]
      if macro_value &&  !File.exist?(macro_value)
        @prerequisites_resolved = false
      end
    end
    @qt_path_macros.each do |macro|
      macro_value = @tc.settings[macro]
      if macro_value && !Dir.exist?(macro_value)
        @prerequisites_resolved = false
      end
    end
    @checked = true
  end


  # Check only once our sanity
  #
  # @return [bool] true if already checked or false if not
  def check_once
    check unless @checked
    @prerequisites_resolved
  end


  # Reads and parses the qt configuration
  #
  # @param [String] file      Filename of qt configuration file
  # @return [KeyValueReader]  Parsed configuration file accessible via properties
  def read_config(file)
    if file && !file.empty?
      KeyValueReader.new(file)
    end
  end

  # Returns the cflags configuration for the Qt compilation
  # @return [String]  cflags used for compilation qt files
  def cflags
    " -I#{@tc.settings['OE_QMAKE_INCDIR_QT']} -I#{@tc.settings['OE_QMAKE_INCDIR_QT']}/QtCore -I#{@tc.settings['OE_QMAKE_INCDIR_QT']}/Qt -I#{@tc.settings['OE_QMAKE_INCDIR_QT']}/QtNetwork -I#{@tc.settings['OE_QMAKE_INCDIR_QT']}/QtDBus"
  end

  # Returns the ldflags configuration for the Qt linkage
  # @return [String]  ldflags used for linking qt applications
  def ldflags
   " -L#{@tc.settings['OE_QMAKE_LIBDIR_QT']}"
  end

  # Returns the libs used for the Qt application linkage
  # @return [String]  Libraries used for linking qt apps. These are QtCore and QtNetwork by default.
  #                   Add more libraries inside your project specific rake file if you need more.
  def libs
    " QtCore#{@lib_infix} QtNetwork#{@lib_infix} QtDBus#{@lib_infix}"
  end

end

end