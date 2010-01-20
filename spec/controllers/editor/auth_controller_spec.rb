require File.dirname(__FILE__) + "/../../spec_helper"

describe Editor::AuthController do

  it "should be able to render all paragraphs" do
    mock_editor

    display_all_editors_for do |paragraph, output|
      output.status.should == '200 OK'
    end
  end

end
