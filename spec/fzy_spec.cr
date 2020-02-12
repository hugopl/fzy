require "./spec_helper"

describe Fzy do
  context "match" do
    it "works" do
      Fzy.search("amor", %w(app/models/order)).first.value.should eq("app/models/order")
      Fzy.search("amor", %w(amor)).first.value.should eq("amor")
      Fzy.search("amor", %w(amora)).first.value.should eq("amora")
      Fzy.search("amor", %w(amoR)).first.value.should eq("amoR")
      Fzy.search("amor", %w(amos)).size.should eq(0)
    end
  end

  context "search" do
    it "works" do
      files = %w(
        src/main.cr
        lib/fuzzy_match/.gitignore
        lib/fuzzy_match/LICENSE
        lib/version_from_shard/LICENSE
        lib/fuzzy_match/src/fuzzy_match/version.cr
        lib/fuzzy_match/.tool-versions
        lib/fuzzy_match/.editorconfig
      )
      results = Fzy.search("main", files)
      results.first.value.should eq("src/main.cr")
    end
  end

  # Tests below ported from https://github.com/jhawthorn/fzy.js
  context "score" do
    it "should prefer starts of words" do
      # App/Models/Order is better than App/MOdels/zRder
      Fzy.score("amor", "app/models/order").should be > Fzy.score("amor", "app/models/zrder")
    end

    it "should prefer consecutive letters" do
      # App/MOdels/foo is better than App/M/fOo
      Fzy.score("amo", "app/m/foo").should be < Fzy.score("amo", "app/models/foo")
    end

    it "should prefer contiguous over letter following period" do
      # GEMFIle.Lock < GEMFILe
      Fzy.score("gemfil", "Gemfile.lock").should be < Fzy.score("gemfil", "Gemfile")
    end

    it "should prefer shorter matches" do
      Fzy.score("abce", "abcdef").should be > Fzy.score("abce", "abc de")
      Fzy.score("abc", "    a b c ").should be > Fzy.score("abc", " a  b  c ")
      Fzy.score("abc", " a b c    ").should be > Fzy.score("abc", " a  b  c ")
    end

    it "should prefer shorter candidates" do
      Fzy.score("test", "tests").should be > Fzy.score("test", "testing")
    end

    it "should prefer start of candidate" do
      # Scores first letter highly
      Fzy.score("test", "testing").should be > Fzy.score("test", "/testing")
    end

    it "score exact score" do
      # Exact match is Fzy::SCORE_MAX
      Fzy.score("abc", "abc").should eq(Fzy::SCORE_MAX)
      Fzy.score("aBc", "abC").should eq(Fzy::SCORE_MAX)
    end

    it "score empty query" do
      # Empty query always results in Fzy::SCORE_MIN
      Fzy.score("", "").should eq(Fzy::SCORE_MIN)
      Fzy.score("", "a").should eq(Fzy::SCORE_MIN)
      Fzy.score("", "bb").should eq(Fzy::SCORE_MIN)
    end

    it "score gaps" do
      Fzy.score("a", "*a").should eq(Fzy::SCORE_GAP_LEADING)
      Fzy.score("a", "*ba").should eq(Fzy::SCORE_GAP_LEADING * 2)
      Fzy.score("a", "**a*").should eq(Fzy::SCORE_GAP_LEADING * 2 + Fzy::SCORE_GAP_TRAILING)
      Fzy.score("a", "**a**").should eq(Fzy::SCORE_GAP_LEADING * 2 + Fzy::SCORE_GAP_TRAILING*2)
      Fzy.score("aa", "**aa**").should eq(Fzy::SCORE_GAP_LEADING * 2 + Fzy::SCORE_MATCH_CONSECUTIVE + Fzy::SCORE_GAP_TRAILING * 2)
      Fzy.score("aa", "**a*a**").should eq(Fzy::SCORE_GAP_LEADING + Fzy::SCORE_GAP_LEADING + Fzy::SCORE_GAP_INNER + Fzy::SCORE_GAP_TRAILING + Fzy::SCORE_GAP_TRAILING)
    end

    it "score consecutive" do
      Fzy.score("aa", "*aa").should eq(Fzy::SCORE_GAP_LEADING + Fzy::SCORE_MATCH_CONSECUTIVE)
      Fzy.score("aaa", "*aaa").should eq(Fzy::SCORE_GAP_LEADING + Fzy::SCORE_MATCH_CONSECUTIVE * 2)
      Fzy.score("aaa", "*a*aa").should eq(Fzy::SCORE_GAP_LEADING + Fzy::SCORE_GAP_INNER + Fzy::SCORE_MATCH_CONSECUTIVE)
    end

    it "score slash" do
      Fzy.score("a", "/a").should eq(Fzy::SCORE_GAP_LEADING + Fzy::SCORE_MATCH_SLASH)
      Fzy.score("a", "*/a").should eq(Fzy::SCORE_GAP_LEADING * 2 + Fzy::SCORE_MATCH_SLASH)
      Fzy.score("aa", "a/aa").should eq(Fzy::SCORE_GAP_LEADING*2 + Fzy::SCORE_MATCH_SLASH + Fzy::SCORE_MATCH_CONSECUTIVE)
    end

    it "score capital" do
      Fzy.score("a", "bA").should eq(Fzy::SCORE_GAP_LEADING + Fzy::SCORE_MATCH_CAPITAL)
      Fzy.score("a", "baA").should eq(Fzy::SCORE_GAP_LEADING * 2 + Fzy::SCORE_MATCH_CAPITAL)
      Fzy.score("aa", "baAa").should eq(Fzy::SCORE_GAP_LEADING * 2 + Fzy::SCORE_MATCH_CAPITAL + Fzy::SCORE_MATCH_CONSECUTIVE)
    end

    it "score dot" do
      Fzy.score("a", ".a").should eq(Fzy::SCORE_GAP_LEADING + Fzy::SCORE_MATCH_DOT)
      Fzy.score("a", "*a.a").should eq(Fzy::SCORE_GAP_LEADING * 3 + Fzy::SCORE_MATCH_DOT)
      Fzy.score("a", "*a.a").should eq(Fzy::SCORE_GAP_LEADING + Fzy::SCORE_GAP_INNER + Fzy::SCORE_MATCH_DOT)
    end
  end

  context "positions" do
    it "positions consecutive" do
      Fzy.search("amo", %w(app/models/foo)).first.positions.should eq([0, 4, 5])
    end

    it "positions start of word" do
      # We should prefer matching the 'o' in order, since it's the beginning
      # of a word.
      Fzy.search("amor", %w(app/models/order)).first.positions.should eq([0, 4, 11, 12])
    end

    it "positions no bonuses" do
      Fzy.search("as", %w(tags)).first.positions.should eq([1, 3])
      Fzy.search("as", %w(examples.txt)).first.positions.should eq([2, 7])
    end

    it "positions multiple candidates start of words" do
      Fzy.search("abc", %w(a/a/b/c/c)).first.positions.should eq([2, 4, 6])
    end

    it "positions exact match" do
      Fzy.search("foo", %w(foo)).first.positions.should eq([0, 1, 2])
    end

    it "positions empty string" do
      Fzy.search("", %w(foo)).first.positions.should eq([] of Int32)
    end
  end
end
