require "./spec_helper"

describe Fzy do
  it "has a version number" do
    Fzy::VERSION.should match /\A\d+\.\d+\.\d+\z/
  end

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
        lib/fuzzy_match/.gitignore
        lib/fuzzy_match/LICENSE
        src/main.cr
        lib/version_from_shard/LICENSE
        lib/fuzzy_match/src/fuzzy_match/version.cr
        lib/fuzzy_match/.tool-versions
        lib/fuzzy_match/.editorconfig
      )
      results = Fzy.search("main", files)
      results.first.value.should eq("src/main.cr")
    end
  end

  context "index" do
    it "should be stored in matches" do
      files = %w(
        lib/fuzzy_match/.gitignore
        lib/fuzzy_match/LICENSE
        src/main.cr
        lib/version_from_shard/LICENSE
        lib/fuzzy_match/src/fuzzy_match/version.cr
        lib/fuzzy_match/.tool-versions
        lib/fuzzy_match/.editorconfig
      )
      results = Fzy.search("LICENSE", files)
      results.size.should eq(2)
      results[0].value.should eq("lib/fuzzy_match/LICENSE")
      results[0].index.should eq(1)
      results[1].value.should eq("lib/version_from_shard/LICENSE")
      results[1].index.should eq(3)
    end
  end

  # Tests below ported from https://github.com/jhawthorn/fzy.js
  context "score" do
    it "should prefer starts of words" do
      # App/Models/Order is better than App/MOdels/zRder
      Fzy.search("amor", ["app/models/order"]).first.score.should be > Fzy.search("amor", ["app/models/zrder"]).first.score
    end

    it "should prefer consecutive letters" do
      # App/MOdels/foo is better than App/M/fOo
      Fzy.search("amo", ["app/m/foo"]).first.score.should be < Fzy.search("amo", ["app/models/foo"]).first.score
    end

    it "should prefer contiguous over letter following period" do
      # GEMFIle.Lock < GEMFILe
      Fzy.search("gemfil", ["Gemfile.lock"]).first.score.should be < Fzy.search("gemfil", ["Gemfile"]).first.score
    end

    it "should prefer shorter matches" do
      Fzy.search("abce", ["abcdef"]).first.score.should be > Fzy.search("abce", ["abc de"]).first.score
      Fzy.search("abc", ["    a b c "]).first.score.should be > Fzy.search("abc", [" a  b  c "]).first.score
      Fzy.search("abc", [" a b c    "]).first.score.should be > Fzy.search("abc", [" a  b  c "]).first.score
    end

    it "should prefer shorter candidates" do
      Fzy.search("test", ["tests"]).first.score.should be > Fzy.search("test", ["testing"]).first.score
    end

    it "should prefer start of candidate" do
      # Scores first letter highly
      Fzy.search("test", ["testing"]).first.score.should be > Fzy.search("test", ["/testing"]).first.score
    end

    it "score exact score" do
      # Exact match is Fzy::SCORE_MAX
      Fzy.search("abc", ["abc"]).first.score.should eq(Fzy::SCORE_MAX)
      Fzy.search("aBc", ["abC"]).first.score.should eq(Fzy::SCORE_MAX)
    end

    it "score empty query" do
      # Empty query always results in Fzy::SCORE_MIN
      Fzy.search("", [""]).first.score.should eq(Fzy::SCORE_MIN)
      Fzy.search("", ["a"]).first.score.should eq(Fzy::SCORE_MIN)
      Fzy.search("", ["bb"]).first.score.should eq(Fzy::SCORE_MIN)
    end

    it "score gaps" do
      Fzy.search("a", ["*a"]).first.score.should eq(Fzy::SCORE_GAP_LEADING)
      Fzy.search("a", ["*ba"]).first.score.should eq(Fzy::SCORE_GAP_LEADING * 2)
      Fzy.search("a", ["**a*"]).first.score.should eq(Fzy::SCORE_GAP_LEADING * 2 + Fzy::SCORE_GAP_TRAILING)
      Fzy.search("a", ["**a**"]).first.score.should eq(Fzy::SCORE_GAP_LEADING * 2 + Fzy::SCORE_GAP_TRAILING*2)
      Fzy.search("aa", ["**aa**"]).first.score.should eq(Fzy::SCORE_GAP_LEADING * 2 + Fzy::SCORE_MATCH_CONSECUTIVE + Fzy::SCORE_GAP_TRAILING * 2)
      Fzy.search("aa", ["**a*a**"]).first.score.should eq(Fzy::SCORE_GAP_LEADING + Fzy::SCORE_GAP_LEADING + Fzy::SCORE_GAP_INNER + Fzy::SCORE_GAP_TRAILING + Fzy::SCORE_GAP_TRAILING)
    end

    it "score consecutive" do
      Fzy.search("aa", ["*aa"]).first.score.should eq(Fzy::SCORE_GAP_LEADING + Fzy::SCORE_MATCH_CONSECUTIVE)
      Fzy.search("aaa", ["*aaa"]).first.score.should eq(Fzy::SCORE_GAP_LEADING + Fzy::SCORE_MATCH_CONSECUTIVE * 2)
      Fzy.search("aaa", ["*a*aa"]).first.score.should eq(Fzy::SCORE_GAP_LEADING + Fzy::SCORE_GAP_INNER + Fzy::SCORE_MATCH_CONSECUTIVE)
    end

    it "score slash" do
      Fzy.search("a", ["/a"]).first.score.should eq(Fzy::SCORE_GAP_LEADING + Fzy::SCORE_MATCH_SLASH)
      Fzy.search("a", ["*/a"]).first.score.should eq(Fzy::SCORE_GAP_LEADING * 2 + Fzy::SCORE_MATCH_SLASH)
      Fzy.search("aa", ["a/aa"]).first.score.should eq(Fzy::SCORE_GAP_LEADING*2 + Fzy::SCORE_MATCH_SLASH + Fzy::SCORE_MATCH_CONSECUTIVE)
    end

    it "score capital" do
      Fzy.search("a", ["bA"]).first.score.should eq(Fzy::SCORE_GAP_LEADING + Fzy::SCORE_MATCH_CAPITAL)
      Fzy.search("a", ["baA"]).first.score.should eq(Fzy::SCORE_GAP_LEADING * 2 + Fzy::SCORE_MATCH_CAPITAL)
      Fzy.search("aa", ["baAa"]).first.score.should eq(Fzy::SCORE_GAP_LEADING * 2 + Fzy::SCORE_MATCH_CAPITAL + Fzy::SCORE_MATCH_CONSECUTIVE)
    end

    it "score dot" do
      Fzy.search("a", [".a"]).first.score.should eq(Fzy::SCORE_GAP_LEADING + Fzy::SCORE_MATCH_DOT)
      Fzy.search("a", ["*a.a"]).first.score.should eq(Fzy::SCORE_GAP_LEADING * 3 + Fzy::SCORE_MATCH_DOT)
      Fzy.search("a", ["*a.a"]).first.score.should eq(Fzy::SCORE_GAP_LEADING + Fzy::SCORE_GAP_INNER + Fzy::SCORE_MATCH_DOT)
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

    it "are sorted when double letters later in string" do
      Fzy.search("bookmarks", %w(clear_bookmarks)).first.positions.should eq([6, 7, 8, 9, 10, 11, 12, 13, 14])
    end

    it "are sorted when double letters beginning of string" do
      Fzy.search("aandom", %w(aandom_baandom)).first.positions.should eq([0, 1, 2, 3, 4, 5])
    end

    it "favors start of match" do
      Fzy.search("andom", %w(andom_random)).first.positions.should eq([0, 1, 2, 3, 4])
    end
  end
end
