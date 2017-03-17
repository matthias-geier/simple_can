
module TestMod
  include SimpleCan

  def self.read_wonk; yield; end
  def read_work; yield; end
end

class SubClass
  include TestMod
end

class TestClass
  include SimpleCan

  def read_list; yield; end
  def read_list!; yield; end
  def write_obj(a); yield(a); end
  def write_obj!(a); yield(a); end
  def manage_all; yield; end
  def manage_all!; yield; end
end

describe "SimpleCan" do
  describe "strategy" do
    it "allows setting and reading of a strategy" do
      assert_equal SimpleCan.strategy, SimpleCan::BasicStrategy
      SimpleCan.strategy = "mooo"
      assert_equal SimpleCan.strategy, "mooo"
    end
  end

  describe "capability" do
    after { TestClass.capability = nil }

    it "stores capability in thread" do
      assert_nil Thread.current[SimpleCan::THREAD_VAR]
      TestClass.capability = "write"
      assert_equal Thread.current[SimpleCan::THREAD_VAR], 1
    end

    it "returns capability from thread" do
      TestClass.capability = "write"
      assert_equal Thread.current[SimpleCan::THREAD_VAR], 1
      assert_equal TestClass.capability, 1
    end

    it "wraps and resets block with capability" do
      assert_nil Thread.current[SimpleCan::THREAD_VAR]
      block_ran = false
      TestClass.with_capability("manage") do
        block_ran = true
        assert_equal TestClass.capability, 2
      end
      assert block_ran
      assert_nil Thread.current[SimpleCan::THREAD_VAR]
    end
  end

  describe "modules" do
    it "creates convenience methods for modules" do
      %w(read write manage).each do |role|
        TestMod.respond_to?("#{role}?")
        TestMod.respond_to?("#{role}!")
      end
    end

    it "defines method wrappers that allow access" do
      TestMod.with_capability("read") do
        assert_equal TestMod.wonk { "cookies" }, "cookies"
      end
    end

    describe "included in class" do
      it "inherits the convenience methods from module" do
        obj = SubClass.new
        %w(read write manage).each do |role|
          obj.respond_to?("#{role}?")
          obj.respond_to?("#{role}!")
          SubClass.respond_to?("#{role}?")
          SubClass.respond_to?("#{role}!")
        end
      end

      it "inherits method wrappers" do
        TestMod.with_capability("read") do
          assert_equal SubClass.new.work { "cookies" }, "cookies"
        end
      end
    end
  end

  describe "classes" do
    it "creates convenience methods for classes" do
      obj = TestClass.new
      %w(read write manage).each do |role|
        obj.respond_to?("#{role}?")
        obj.respond_to?("#{role}!")
        TestClass.respond_to?("#{role}?")
        TestClass.respond_to?("#{role}!")
      end
    end

    it "defines method wrappers that fail access" do
      obj = TestClass.new
      TestClass.with_capability("read") do
        assert_equal obj.obj(1), :unauthorized
        assert_equal obj.all, :unauthorized
      end
    end

    it "defines method wrappers that allow access" do
      obj = TestClass.new
      TestClass.with_capability("read") do
        assert_equal obj.list { "cookies" }, "cookies"
      end
      TestClass.with_capability("manage") do
        assert_equal obj.obj("cookies") { |a| a }, "cookies"
        assert_equal obj.all { "cookies" }, "cookies"
      end
    end

    it "defines wrappers that raise" do
      obj = TestClass.new
      TestClass.with_capability("read") do
        unauth = (begin; obj.obj!(1); rescue SimpleCan::Unauthorized; "m"; end)
        unauth2 = (begin; obj.all!; rescue SimpleCan::Unauthorized; "meow"; end)
        assert_equal unauth, "m"
        assert_equal unauth2, "meow"
      end
    end
  end
end
