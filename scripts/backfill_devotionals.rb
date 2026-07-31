# Regenerates devotional HTML files whose content is the generation-failure
# placeholder (e.g. after a model outage). For each affected date it reuses the
# cached verse (from verses/<date>.json, falling back to the verse block already
# in the HTML) and regenerates the devotional via the Claude API — it never
# re-fetches the verse-of-the-day, so historical dates keep their correct verse.
#
#   ANTHROPIC_API_KEY=... ruby scripts/backfill_devotionals.rb          # all failed dates
#   ANTHROPIC_API_KEY=... ruby scripts/backfill_devotionals.rb 2026-07-01 2026-07-02
require 'net/http'
require 'json'
require 'uri'
require 'date'
require 'kramdown'

API_URL = 'https://api.anthropic.com/v1/messages'
MODEL = 'claude-sonnet-5'
MAX_TOKENS = 1500
FALLBACK_MARKER = "couldn't find the devotional content"
PROMPT_TEMPLATE_PATH = 'templates/devotional_prompt.txt'
HTML_TEMPLATE_PATH = 'templates/devotional_template.html'
ARCHIVE_DIR = 'devotionals'
VERSES_DIR = 'verses'

API_KEY = ENV['ANTHROPIC_API_KEY']
abort 'ERROR: ANTHROPIC_API_KEY is not set.' if API_KEY.to_s.empty?

PROMPT_TEMPLATE = File.read(PROMPT_TEMPLATE_PATH, encoding: 'UTF-8')
HTML_TEMPLATE = File.read(HTML_TEMPLATE_PATH, encoding: 'UTF-8')

# Dates whose archived HTML still holds the failure placeholder.
def failed_dates
  Dir.glob(File.join(ARCHIVE_DIR, '*.html')).filter_map do |path|
    date = File.basename(path, '.html')
    next unless date.match?(/\A\d{4}-\d{2}-\d{2}\z/)
    date if File.read(path, encoding: 'UTF-8').include?(FALLBACK_MARKER)
  end.sort
end

# Verse for a date: prefer the cached JSON, else parse it out of the HTML.
def verse_for(date)
  json_path = File.join(VERSES_DIR, "#{date}.json")
  if File.exist?(json_path)
    data = JSON.parse(File.read(json_path, encoding: 'UTF-8'))
    ref = data['reference'].to_s.strip
    text = data['text'].to_s.strip
    return { reference: ref, text: text } unless ref.empty? || text.empty?
  end

  html = File.read(File.join(ARCHIVE_DIR, "#{date}.html"), encoding: 'UTF-8')
  text = html[%r{<blockquote>(.+?)</blockquote>}m, 1].to_s.strip
  ref = html[%r{<cite>(.+?)\s*\(ESV\)</cite>}m, 1].to_s.strip
  return nil if text.empty? || ref.empty?

  { reference: ref, text: text }
end

def generate_devotional(verse)
  prompt = PROMPT_TEMPLATE
           .gsub('{{VERSE_REFERENCE}}', verse[:reference])
           .gsub('{{VERSE_TEXT}}', verse[:text])
  body = {
    model: MODEL,
    max_tokens: MAX_TOKENS,
    thinking: { type: 'disabled' }, # keep the full budget for output on Sonnet 5
    messages: [{ role: 'user', content: prompt }]
  }.to_json

  uri = URI(API_URL)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.read_timeout = 120
  http.open_timeout = 15

  attempts = 0
  begin
    attempts += 1
    req = Net::HTTP::Post.new(uri.path)
    req['Content-Type'] = 'application/json'
    req['x-api-key'] = API_KEY
    req['anthropic-version'] = '2023-06-01'
    req.body = body
    resp = http.request(req)

    case resp.code
    when '200'
      JSON.parse(resp.body.force_encoding('UTF-8')).dig('content', 0, 'text')
    when '429', '500', '502', '503', '529'
      raise "retryable #{resp.code}: #{resp.body[0, 200]}"
    else
      warn "  API error #{resp.code}: #{resp.body[0, 200]}"
      nil
    end
  rescue StandardError => e
    if attempts < 4
      sleep(2**attempts) # 2s, 4s, 8s
      retry
    end
    warn "  giving up after #{attempts} attempts: #{e.message}"
    nil
  end
end

def render(date, verse, content)
  date_formatted = Date.parse(date).strftime('%B %d, %Y')
  replacements = {
    'PAGE_TITLE' => "Devotional for #{date_formatted}",
    'DATE_FORMATTED' => date_formatted,
    'VERSE_REFERENCE' => verse[:reference],
    'VERSE_TEXT' => verse[:text],
    'DEVOTIONAL_CONTENT' => Kramdown::Document.new(content).to_html
  }
  html = HTML_TEMPLATE.dup
  replacements.each { |k, v| html.gsub!("{{#{k}}}", v.to_s) }
  html
end

targets = ARGV.empty? ? failed_dates : ARGV.sort
puts "Backfilling #{targets.length} date(s)."

done = []
skipped = []
targets.each_with_index do |date, i|
  printf("[%2d/%d] %s ... ", i + 1, targets.length, date)
  verse = verse_for(date)
  if verse.nil?
    puts 'SKIP (no verse)'
    skipped << date
    next
  end

  content = generate_devotional(verse)
  if content.nil? || content.strip.empty?
    puts 'SKIP (generation failed)'
    skipped << date
    next
  end

  File.write(File.join(ARCHIVE_DIR, "#{date}.html"), render(date, verse, content))
  puts "ok (#{verse[:reference]})"
  done << date
  sleep 1 # be gentle on rate limits
end

puts
puts "Regenerated: #{done.length}"
puts "Skipped:     #{skipped.length}#{skipped.empty? ? '' : " -> #{skipped.join(', ')}"}"
