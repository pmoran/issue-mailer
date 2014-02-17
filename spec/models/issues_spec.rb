require 'spec_helper'
require 'ostruct'

describe Issues do

  before(:each) do
    @mail = Mail.new do
      to      Issues::EMAIL
      from    'Mikel Lindsaar <test@jetstar.com>'
      subject 'Multipart email sent with Mail'
    end
  end

  context "#update" do

    before(:each) do
      @issues = Issues.new
      Issues.stub!(:new).and_return(@issues)
      Mail.stub!(:find_and_delete).and_yield(@mail)
    end
    
    it "should check for mail and post a new issue" do
      @issues.should_receive(:post).and_return(true)
      Issues.update.should == 1
    end

    it "should not delete mails when issue can't created" do
      @issues.should_receive(:post).and_return(false)
      @mail.should_receive(:skip_deletion)
      Issues.update.should == 0
    end

    it "should reject email from non-Jetstar addresses" do
      @mail.from = ["test@foo.com"]
      @issues.should_not_receive(:post)
      @mail.should_receive(:skip_deletion)
      Issues.update.should == 0
    end

    it "should reject email from non-Jetstar addresses when there also is a jetstar address" do
      @mail.from = ["test@jetstar.com", "test@foo.com"]
      @issues.should_not_receive(:post)
      Issues.update.should == 0
    end
    
    it "should reject mail not sent to issues mailbox" do
      @mail.to = "bad@jqdev.net"
      @issues.should_not_receive(:post)
      Issues.update.should == 0
    end

  end

  context "parsing mail" do

    it "should provide a title" do
      Issues.from(@mail)[:title].should == "Multipart email sent with Mail"
    end

    it "should provide a label" do
      Issues.from(@mail)[:labels].should == ["emailed"]
    end

    it "should provide a body containing from email" do
      Issues.from(@mail)[:body].should =~ /^\[Submitted by: test@jetstar.com/
    end

    context "with a non-multipart mail" do

      it "should provide a body containing mail body" do
        @mail.body = "This is the only body part"
        Issues.from(@mail)[:body].should =~ /This is the only body part/
      end

      it "should contain multi line body text" do
        @mail.body = <<-EOS
        First line

        Second line
        EOS
        Issues.from(@mail)[:body].should =~ /First line/
        Issues.from(@mail)[:body].should =~ /Second line/
      end

      it "should not include text after end token" do
        @mail.body = <<-EOS
        This is the body

        #end
        This is the signature
        EOS

        Issues.from(@mail)[:body].should_not =~ /\#end/
        Issues.from(@mail)[:body].should_not =~ /This is the signature/
      end

    end

    context "with a multipart mail" do

      before(:each) do
        text_part = Mail::Part.new do
          body 'This is plain text'
        end
        html_part = Mail::Part.new do
          content_type 'text/html; charset=UTF-8'
          body '<h1>This is HTML</h1>'
        end
        @mail.text_part = text_part
        @mail.html_part = html_part
      end

      it "should provide a body from the plain text part" do
        Issues.from(@mail)[:body].should =~ /This is plain text/
      end

      it "should not contain non-text part" do
        Issues.from(@mail)[:body].should_not =~ /This is HTML/
      end

    end

  end

end
