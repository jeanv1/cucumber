require File.dirname(__FILE__) + '/../../spec_helper'
require 'stringio'
require 'cucumber/parser/top_down_visitor'

module Cucumber
  module Formatters
    class MiniExecutor < Cucumber::Parser::TopDownVisitor
      def initialize(f)
        @f = f
      end
      
      def visit_step(step)
        if step.regexp == //
          # Just make sure there are some params so we can get <span>s
          proc = lambda do
            case(step.id % 3)
            when 0
              raise Pending
            when 1
              raise "This one failed"
            end
          end
          proc.extend(CoreExt::CallIn)
          proc.name = "WHATEVER"
          step.attach(/(\w+).*/, proc, ['xxx'])
          o = Object.new
          step.execute_in(o) rescue nil
        else
          @f.step_executed(step)
        end
      end
    end
  
    describe HtmlFormatter do
      SIMPLE_DIR = File.dirname(__FILE__) + '/../../../examples/simple'
      
      before do
        p = Parser::StoryParser.new
        @stories = Parser::StoriesNode.new(Dir["#{SIMPLE_DIR}/*.story"], p)
        @io = StringIO.new
        @formatter = HtmlFormatter.new(@io)
        @me = MiniExecutor.new(@formatter)
      end
      
      it "should render HTML" do
        @me.visit_stories(@stories) # set regexp+proc+args and execute
        @formatter.visit_stories(@stories)
        @me.visit_stories(@stories) # output result of execution
        @formatter.dump
        expected_html = File.dirname(__FILE__) + '/stories.html'
        #File.open(expected_html, 'w') {|io| io.write(@io.string)}
        @io.string.should == IO.read(expected_html)
      end
    end
  end
end
