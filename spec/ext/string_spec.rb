require "csa/ext/string"

RSpec.describe String, "#added method" do
  context "capitalize_first" do
    it "demo" do
      test_name = "demo".capitalize_first
      expect_name = "Demo"
      expect(test_name).to eq expect_name
    end
    it "dEmo" do
      test_name = "dEmo".capitalize_first
      expect_name = "DEmo"
      expect(test_name).to eq expect_name
    end
    it "demoproject" do
      test_name = "demoproject".capitalize_first
      expect_name = "Demoproject"
      expect(test_name).to eq expect_name
    end
    it "demoProject" do
      test_name = "demoProject".capitalize_first
      expect_name = "DemoProject"
      expect(test_name).to eq expect_name
    end
  end
end
