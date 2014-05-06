FactoryGirl.define do
  factory :prj_file_cache, class: PrjFileCache do
    prj_list {  { 'APP' => { 'hello' => {'PRJ_HOME' => '.', 'PRJ_FILE' => './prj.rake'}}} }
  end
end
