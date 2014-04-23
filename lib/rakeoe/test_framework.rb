module RakeOE
  
class TestFramework

  #
  # Initialize framework
  #
  # Example parameters
  # {
  #   :name         => 'CUnit',
  #   :binary_path  => @env['LIB_OUT']
  #   :include_dir  => lib_dir(name)
  #   :cflags       => ''
  # }
  def initialize(params)
    @params = params
  end

  def name
    @params[:name]
  end

  # Returns test framework binary path
  def binary_path
    @params[:binary_path]
  end

  # Returns test framework include path
  def include
    @params[:include_dir]
  end

  # Return test framework specific compilation flags
  def cflags
    @params[:cflags]
  end

end

end
