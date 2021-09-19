class GitLog
  def initialize(line)
    @line = line
  end

  def match(regexp)
    @line.match(regexp)
  end

  def strip
    @line.strip
  end

  def to_s
    @line.to_s
  end

  def has_files?
    !!@line.match(/(\d+) files? changed.*/)
  end

  [ :files, :insertions, :deletions ].each do |attribute|
    define_method(attribute) do
      return nil unless has_files?
      @line.match(/.* (\d+) #{attribute}?/).to_a.last.to_i rescue 0
    end
  end

  def diff_count
    insertions + deletions
  end
end

regexp = ARGV[0]
dict = {}
key = nil
list = `git log --reverse --stat --no-merges`
list.encode('UFT-8', 'UFT-8', invalid: :replace).split("\n").each do |line|
  git_log = GitLog.new(line)
  case git_log.match(/\A(commit|Merge|Author|Date|    )/).to_a.first
  when "commit"
    key = git_log.match(/\Acommit (.*)/)&.to_a[1]
  when "    "
    key = git_log.strip.match(/#{regexp}/).to_a[1] if regexp
  else
    if git_log.has_files? && key
      dict[key] ||= []
      dict[key] << git_log.diff_count
    end
  end
end
dict.each do |key, value|
  puts "#{key}\t#{value.count}\t#{value.inject do |s, i| s + i end}"
end
