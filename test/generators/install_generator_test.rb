require "test_helper"
require "generators/rodauth/install_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests Rodauth::Rails::Generators::InstallGenerator
  destination Pathname("#{__dir__}/../../tmp").expand_path
  setup :prepare_destination

  test "initializer" do
    config_application = destination_root.join("config/application.rb")

    mkdpath(config_application)

    run_generator
    # assert_file "config/initializers/rodauth.rb", /Rodauth::Rails\.configure/
  end
end
